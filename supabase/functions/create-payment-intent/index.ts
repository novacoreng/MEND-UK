import { corsHeaders } from '../_shared/cors.ts';
import Stripe from 'npm:stripe@18.5.0';
import { createClient } from 'npm:@supabase/supabase-js@2.57.0';

function moneyToPence(value: number) {
  const pence = Math.round(value * 100);
  if (!Number.isSafeInteger(pence) || pence < 100) throw new Error('Invalid quote total');
  return pence;
}

function platformFeePence(amountPence: number) {
  const configured = Number(Deno.env.get('MEND_PLATFORM_FEE_BPS') ?? '0');
  if (!Number.isFinite(configured) || configured < 0 || configured > 5000) throw new Error('Invalid MEND_PLATFORM_FEE_BPS configuration');
  return Math.round(amountPence * configured / 10_000);
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const auth = req.headers.get('Authorization');
    if (!auth) throw new Error('Authentication required');
    const userClient = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, { global: { headers: { Authorization: auth } } });
    const { data: { user } } = await userClient.auth.getUser();
    if (!user) throw new Error('Authentication required');

    const { repairId } = await req.json();
    if (!repairId) throw new Error('Repair is required');

    const { data: repair, error: repairError } = await userClient
      .from('repairs')
      .select('id,customer_id,assigned_trade_id,status,estimated_price,final_price,currency')
      .eq('id', repairId).single();
    if (repairError || !repair || repair.customer_id !== user.id) throw new Error('Repair not found');
    if (!['accepted','scheduled','on_the_way','arrived','in_progress','awaiting_customer','completed','customer_review','confirmed'].includes(repair.status)) {
      throw new Error('This repair is not ready for payment');
    }
    if (!repair.assigned_trade_id) throw new Error('A trade must be assigned before payment');

    const { data: quote, error: quoteError } = await userClient
      .from('quotes').select('id,total,currency,status,valid_until,trade_id')
      .eq('repair_id', repairId).eq('status','accepted').eq('trade_id', repair.assigned_trade_id)
      .order('version',{ascending:false}).limit(1).maybeSingle();
    if (quoteError || !quote) throw new Error('No accepted quote is available for this repair');
    if (quote.valid_until && new Date(quote.valid_until).getTime() < Date.now()) throw new Error('The accepted quote has expired');
    if (quote.currency !== 'GBP') throw new Error('Only GBP payments are currently supported');

    const amountPence = moneyToPence(Number(quote.total));
    const feePence = platformFeePence(amountPence);
    const transferPence = amountPence - feePence;
    if (transferPence < 100) throw new Error('The trade payout would be below the minimum supported amount');

    const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    const { data: connected } = await admin.from('stripe_connected_accounts')
      .select('stripe_account_id,details_submitted,charges_enabled,payouts_enabled,status')
      .eq('trade_id', repair.assigned_trade_id).maybeSingle();
    if (!connected?.stripe_account_id || !connected.details_submitted || !connected.payouts_enabled) {
      throw new Error('The assigned trade has not completed Stripe payout onboarding');
    }

    const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!);
    const { data: existing } = await admin.from('payments').select('*').eq('repair_id', repairId).eq('payment_type','repair')
      .not('status','in','(cancelled,failed,refunded,partially_refunded)').maybeSingle();

    if (existing?.provider_payment_id && existing.status !== 'failed') {
      const intent = await stripe.paymentIntents.retrieve(existing.provider_payment_id);
      if (intent.amount !== amountPence || intent.currency !== 'gbp') throw new Error('Existing Stripe payment amount does not match the accepted quote');
      return new Response(JSON.stringify({
        clientSecret:intent.client_secret,
        paymentIntentId:intent.id,
        paymentId:existing.id,
        amountPence,
        platformFeePence:feePence,
        transferPence,
      }), {headers:{...corsHeaders,'Content-Type':'application/json'}});
    }

    const transferGroup = `mend_repair_${repairId}`;
    const intent = await stripe.paymentIntents.create({
      amount: amountPence,
      currency: 'gbp',
      automatic_payment_methods: { enabled: true },
      transfer_group: transferGroup,
      metadata: { repair_id: repairId, customer_id: user.id, quote_id: quote.id, trade_id: repair.assigned_trade_id },
      description: `MEND UK repair ${repairId}`,
    }, { idempotencyKey: `mend-repair-${repairId}-quote-${quote.id}` });

    const { data: payment, error: paymentError } = await admin.from('payments').insert({
      repair_id: repairId,
      customer_id:user.id,
      trade_id:repair.assigned_trade_id,
      provider:'stripe',
      provider_payment_id:intent.id,
      amount:Number(quote.total),
      currency:'GBP',
      payment_type:'repair',
      status:'pending',
      platform_fee:feePence / 100,
      transfer_amount:transferPence / 100,
      transfer_group:transferGroup,
    }).select().single();
    if (paymentError) {
      if (paymentError.code === '23505') {
        const { data: retryExisting } = await admin.from('payments').select('*').eq('repair_id', repairId).eq('payment_type','repair').not('status','in','(cancelled,failed,refunded,partially_refunded)').maybeSingle();
        if (retryExisting?.provider_payment_id) {
          const retryIntent = await stripe.paymentIntents.retrieve(retryExisting.provider_payment_id);
          return new Response(JSON.stringify({ clientSecret:retryIntent.client_secret,paymentIntentId:retryIntent.id,paymentId:retryExisting.id,amountPence,platformFeePence:feePence,transferPence }), {headers:{...corsHeaders,'Content-Type':'application/json'}});
        }
      }
      throw paymentError;
    }

    await admin.from('payment_transactions').upsert({
      payment_id:payment.id,
      transaction_type:'payment_intent_created',
      amount:Number(quote.total),
      provider_reference:intent.id,
      idempotency_key:`intent:${intent.id}`,
      metadata:{quote_id:quote.id,repair_id:repairId,platform_fee:feePence/100,transfer_amount:transferPence/100,transfer_group:transferGroup}
    }, { onConflict:'idempotency_key' });

    return new Response(JSON.stringify({ clientSecret:intent.client_secret,paymentIntentId:intent.id,paymentId:payment.id,amountPence,platformFeePence:feePence,transferPence }), {headers:{...corsHeaders,'Content-Type':'application/json'}});
  } catch (e) {
    return new Response(JSON.stringify({error:e instanceof Error?e.message:'Payment could not be started'}), {status:400,headers:{...corsHeaders,'Content-Type':'application/json'}});
  }
});

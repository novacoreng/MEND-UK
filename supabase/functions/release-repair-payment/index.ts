import { corsHeaders } from '../_shared/cors.ts';
import Stripe from 'npm:stripe@18.5.0';
import { createClient } from 'npm:@supabase/supabase-js@2.57.0';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const auth = req.headers.get('Authorization');
    if (!auth) throw new Error('Authentication required');
    const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, { global: { headers: { Authorization: auth } } });
    const { data: { user } } = await db.auth.getUser();
    if (!user) throw new Error('Authentication required');
    const { repairId } = await req.json();
    if (!repairId) throw new Error('Repair is required');

    const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    const { data: repair } = await admin.from('repairs').select('id,customer_id,tenant_id,status').eq('id',repairId).single();
    if (!repair || (repair.customer_id !== user.id && repair.tenant_id !== user.id)) throw new Error('Not authorised to release this repair payment');
    if (!['confirmed','payment_completed','closed'].includes(repair.status)) throw new Error('Repair must be customer-confirmed before payment release');

    const { data: payment } = await admin.from('payments').select('*').eq('repair_id',repairId).eq('payment_type','repair').order('created_at',{ascending:false}).limit(1).maybeSingle();
    if (!payment) throw new Error('Payment not found');
    if (payment.status === 'released') return new Response(JSON.stringify({released:true,transferId:payment.provider_transfer_id}), {headers:{...corsHeaders,'Content-Type':'application/json'}});
    if (!['protected','release_requested'].includes(payment.status)) throw new Error('Payment is not protected and cannot be released');

    const { data: connected } = await admin.from('stripe_connected_accounts').select('stripe_account_id,payouts_enabled').eq('trade_id',payment.trade_id).single();
    if (!connected?.stripe_account_id || !connected.payouts_enabled) throw new Error('Trade payout account is not ready');
    if (!payment.transfer_amount || Number(payment.transfer_amount) < 1) throw new Error('Invalid trade payout amount');

    const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!);
    const intent = await stripe.paymentIntents.retrieve(payment.provider_payment_id);
    if (intent.status !== 'succeeded') throw new Error('Stripe payment has not succeeded');
    const chargeId = typeof intent.latest_charge === 'string' ? intent.latest_charge : intent.latest_charge?.id;
    if (!chargeId) throw new Error('Stripe charge is not available for transfer');

    const { error: queueError } = await admin.rpc('request_payment_release',{p_payment_id:payment.id});
    if (queueError) throw queueError;

    const amount = Math.round(Number(payment.transfer_amount) * 100);
    const transfer = await stripe.transfers.create({ amount, currency:'gbp', destination:connected.stripe_account_id, source_transaction:chargeId, transfer_group:payment.transfer_group || `mend_repair_${repairId}`, metadata:{payment_id:payment.id,repair_id:repairId,trade_id:payment.trade_id}, }, { idempotencyKey:`mend-release-${payment.id}` });

    await admin.from('payments').update({provider_charge_id:chargeId,provider_transfer_id:transfer.id,status:'released',released_at:new Date().toISOString()}).eq('id',payment.id);
    await admin.from('payment_transactions').upsert({payment_id:payment.id,transaction_type:'payout_released',amount:Number(payment.transfer_amount),provider_reference:transfer.id,idempotency_key:`transfer:${transfer.id}`,metadata:{charge_id:chargeId,repair_id:repairId}}, {onConflict:'idempotency_key'});
    await admin.from('payouts').upsert({payment_id:payment.id,trade_id:payment.trade_id,amount:Number(payment.transfer_amount),status:'paid',provider_reference:transfer.id},{onConflict:'payment_id'});

    return new Response(JSON.stringify({released:true,transferId:transfer.id,amount:Number(payment.transfer_amount)}), {headers:{...corsHeaders,'Content-Type':'application/json'}});
  } catch (e) {
    return new Response(JSON.stringify({error:e instanceof Error?e.message:'Payment release failed'}), {status:400,headers:{...corsHeaders,'Content-Type':'application/json'}});
  }
});

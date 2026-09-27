import { corsHeaders } from '../_shared/cors.ts';
import Stripe from 'npm:stripe@18.5.0';
import { createClient } from 'npm:@supabase/supabase-js@2.57.0';

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  const signature = req.headers.get('stripe-signature');
  const body = await req.text();
  try {
    if (!signature) throw new Error('Missing Stripe signature');
    const secret = Deno.env.get('STRIPE_SECRET_KEY');
    const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET');
    if (!secret || !webhookSecret) throw new Error('Stripe webhook configuration is incomplete');

    const stripe = new Stripe(secret);
    const event = await stripe.webhooks.constructEventAsync(body, signature, webhookSecret);
    const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

    const { data: duplicate } = await admin.from('payment_transactions').select('id').eq('idempotency_key', `event:${event.id}`).maybeSingle();
    if (duplicate) return json({ received: true, duplicate: true });

    const object: any = event.data.object;
    let paymentId: string | null = object?.metadata?.payment_id ?? null;
    let repairId: string | null = object?.metadata?.repair_id ?? null;

    if (!paymentId && object?.id) {
      const providerIds = [object.id, object?.payment_intent, object?.charge].filter((v): v is string => typeof v === 'string' && v.length > 0);
      for (const providerId of providerIds) {
        const { data: byProvider } = await admin.from('payments').select('id,repair_id').or(`provider_payment_id.eq.${providerId},provider_charge_id.eq.${providerId},provider_transfer_id.eq.${providerId}`).maybeSingle();
        if (byProvider) { paymentId = byProvider.id; repairId = byProvider.repair_id ?? repairId; break; }
      }
    }

    if (event.type === 'account.updated') {
      const account = object as Stripe.Account;
      const tradeId = account.metadata?.trade_id;
      if (tradeId) {
        const { error } = await admin.rpc('set_stripe_connected_account_state', {
          p_trade_id:tradeId,p_account_id:account.id,p_details_submitted:account.details_submitted ?? false,
          p_charges_enabled:account.charges_enabled ?? false,p_payouts_enabled:account.payouts_enabled ?? false,
          p_requirements_due:account.requirements?.currently_due ?? [],p_status:account.payouts_enabled ? 'active' : 'pending'
        });
        if (error) throw error;
      }
    } else if (event.type === 'payment_intent.succeeded') {
      if (!paymentId) throw new Error('Payment record not found for successful PaymentIntent');
      const intent = object as Stripe.PaymentIntent;
      const chargeId = typeof intent.latest_charge === 'string' ? intent.latest_charge : intent.latest_charge?.id;
      const { error } = await admin.rpc('mark_payment_protected',{p_payment_id:paymentId,p_provider_payment_id:intent.id,p_provider_event_id:event.id,p_amount_pence:intent.amount_received ?? intent.amount});
      if (error) throw error;
      if (chargeId) await admin.from('payments').update({provider_charge_id:chargeId}).eq('id',paymentId);
    } else if (event.type === 'payment_intent.payment_failed') {
      if (!paymentId) throw new Error('Payment record not found for failed PaymentIntent');
      const intent = object as Stripe.PaymentIntent;
      const reason = intent.last_payment_error?.message ?? 'Provider reported payment failure';
      const { error } = await admin.rpc('mark_payment_failed',{p_payment_id:paymentId,p_provider_payment_id:intent.id,p_provider_event_id:event.id,p_reason:reason});
      if (error) throw error;
    } else if (event.type === 'charge.refunded' || event.type === 'refund.created' || event.type === 'refund.updated') {
      if (!paymentId) throw new Error('Payment record not found for refund event');
      const charge = event.type === 'charge.refunded' ? object as Stripe.Charge : null;
      const refund = event.type === 'charge.refunded' ? null : object as Stripe.Refund;
      const amount = charge?.amount_refunded ?? refund?.amount ?? 0;
      const { data: payment } = await admin.from('payments').select('amount').eq('id',paymentId).single();
      if (payment) {
        const refundedAmount = Number(amount) / 100;
        await admin.from('payments').update({refunded_amount:refundedAmount,status:refundedAmount >= Number(payment.amount) ? 'refunded' : 'partially_refunded'}).eq('id',paymentId);
      }
    } else if (event.type === 'transfer.created') {
      if (!paymentId) throw new Error('Payment record not found for transfer event');
      const transfer = object as Stripe.Transfer;
      await admin.from('payments').update({provider_transfer_id:transfer.id,status:'released',released_at:new Date().toISOString()}).eq('id',paymentId);
      await admin.from('payment_transactions').upsert({payment_id:paymentId,transaction_type:'payout_released',amount:Number(transfer.amount)/100,provider_reference:transfer.id,idempotency_key:`transfer-event:${transfer.id}`,metadata:{repair_id:repairId}}, {onConflict:'idempotency_key'});
    } else if (event.type === 'transfer.failed' || event.type === 'transfer.reversed') {
      if (!paymentId) throw new Error('Payment record not found for failed transfer event');
      const transfer = object as Stripe.Transfer;
      await admin.rpc('mark_payment_transfer_failed',{p_payment_id:paymentId,p_transfer_id:transfer.id,p_reason:event.type,p_provider_event_id:event.id});
    }

    if (paymentId) {
      await admin.from('payment_transactions').upsert({payment_id:paymentId,transaction_type:event.type,amount:0,provider_reference:event.id,idempotency_key:`event:${event.id}`,metadata:{repair_id:repairId}}, {onConflict:'idempotency_key'});
    }
    return json({received:true});
  } catch (e) {
    return json({error:e instanceof Error?e.message:'Webhook error'},400);
  }
});

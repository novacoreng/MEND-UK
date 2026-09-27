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
    const { data: trade } = await db.from('trade_profiles').select('id,user_id,business_name,display_name').eq('user_id', user.id).maybeSingle();
    if (!trade) throw new Error('Trade profile not found');
    const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    const { data: existing } = await admin.from('stripe_connected_accounts').select('*').eq('trade_id', trade.id).maybeSingle();
    if (existing?.stripe_account_id) return new Response(JSON.stringify({ accountId: existing.stripe_account_id, status: existing.status, payoutsEnabled: existing.payouts_enabled }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!);
    const account = await stripe.accounts.create({ type: 'express', country: 'GB', email: user.email ?? undefined, business_profile: { name: trade.business_name || trade.display_name }, capabilities: { card_payments: { requested: true }, transfers: { requested: true } }, metadata: { trade_id: trade.id, mend_user_id: user.id } }, { idempotencyKey: `mend-connect-account-${trade.id}` });
    const { error } = await admin.rpc('set_stripe_connected_account_state', { p_trade_id: trade.id, p_account_id: account.id, p_details_submitted: account.details_submitted ?? false, p_charges_enabled: account.charges_enabled ?? false, p_payouts_enabled: account.payouts_enabled ?? false, p_requirements_due: account.requirements?.currently_due ?? [], p_status: account.payouts_enabled ? 'active' : 'pending' });
    if (error) throw error;
    return new Response(JSON.stringify({ accountId: account.id, status: account.payouts_enabled ? 'active' : 'pending', payoutsEnabled: account.payouts_enabled }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  } catch (e) { return new Response(JSON.stringify({ error: e instanceof Error ? e.message : 'Unable to create Stripe connected account' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }); }
});

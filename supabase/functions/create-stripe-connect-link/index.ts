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
    const { data: trade } = await db.from('trade_profiles').select('id,user_id').eq('user_id', user.id).maybeSingle();
    if (!trade) throw new Error('Trade profile not found');
    const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    const { data: connected } = await admin.from('stripe_connected_accounts').select('stripe_account_id').eq('trade_id', trade.id).single();
    if (!connected?.stripe_account_id) throw new Error('Stripe payout account has not been created');
    const refreshUrl = Deno.env.get('STRIPE_CONNECT_REFRESH_URL');
    const returnUrl = Deno.env.get('STRIPE_CONNECT_RETURN_URL');
    if (!refreshUrl || !returnUrl) throw new Error('Stripe Connect return URLs are not configured');
    const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!);
    const link = await stripe.accountLinks.create({ account: connected.stripe_account_id, refresh_url: refreshUrl, return_url: returnUrl, type: 'account_onboarding', collection_options: { fields: 'eventually_due' } });
    return new Response(JSON.stringify({ url: link.url, expiresAt: link.expires_at }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  } catch (e) { return new Response(JSON.stringify({ error: e instanceof Error ? e.message : 'Unable to create Stripe onboarding link' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }); }
});

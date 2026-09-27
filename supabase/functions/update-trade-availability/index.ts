import { createClient } from 'npm:@supabase/supabase-js@2.57.0';
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const auth = req.headers.get('Authorization');
    if (!auth) throw new Error('Authentication required');
    const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, { global: { headers: { Authorization: auth } } });
    const { data: { user } } = await db.auth.getUser();
    if (!user) throw new Error('Authentication required');
    const { tradeId, availability } = await req.json();
    if (!tradeId || !Array.isArray(availability) || availability.length > 70) throw new Error('Invalid availability');
    const { data: trade, error: tradeError } = await db.from('trade_profiles').select('user_id').eq('id', tradeId).single();
    if (tradeError || !trade || trade.user_id !== user.id) throw new Error('Not authorised');
    const cleaned = availability.map((x: any) => ({ trade_id: tradeId, weekday: Number(x.weekday), start_time: String(x.start_time), end_time: String(x.end_time), is_active: x.is_active !== false }))
      .filter((x: any) => Number.isInteger(x.weekday) && x.weekday >= 0 && x.weekday <= 6 && /^\d{2}:\d{2}/.test(x.start_time) && /^\d{2}:\d{2}/.test(x.end_time) && x.start_time < x.end_time);
    const { error: delError } = await db.from('trade_availability').delete().eq('trade_id', tradeId);
    if (delError) throw delError;
    if (cleaned.length) { const { error } = await db.from('trade_availability').insert(cleaned); if (error) throw error; }
    return new Response(JSON.stringify({ ok: true, count: cleaned.length }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  } catch (e) {
    return new Response(JSON.stringify({ error: e instanceof Error ? e.message : 'Unable to update availability' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }
});

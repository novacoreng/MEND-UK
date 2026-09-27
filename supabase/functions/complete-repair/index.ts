import { corsHeaders } from '../_shared/cors.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.57.0';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const auth = req.headers.get('Authorization');
    if (!auth) throw new Error('Authentication required');
    const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, { global: { headers: { Authorization: auth } } });
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Authentication required');
    const body = await req.json();
    if (!body.repairId || !body.action) throw new Error('repairId and action are required');
    if (!['trade_complete', 'customer_confirm'].includes(body.action)) throw new Error('Invalid completion action');
    const { data, error } = await supabase.rpc('complete_repair', { p_repair_id: body.repairId, p_action: body.action, p_note: body.completionNote ?? null });
    if (error) throw error;
    return new Response(JSON.stringify({ repair: data }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  } catch (e) {
    return new Response(JSON.stringify({ error: e instanceof Error ? e.message : 'Completion failed' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }
});

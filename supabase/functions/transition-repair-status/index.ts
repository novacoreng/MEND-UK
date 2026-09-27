import { createClient } from 'npm:@supabase/supabase-js@2'

const cors = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type', 'Content-Type': 'application/json' }

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })
  const auth = req.headers.get('Authorization')
  if (!auth) return new Response(JSON.stringify({ error: 'Authentication required.' }), { status: 401, headers: cors })
  const client = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_ANON_KEY') ?? '', { global: { headers: { Authorization: auth } } })
  const token = auth.replace(/^Bearer\s+/i, '')
  const { data: { user }, error: authError } = await client.auth.getUser(token)
  if (authError || !user) return new Response(JSON.stringify({ error: 'Invalid session.' }), { status: 401, headers: cors })
  try {
    const body = await req.json()
    if (!body.repairId || !body.toStatus) throw new Error('repairId and toStatus are required.')
    const { data, error } = await client.rpc('transition_repair_status', { p_repair_id: body.repairId, p_to_status: body.toStatus, p_note: body.note ?? null })
    if (error) throw error
    return new Response(JSON.stringify({ repair: data }), { status: 200, headers: cors })
  } catch (error) {
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : 'Unable to update repair status.' }), { status: 400, headers: cors })
  }
})

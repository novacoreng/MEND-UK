import { corsHeaders } from '../_shared/cors.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.57.0';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const auth = req.headers.get('Authorization'); if (!auth) throw new Error('Authentication required');
    const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, { global:{headers:{Authorization:auth}} });
    const {data:{user}}=await db.auth.getUser(); if(!user) throw new Error('Authentication required');
    const {quoteId}=await req.json();
    const {data:quote,error:qErr}=await db.from('quotes').select('id,repair_id,status,total,trade_id,version').eq('id',quoteId).single(); if(qErr) throw qErr;
    const {data:repair,error:rErr}=await db.from('repairs').select('id,customer_id,status').eq('id',quote.repair_id).single(); if(rErr) throw rErr;
    if(repair.customer_id!==user.id) throw new Error('Not authorised');
    if(quote.status!=='sent'&&quote.status!=='viewed') throw new Error('Only an active quote can be accepted');
    const {data:accepted}=await db.from('quotes').select('id').eq('repair_id',repair.id).eq('status','accepted').maybeSingle(); if(accepted) throw new Error('Another quote is already accepted');
    const {data:updated,error:uErr}=await db.from('quotes').update({status:'accepted'}).eq('id',quote.id).select().single(); if(uErr) throw uErr;
    const {error:repairErr}=await db.from('repairs').update({assigned_trade_id:quote.trade_id,estimated_price:quote.total,status:'accepted'}).eq('id',repair.id); if(repairErr) throw repairErr;
    return new Response(JSON.stringify({quote:updated}),{headers:{...corsHeaders,'Content-Type':'application/json'}});
  } catch(e){return new Response(JSON.stringify({error:e instanceof Error?e.message:'Quote acceptance failed'}),{status:400,headers:{...corsHeaders,'Content-Type':'application/json'}})}
});

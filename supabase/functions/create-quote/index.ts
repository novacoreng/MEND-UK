import { createClient } from 'npm:@supabase/supabase-js@2.57.0';
import { corsHeaders } from '../_shared/cors.ts';
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok',{headers:corsHeaders});
  try {
    const auth=req.headers.get('Authorization'); if(!auth) throw new Error('Authentication required');
    const db=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_ANON_KEY')!,{global:{headers:{Authorization:auth}}});
    const {data:{user}}=await db.auth.getUser(); if(!user) throw new Error('Authentication required');
    const body=await req.json();
    const repairId=String(body.repairId||''); const items=Array.isArray(body.items)?body.items:[];
    if(!repairId||!items.length) throw new Error('Repair and at least one quote item are required');
    const {data:trade}=await db.from('trade_profiles').select('id').eq('user_id',user.id).single(); if(!trade) throw new Error('Trade profile not found');
    const {data:repair}=await db.from('repairs').select('id,status,customer_id').eq('id',repairId).single(); if(!repair) throw new Error('Repair not found');
    if(!['quote_requested','matching','submitted','quoted'].includes(repair.status)) throw new Error('This repair is not accepting quotes');
    const {data:existing}=await db.from('quotes').select('version').eq('repair_id',repairId).eq('trade_id',trade.id).order('version',{ascending:false}).limit(1).maybeSingle();
    const version=(existing?.version||0)+1;
    const clean=items.map((x:any)=>({description:String(x.description||'').trim(),quantity:Number(x.quantity||1),unit_price:Number(x.unit_price||0),item_type:String(x.item_type||'labour')}));
    if(clean.some(x=>!x.description||x.quantity<=0||x.unit_price<0)) throw new Error('Invalid quote item');
    const subtotal=clean.reduce((a,x)=>a+x.quantity*x.unit_price,0);
    const tax=Math.max(0,Number(body.tax||0)); const discount=Math.max(0,Number(body.discount||0)); const total=Math.max(0,subtotal+tax-discount);
    const {data:quote,error}=await db.from('quotes').insert({repair_id:repairId,trade_id:trade.id,version,subtotal,tax,discount,total,currency:'GBP',warranty_days:Math.max(0,Number(body.warrantyDays||0)),scope_description:String(body.scopeDescription||'').trim(),included_work:Array.isArray(body.includedWork)?body.includedWork:[],excluded_work:Array.isArray(body.excludedWork)?body.excludedWork:[],valid_until:body.validUntil||null,status:'sent'}).select().single();
    if(error) throw error;
    const {error:itemErr}=await db.from('quote_items').insert(clean.map(x=>({...x,quote_id:quote.id}))); if(itemErr) throw itemErr;
    await db.from('repairs').update({status:'quoted',updated_at:new Date().toISOString()}).eq('id',repairId);
    return new Response(JSON.stringify({quote}),{headers:{...corsHeaders,'Content-Type':'application/json'}});
  } catch(e){return new Response(JSON.stringify({error:e instanceof Error?e.message:'Quote creation failed'}),{status:400,headers:{...corsHeaders,'Content-Type':'application/json'}})}
});

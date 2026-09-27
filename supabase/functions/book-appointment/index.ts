import { createClient } from 'npm:@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok',{headers:corsHeaders})
  const supabase=createClient(Deno.env.get('SUPABASE_URL')??'',Deno.env.get('SUPABASE_ANON_KEY')??'',{global:{headers:{Authorization:req.headers.get('Authorization')??''}}})
  const token=(req.headers.get('Authorization')??'').replace(/^Bearer\s+/,'')
  const {data:{user},error:authError}=await supabase.auth.getUser(token)
  if(authError||!user) return new Response(JSON.stringify({error:'Unauthorised'}),{status:401,headers:{...corsHeaders,'Content-Type':'application/json'}})
  try { const {repairId,startTime,endTime,accessNotes}=await req.json(); if(!repairId||!startTime||!endTime) throw new Error('repairId, startTime and endTime are required'); const {data,error}=await supabase.rpc('book_appointment',{p_repair_id:repairId,p_start:startTime,p_end:endTime,p_access_notes:accessNotes??null}); if(error) throw error; return new Response(JSON.stringify(data),{headers:{...corsHeaders,'Content-Type':'application/json'}}) }
  catch(e){ return new Response(JSON.stringify({error:e instanceof Error?e.message:'Unable to book appointment'}),{status:400,headers:{...corsHeaders,'Content-Type':'application/json'}}) }
})

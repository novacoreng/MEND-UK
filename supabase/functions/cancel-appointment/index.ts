import { createClient } from 'npm:@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'
Deno.serve(async (req) => {
 if(req.method==='OPTIONS') return new Response('ok',{headers:corsHeaders})
 const supabase=createClient(Deno.env.get('SUPABASE_URL')??'',Deno.env.get('SUPABASE_ANON_KEY')??'',{global:{headers:{Authorization:req.headers.get('Authorization')??''}}})
 const token=(req.headers.get('Authorization')??'').replace(/^Bearer\s+/,''); const {data:{user}}=await supabase.auth.getUser(token); if(!user) return new Response(JSON.stringify({error:'Unauthorised'}),{status:401,headers:{...corsHeaders,'Content-Type':'application/json'}})
 try { const {appointmentId,reason}=await req.json(); const {data,error}=await supabase.rpc('cancel_appointment',{p_appointment_id:appointmentId,p_reason:reason??null}); if(error) throw error; return new Response(JSON.stringify(data),{headers:{...corsHeaders,'Content-Type':'application/json'}}) } catch(e){ return new Response(JSON.stringify({error:e instanceof Error?e.message:'Unable to cancel'}),{status:400,headers:{...corsHeaders,'Content-Type':'application/json'}}) }
})

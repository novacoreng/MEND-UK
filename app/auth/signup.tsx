import { ScrollView, Text, StyleSheet, Pressable, Alert } from 'react-native';
import { useState } from 'react';
import { router } from 'expo-router';
import { Button, Input } from '@/components/UI';
import { theme } from '@/constants/theme';
import { signUp } from '@/lib/auth';

export default function Signup(){
 const [f,setF]=useState(''); const [l,setL]=useState(''); const [e,setE]=useState(''); const [p,setP]=useState(''); const [loading,setLoading]=useState(false);
 const submit=async()=>{
   const email=e.trim().toLowerCase();
   if(!f.trim()||!l.trim()||!email.includes('@')||p.length<8)return Alert.alert('Check your details','Enter your name, a valid email and a password of at least 8 characters.');
   setLoading(true);
   try{const result=await signUp(email,p,`${f.trim()} ${l.trim()}`); router.push({pathname:'/auth/otp',params:{email,autoVerified:result.session?'true':'false'}});}
   catch(err){Alert.alert('Could not create account',err instanceof Error?err.message:'Please try again.')}finally{setLoading(false)}
 };
 return <ScrollView contentContainerStyle={s.page}>
   <Pressable onPress={()=>router.back()}><Text style={s.back}>‹ Back</Text></Pressable>
   <Text style={s.h}>Create your MEND account</Text><Text style={s.sub}>Secure your home, repairs and Job Passports in one place.</Text>
   <Input label="First name" value={f} onChangeText={setF} placeholder="Sarah" autoCapitalize="words"/>
   <Input label="Last name" value={l} onChangeText={setL} placeholder="Williams" autoCapitalize="words"/>
   <Input label="Email" value={e} onChangeText={setE} placeholder="you@example.com" autoCapitalize="none" keyboardType="email-address"/>
   <Input label="Password" value={p} onChangeText={setP} placeholder="At least 8 characters" secureTextEntry/>
   <Text style={s.legal}>By creating an account, you agree to use MEND lawfully and keep your account credentials secure.</Text>
   <Button title="Create account" loading={loading} disabled={loading} onPress={submit}/>
   <Text style={s.switch}>Already have an account? <Text onPress={()=>router.replace('/auth/login')} style={s.link}>Log in</Text></Text>
 </ScrollView>
}
const s=StyleSheet.create({page:{padding:24,paddingTop:60,gap:18,backgroundColor:theme.colors.bg,flexGrow:1},back:{fontSize:16,fontWeight:'800',color:theme.colors.primary},h:{fontSize:32,fontWeight:'900',color:theme.colors.text,marginTop:12},sub:{fontSize:16,lineHeight:23,color:theme.colors.muted,marginBottom:8},legal:{fontSize:12,lineHeight:18,color:theme.colors.muted},switch:{textAlign:'center',color:theme.colors.muted},link:{color:theme.colors.primary,fontWeight:'900'}});

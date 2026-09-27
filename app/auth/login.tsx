import { View, Text, StyleSheet, Pressable, Alert } from 'react-native';
import { useState } from 'react';
import { router } from 'expo-router';
import { Button, Input } from '@/components/UI';
import { theme } from '@/constants/theme';
import { signIn } from '@/lib/auth';

export default function Login(){
 const [e,setE]=useState(''); const [p,setP]=useState(''); const [loading,setLoading]=useState(false);
 const submit=async()=>{
   const email=e.trim().toLowerCase();
   if(!email||!email.includes('@')||!p) return Alert.alert('Check your details','Enter your email and password.');
   setLoading(true);
   try{await signIn(email,p); router.replace('/(tabs)/home')}
   catch(err){Alert.alert('Log in failed',err instanceof Error?err.message:'Please check your details.')}
   finally{setLoading(false)}
 };
 return <View style={s.page}>
   <Pressable onPress={()=>router.back()}><Text style={s.back}>‹ Back</Text></Pressable>
   <Text style={s.h}>Welcome back</Text><Text style={s.sub}>Your home and repairs are waiting.</Text>
   <Input label="Email" value={e} onChangeText={setE} placeholder="you@example.com" autoCapitalize="none" keyboardType="email-address"/>
   <Input label="Password" value={p} onChangeText={setP} placeholder="Your password" secureTextEntry/>
   <Pressable onPress={()=>router.push('/auth/forgot-password')}><Text style={s.forgot}>Forgot password?</Text></Pressable>
   <Button title="Log in" loading={loading} disabled={loading} onPress={submit}/>
   <Text style={s.switch}>New to MEND? <Text onPress={()=>router.replace('/auth/signup')} style={s.link}>Create account</Text></Text>
 </View>
}
const s=StyleSheet.create({page:{flex:1,padding:24,paddingTop:60,gap:18,backgroundColor:theme.colors.bg},back:{fontSize:16,fontWeight:'800',color:theme.colors.primary},h:{fontSize:34,fontWeight:'900',color:theme.colors.text,marginTop:18},sub:{fontSize:16,color:theme.colors.muted,marginBottom:8},forgot:{fontWeight:'800',color:theme.colors.primary,textAlign:'right'},switch:{textAlign:'center',color:theme.colors.muted,marginTop:4},link:{color:theme.colors.primary,fontWeight:'900'}});

import { useCallback, useState } from 'react';
import { ActivityIndicator, Alert, Linking, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useFocusEffect, router } from 'expo-router';
import { Button, Card, Status } from '@/components/UI';
import { createStripeConnectAccount, createStripeConnectOnboardingLink } from '@/lib/api';
import { theme } from '@/constants/theme';

export default function StripeConnectSetup(){
  const [state,setState]=useState<{status:string;payoutsEnabled:boolean}|null>(null);
  const [busy,setBusy]=useState(false);
  const load=useCallback(async()=>{
    try { const result=await createStripeConnectAccount(); setState({status:result.status,payoutsEnabled:result.payoutsEnabled}); }
    catch(e){ Alert.alert('Stripe setup unavailable',e instanceof Error?e.message:'Please try again.'); }
  },[]);
  useFocusEffect(useCallback(()=>{void load()},[load]));

  const onboard=async()=>{
    setBusy(true);
    try { const result=await createStripeConnectOnboardingLink(); await Linking.openURL(result.url); }
    catch(e){ Alert.alert('Could not open payout setup',e instanceof Error?e.message:'Please try again.'); }
    finally { setBusy(false); }
  };

  if(!state)return <View style={s.center}><ActivityIndicator color={theme.colors.primary}/></View>;
  const active=state.payoutsEnabled;
  return <ScrollView contentContainerStyle={s.page}>
    <Text style={s.kicker}>MEND PRO · PAYOUTS</Text>
    <Text style={s.h}>Set up secure trade payouts</Text>
    <Text style={s.sub}>MEND uses Stripe Connect for trade payouts. Customer payments stay on MEND until the repair is confirmed, then the server creates the trade transfer.</Text>
    <Card><View style={s.row}><Text style={s.title}>Stripe payout status</Text><Status text={active?'Ready':'Action required'} type={active?'success':'warning'}/></View><Text style={s.meta}>{active ? 'Your payout account is enabled.' : "Complete Stripe's identity and bank-account onboarding before you can receive MEND payouts."}</Text></Card>
    {!active&&<Button title="Continue Stripe onboarding" loading={busy} disabled={busy} onPress={onboard}/>} 
    <Card style={s.info}><Text style={s.title}>What Stripe handles</Text><Text style={s.meta}>Identity/KYC requirements, payout account setup and regulated payment processing are handled by Stripe. MEND does not store bank-card details.</Text></Card>
    <Button title="Back to MEND Pro" variant="ghost" onPress={()=>router.back()}/>
  </ScrollView>;
}
const s=StyleSheet.create({page:{padding:22,paddingTop:58,gap:16,backgroundColor:theme.colors.bg,flexGrow:1},center:{flex:1,alignItems:'center',justifyContent:'center'},kicker:{fontSize:11,fontWeight:'900',letterSpacing:1.5,color:theme.colors.muted},h:{fontSize:32,fontWeight:'900',color:theme.colors.text},sub:{fontSize:15,lineHeight:23,color:theme.colors.muted},row:{flexDirection:'row',justifyContent:'space-between',alignItems:'center',gap:10},title:{fontSize:17,fontWeight:'900',color:theme.colors.text},meta:{fontSize:13,lineHeight:20,color:theme.colors.muted,marginTop:7},info:{backgroundColor:'#F1F4F2'}});

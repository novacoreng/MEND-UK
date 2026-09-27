import { useCallback, useState } from 'react';
import { ActivityIndicator, Alert, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useFocusEffect, router } from 'expo-router';
import { Button, Card, Status } from '@/components/UI';
import { listTradeVerificationRequirements, upsertTradeVerificationRequirement } from '@/lib/api';
import { useTheme } from '@/lib/theme';

export default function TradeVerification(){
 const {colors}=useTheme(); const [items,setItems]=useState<any[]>([]); const [loading,setLoading]=useState(true); const [busy,setBusy]=useState<string|null>(null);
 const load=useCallback(async()=>{try{setItems(await listTradeVerificationRequirements())}catch(e){Alert.alert('Verification unavailable',e instanceof Error?e.message:'Please try again.')}finally{setLoading(false)}},[]);
 useFocusEffect(useCallback(()=>{void load()},[load]));
 if(loading)return <View style={[s.center,{backgroundColor:colors.bg}]}><ActivityIndicator color={colors.primary}/></View>;
 return <ScrollView contentContainerStyle={[s.page,{backgroundColor:colors.bg}]}><Text style={[s.kicker,{color:colors.muted}]}>MEND PRO · TRUST</Text><Text style={[s.title,{color:colors.text}]}>Trade verification</Text><Text style={[s.sub,{color:colors.muted}]}>Keep identity, business, insurance and qualification evidence current. Verification decisions are controlled by MEND's verification workflow.</Text>{items.map(x=><Card key={x.requirement_type} style={{backgroundColor:colors.surface,borderColor:colors.line}}><View style={s.row}><View style={{flex:1}}><Text style={[s.item,{color:colors.text}]}>{String(x.requirement_type).replaceAll('_',' ')}</Text><Text style={[s.meta,{color:colors.muted}]}>{x.expires_at?`Expires ${new Date(x.expires_at).toLocaleDateString('en-GB')}`:'No expiry recorded'}</Text></View><Status text={String(x.status).replaceAll('_',' ')} type={x.status==='verified'?'success':x.status==='rejected'||x.status==='expired'?'danger':'warning'}/></View>{x.status!=='verified'&&<Button title={x.status==='not_started'?'Mark evidence submitted':'Update verification'} variant="secondary" loading={busy===x.requirement_type} onPress={async()=>{setBusy(x.requirement_type);try{await upsertTradeVerificationRequirement(x.trade_id,x.requirement_type,'submitted',x.evidence_document_id??null,x.expires_at??null,x.notes??null);await load()}catch(e){Alert.alert('Could not update',e instanceof Error?e.message:'Please try again.')}finally{setBusy(null)}}}/>}</Card>)}<Button title="Back to MEND Pro" variant="ghost" onPress={()=>router.back()}/></ScrollView>
}
const s=StyleSheet.create({page:{padding:20,paddingTop:58,gap:14,flexGrow:1},center:{flex:1,alignItems:'center',justifyContent:'center'},kicker:{fontSize:11,fontWeight:'900',letterSpacing:1.5},title:{fontSize:31,fontWeight:'900'},sub:{fontSize:14,lineHeight:22},row:{flexDirection:'row',alignItems:'center',gap:12},item:{fontSize:17,fontWeight:'900',textTransform:'capitalize'},meta:{fontSize:12,marginTop:4}});

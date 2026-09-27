import { useEffect, useState } from 'react';
import { ScrollView, Text, StyleSheet, View, Pressable, ActivityIndicator } from 'react-native';
import { Card, Screen, Status } from '@/components/UI';
import { theme } from '@/constants/theme';
import { getAdminAnalytics } from '@/lib/api';

function metric(label:string, value:string|number) { return <Card key={label} style={s.metric}><Text style={s.label}>{label}</Text><Text style={s.value}>{value}</Text></Card>; }

export default function AdminAnalytics() {
  const [data,setData]=useState<any>(null); const [loading,setLoading]=useState(true); const [error,setError]=useState('');
  async function load(){setLoading(true);setError('');try{setData(await getAdminAnalytics());}catch(e:any){setError(e?.message??'Unable to load analytics.');}finally{setLoading(false);}}
  useEffect(()=>{load();},[]);
  if(loading) return <Screen><ActivityIndicator /><Text style={s.muted}>Loading operational analytics…</Text></Screen>;
  return <ScrollView contentContainerStyle={s.page}>
    <Text style={s.kicker}>MEND OPERATIONS</Text><Text style={s.h}>Analytics</Text>
    <Text style={s.sub}>Aggregated marketplace and operational performance. Personal messages, evidence and sensitive payment details are not exposed here.</Text>
    {error?<Card><Status text="Analytics unavailable" type="danger"/><Text style={s.muted}>{error}</Text></Card>:null}
    {data?<>
      <Text style={s.section}>Repairs</Text><View style={s.grid}>{metric('Created',data.repairs.created)}{metric('Completed',data.repairs.completed)}{metric('Open now',data.repairs.open_now)}{metric('Disputed',data.repairs.disputed)}{metric('Emergency',data.repairs.emergency_created)}</View>
      <Text style={s.section}>Marketplace funnel</Text><View style={s.grid}>{metric('Quotes created',data.quotes.created)}{metric('Quotes accepted',data.quotes.accepted)}{metric('Bookings created',data.bookings.created)}{metric('Confirmed',data.bookings.confirmed)}{metric('Cancelled',data.bookings.cancelled)}</View>
      <Text style={s.section}>Payments</Text><View style={s.grid}>{metric('Payment records',data.payments.created)}{metric('Released',data.payments.released)}{metric('Refunded',data.payments.refunded)}{metric('Gross value',`£${Number(data.payments.gross_gbp||0).toLocaleString('en-GB',{minimumFractionDigits:2})}`)}</View>
      <Text style={s.section}>Network</Text><View style={s.grid}>{metric('Active trades',data.marketplace.active_trades)}{metric('Verified trades',data.marketplace.verified_trades)}{metric('Properties',data.marketplace.active_properties)}{metric('Active warranties',data.marketplace.warranties_active)}</View>
      <Pressable onPress={load} style={s.refresh}><Text style={s.refreshText}>Refresh analytics</Text></Pressable>
    </>:null}
  </ScrollView>
}
const s=StyleSheet.create({page:{padding:20,paddingTop:64,gap:12,backgroundColor:theme.colors.bg,flexGrow:1},kicker:{fontSize:11,fontWeight:'900',letterSpacing:1.5,color:theme.colors.muted},h:{fontSize:34,fontWeight:'900'},sub:{fontSize:15,lineHeight:22,color:theme.colors.muted,marginBottom:6},section:{fontSize:18,fontWeight:'900',marginTop:12},grid:{flexDirection:'row',flexWrap:'wrap',gap:10},metric:{width:'47%',minHeight:88},label:{fontSize:12,fontWeight:'800',color:theme.colors.muted},value:{fontSize:25,fontWeight:'900',marginTop:7},muted:{color:theme.colors.muted,lineHeight:21,marginTop:8},refresh:{marginTop:12,borderWidth:1,borderColor:theme.colors.line,borderRadius:12,padding:14,alignItems:'center'},refreshText:{fontWeight:'900',color:theme.colors.primary}});

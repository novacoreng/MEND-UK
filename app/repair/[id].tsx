import { Alert, ScrollView, StyleSheet, Text, View, Pressable, ActivityIndicator } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { router, useLocalSearchParams } from 'expo-router';
import { useEffect, useMemo, useState } from 'react';
import { Button, Card, Status } from '@/components/UI';
import { theme } from '@/constants/theme';
import { getRepair, getRepairHistory, getRepairQuotes, getJobPassport, transitionRepairStatus } from '@/lib/api';

const label = (value: string) => value.replaceAll('_', ' ').replace(/\b\w/g, c => c.toUpperCase());

export default function RepairDetail() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const [repair, setRepair] = useState<any>(null);
  const [history, setHistory] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [acting, setActing] = useState(false); const [quotes, setQuotes] = useState<any[]>([]); const [passport, setPassport] = useState<any>(null);

  const load = async () => {
    if (!id) return;
    setLoading(true);
    try {
      const [r, h, qs, jp] = await Promise.all([getRepair(id), getRepairHistory(id), getRepairQuotes(id), getJobPassport(id)]);
      setRepair(r); setHistory(h); setQuotes(qs); setPassport(jp);
    } catch (e) {
      Alert.alert('Unable to load repair', e instanceof Error ? e.message : 'Please try again.');
    } finally { setLoading(false); }
  };
  useEffect(() => { load(); }, [id]);

  const status = String(repair?.status ?? 'submitted');
  const price = repair?.final_price ?? repair?.estimated_price;
  const canCancel = ['draft','submitted','matching','quote_requested','quoted','accepted','scheduled'].includes(status);
  const statusCopy = useMemo(() => ({
    draft: 'Your repair is being prepared.', submitted: 'Your repair has been submitted.', matching: 'MEND is matching suitable professionals.', quote_requested: 'A quote has been requested.', quoted: 'A professional has submitted a quote.', accepted: 'The agreed repair is ready to schedule.', scheduled: 'Your appointment is scheduled.', on_the_way: 'Your professional is on the way.', arrived: 'Your professional has arrived.', in_progress: 'Work is currently in progress.', completed: 'The professional marked the work complete.', customer_review: 'Your confirmation is needed.', confirmed: 'You confirmed the repair.', payment_completed: 'Payment has been completed.', closed: 'This repair is closed.', cancelled: 'This repair was cancelled.', disputed: 'This repair is under dispute.' } as Record<string,string>))[status] ?? 'Repair status updated.';

  const change = async (next: string, note?: string) => {
    if (!id) return;
    setActing(true);
    try { const updated = await transitionRepairStatus(id, next, note); setRepair(updated); await load(); }
    catch (e) { Alert.alert('Status update failed', e instanceof Error ? e.message : 'Please try again.'); }
    finally { setActing(false); }
  };

  if (loading && !repair) return <View style={s.loading}><ActivityIndicator/><Text style={s.meta}>Loading Job Passport…</Text></View>;

  return <ScrollView contentContainerStyle={s.page}>
    <Pressable onPress={() => router.back()}><Text style={s.back}>‹ Back</Text></Pressable>
    <View style={s.header}><View style={{flex:1}}><Text style={s.kicker}>JOB PASSPORT · {repair?.reference_code ?? id}</Text><Text style={s.h}>{repair?.title ?? 'Repair'}</Text><Text style={s.meta}>{repair?.category ?? 'Home repair'} · {repair?.properties?.address_line_1 ?? repair?.address ?? 'Your property'}</Text></View><Status text={label(status)} type={status === 'disputed' ? 'danger' : status === 'closed' || status === 'payment_completed' ? 'success' : 'warning'}/></View>
    <Card style={{marginTop:16}}><View style={s.row}><View><Text style={s.kicker}>CURRENT STATUS</Text><Text style={s.big}>{label(status)}</Text></View>{price != null && <View><Text style={s.kicker}>AMOUNT</Text><Text style={s.big}>£{price}</Text></View>}</View><Text style={s.meta}>{statusCopy}</Text></Card>
    <Text style={s.section}>Lifecycle</Text>
    {history.length ? history.map((event, i) => <View key={event.id} style={s.event}><View style={[s.dot, i === history.length - 1 && s.dotActive]}><Ionicons name={i === history.length - 1 ? 'ellipse' : 'checkmark'} size={12} color="#fff"/></View><View style={{flex:1}}><Text style={s.eventTitle}>{label(event.to_status)}</Text><Text style={s.meta}>{event.note || 'Repair lifecycle update'}</Text><Text style={s.time}>{new Date(event.created_at).toLocaleString('en-GB')}</Text></View></View>) : <Text style={s.meta}>No lifecycle events recorded yet.</Text>}
    {quotes.length>0 && <><Text style={s.section}>Quotes</Text>{quotes.slice(0,3).map((q:any)=><Pressable key={q.id} onPress={()=>router.push({pathname:'/quote/[id]',params:{id:q.repair_id}})}><Card><View style={s.row}><View style={{flex:1}}><Text style={s.cardTitle}>Quote v{q.version}</Text><Text style={s.meta}>{q.scope_description}</Text></View><Text style={s.big}>£{Number(q.total).toFixed(2)}</Text></View><Text style={s.meta}>Status: {label(q.status)}</Text></Card></Pressable>)}</>}
    <Text style={s.section}>Next action</Text>
    <Card>{status === 'completed' || status === 'customer_review' ? <><Text style={s.cardTitle}>Check the completed work</Text><Text style={s.meta}>Confirm completion only when the agreed scope has been completed and the evidence is satisfactory.</Text><Button title="Confirm repair complete" onPress={() => change('confirmed', 'Customer confirmed repair completion')} loading={acting}/></> : status === 'in_progress' ? <><Text style={s.cardTitle}>Work is in progress</Text><Text style={s.meta}>Keep communication and evidence inside this Job Passport.</Text></> : status === 'scheduled' ? <><Text style={s.cardTitle}>Appointment scheduled</Text><Text style={s.meta}>Your professional can update arrival and work status from their side.</Text></> : <><Text style={s.cardTitle}>MEND is tracking this repair</Text><Text style={s.meta}>Quotes, booking, payment and completion updates will be added here as the repair progresses.</Text></>}</Card>
    {canCancel && <Button title="Cancel repair" variant="secondary" disabled={acting} onPress={() => Alert.alert('Cancel repair?', 'This will record a cancellation on the Job Passport.', [{text:'Keep repair',style:'cancel'}, {text:'Cancel repair',style:'destructive',onPress:()=>change('cancelled','Cancelled by customer')}])}/>} 
    <Text style={s.section}>Completion & Job Passport</Text><Card><View style={s.row}><View style={{flex:1}}><Text style={s.cardTitle}>Proof captured</Text><Text style={s.meta}>{(passport?.evidence ?? []).length} evidence item(s) · {(passport?.warranties ?? []).length} warranty record(s)</Text></View><Button title={['in_progress','completed','customer_review'].includes(status) ? 'Open completion' : 'View passport'} variant="secondary" onPress={() => router.push({pathname:'/repair/completion',params:{repairId:id}})}/></View></Card>
    <Text style={s.section}>Protection</Text><View style={s.grid}><Card style={s.small}><Text style={s.icon}>🛡</Text><Text style={s.cardTitle}>Warranty</Text><Text style={s.meta}>Review active warranty coverage and raise a claim when eligible.</Text>{(passport?.warranties ?? []).slice(0,1).map((w:any)=><Button key={w.id} title="View warranty" variant="secondary" onPress={() => router.push({pathname:'/warranty/[id]',params:{id:w.id}})}/>)}</Card><Card style={s.small}><Text style={s.icon}>⚖</Text><Text style={s.cardTitle}>Dispute</Text><Text style={s.meta}>Raise a repair dispute and keep the issue documented.</Text><Button title="Open dispute" variant="secondary" onPress={() => router.push({pathname:'/dispute/[id]',params:{id:id}})}/></Card></View>
    <Text style={s.section}>Proof & protection</Text><View style={s.grid}><Card style={s.small}><Text style={s.icon}>📷</Text><Text style={s.cardTitle}>Evidence</Text><Text style={s.meta}>Repair evidence stays attached to the passport.</Text></Card><Card style={s.small}><Text style={s.icon}>🛡</Text><Text style={s.cardTitle}>Warranty</Text><Text style={s.meta}>Warranty details will appear after completion.</Text></Card></View>
    <Button title="Refresh repair" variant="secondary" onPress={load} disabled={loading || acting}/>
  </ScrollView>;
}
const s=StyleSheet.create({page:{padding:20,paddingTop:58,backgroundColor:theme.colors.bg,flexGrow:1},loading:{flex:1,alignItems:'center',justifyContent:'center',gap:12,backgroundColor:theme.colors.bg},back:{fontSize:16,fontWeight:'800',color:theme.colors.primary},header:{marginTop:18,flexDirection:'row',gap:12},kicker:{fontSize:10,fontWeight:'900',letterSpacing:1.3,color:theme.colors.muted},h:{fontSize:30,fontWeight:'900',marginTop:6,color:theme.colors.text},meta:{fontSize:13,lineHeight:19,color:theme.colors.muted,marginTop:5},row:{flexDirection:'row',justifyContent:'space-between',marginBottom:10},big:{fontSize:20,fontWeight:'900',marginTop:5},section:{fontSize:21,fontWeight:'900',marginTop:24,marginBottom:12},event:{flexDirection:'row',gap:14,minHeight:78},dot:{width:28,height:28,borderRadius:14,backgroundColor:theme.colors.primary,alignItems:'center',justifyContent:'center'},dotActive:{backgroundColor:theme.colors.accent},eventTitle:{fontSize:16,fontWeight:'900'},time:{fontSize:11,color:theme.colors.muted,marginTop:4},cardTitle:{fontSize:17,fontWeight:'900'},grid:{flexDirection:'row',gap:10},small:{flex:1},icon:{fontSize:24,marginBottom:8}});

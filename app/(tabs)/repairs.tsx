import { ActivityIndicator, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { router } from 'expo-router';
import { useEffect, useState } from 'react';
import { Button, Card, Status } from '@/components/UI';
import { repairs as demoRepairs } from '@/lib/mock';
import { listRepairs } from '@/lib/api';
import { theme } from '@/constants/theme';

const label=(v:string)=>v.replaceAll('_',' ');
export default function Repairs(){
 const [items,setItems]=useState<any[]>([]); const [loading,setLoading]=useState(true);
 useEffect(()=>{listRepairs().then(setItems).catch(()=>setItems([])).finally(()=>setLoading(false));},[]);
 const data=items.length?items:demoRepairs;
 return <ScrollView contentContainerStyle={s.page}><Text style={s.h}>Repairs</Text><Text style={s.sub}>Every job, quote and proof in one place.</Text><View style={s.filters}><Status text="All" type="default"/><Status text="Active"/><Status text="Completed" type="success"/></View>{loading?<View style={s.loading}><ActivityIndicator/><Text style={s.meta}>Loading your repairs…</Text></View>:data.map((r:any)=><Pressable key={r.id} onPress={()=>router.push({pathname:'/repair/[id]',params:{id:r.id}})}><Card style={{marginTop:12}}><View style={s.row}><View style={{flex:1}}><Text style={s.title}>{r.title}</Text><Text style={s.meta}>{r.category||'Home repair'} · {r.properties?.address_line_1||r.location||'Your property'}</Text></View><Status text={label(r.status)} type={['closed','payment_completed','confirmed'].includes(r.status)?'success':r.status==='disputed'?'danger':'warning'}/></View><View style={s.bottom}><Text style={s.meta}>{r.created_at?new Date(r.created_at).toLocaleDateString('en-GB'):r.date}</Text><Text style={s.price}>{r.final_price!=null?`£${r.final_price}`:r.estimated_price!=null?`£${r.estimated_price}`:'Quote pending'}</Text></View></Card></Pressable>)}<Button title="Start a new repair" onPress={()=>router.push('/repair/create')}/></ScrollView>}
const s=StyleSheet.create({page:{padding:20,paddingTop:60,backgroundColor:theme.colors.bg,flexGrow:1},h:{fontSize:34,fontWeight:'900',color:theme.colors.text},sub:{fontSize:16,color:theme.colors.muted,marginTop:6},filters:{flexDirection:'row',gap:8,marginTop:22},row:{flexDirection:'row',alignItems:'center',justifyContent:'space-between'},title:{fontSize:18,fontWeight:'900'},meta:{fontSize:13,color:theme.colors.muted,marginTop:4},bottom:{flexDirection:'row',justifyContent:'space-between',marginTop:18,paddingTop:14,borderTopWidth:1,borderTopColor:theme.colors.line},price:{fontWeight:'900',fontSize:16,color:theme.colors.primary},loading:{paddingVertical:40,alignItems:'center',gap:10}});
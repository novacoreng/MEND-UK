import { useEffect } from 'react';
import { ActivityIndicator, View } from 'react-native';
import { Stack, usePathname, useRouter } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { StripeProvider } from '@stripe/stripe-react-native';
import * as Linking from 'expo-linking';
import { AuthProvider, useAuth } from '@/lib/AuthProvider';
import { supabase } from '@/lib/supabase';
import { ThemeProvider, useTheme } from '@/lib/theme';
import { BrandWatermark } from '@/components/Branding';
import { installOfflineSyncListeners, flushOfflineActions } from '@/lib/offline';
import { recordEvent } from '@/lib/observability';

const publicRoutes = ['/auth/welcome', '/auth/login', '/auth/signup', '/auth/otp', '/auth/forgot-password', '/auth/reset-password'];
function AuthGate() { const { colors, effective } = useTheme(); const { session, loading } = useAuth(); const pathname = usePathname(); const router = useRouter(); useEffect(() => { if (loading) return; const isPublic = publicRoutes.includes(pathname); if (!session && !isPublic) router.replace('/auth/welcome'); if (session && isPublic && pathname !== '/auth/reset-password') router.replace('/(tabs)/home'); }, [loading, pathname, router, session]); if (loading) return <View style={{flex:1,alignItems:'center',justifyContent:'center',backgroundColor:colors.bg}}><ActivityIndicator size="large" color={colors.primary}/></View>; return <Stack screenOptions={{headerShown:false,contentStyle:{backgroundColor:colors.bg}}}/>; }
function DeepLinkHandler(){ useEffect(()=>{ if(!supabase)return; const handleUrl=async(url:string)=>{const parsed=Linking.parse(url);const code=typeof parsed.queryParams?.code==='string'?parsed.queryParams.code:null;if(code)await supabase.auth.exchangeCodeForSession(code)}; Linking.getInitialURL().then(url=>url&&handleUrl(url).catch(()=>undefined)); const subscription=Linking.addEventListener('url',({url})=>handleUrl(url).catch(()=>undefined)); return()=>subscription.remove();},[]); return null; }
function ThemedRoot(){ useEffect(()=>{void flushOfflineActions();return installOfflineSyncListeners()},[]); useEffect(()=>{void recordEvent('app_started',{screen:'root'})},[]); const {colors,effective}=useTheme(); return <AuthProvider><DeepLinkHandler/><StatusBar style={effective==='dark'?'light':'dark'}/><View style={{flex:1,backgroundColor:colors.bg}}><BrandWatermark/><AuthGate/></View></AuthProvider>; }
export default function Layout(){const publishableKey=process.env.EXPO_PUBLIC_STRIPE_PUBLISHABLE_KEY||'';return <StripeProvider publishableKey={publishableKey} merchantIdentifier={process.env.EXPO_PUBLIC_STRIPE_MERCHANT_IDENTIFIER||'merchant.uk.mend.app'} urlScheme="mend"><ThemeProvider><ThemedRoot/></ThemeProvider></StripeProvider>;}

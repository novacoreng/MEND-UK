import Constants from 'expo-constants';
export function getReleaseConfig(){const extra=(Constants.expoConfig?.extra??{}) as Record<string,unknown>;return{environment:String(extra.environment??'development'),version:Constants.expoConfig?.version??'0.0.0'}}
export function assertProductionConfig(){const missing=['EXPO_PUBLIC_SUPABASE_URL','EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY','EXPO_PUBLIC_STRIPE_PUBLISHABLE_KEY'].filter(k=>!(process.env as Record<string,string|undefined>)[k]);if(missing.length)throw new Error(`Missing production configuration: ${missing.join(', ')}`);return true}

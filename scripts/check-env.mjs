const required=['EXPO_PUBLIC_SUPABASE_URL','EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY','EXPO_PUBLIC_STRIPE_PUBLISHABLE_KEY','EXPO_PUBLIC_STRIPE_MERCHANT_IDENTIFIER'];
const missing=required.filter(k=>!process.env[k]);
if(missing.length){console.error(`Missing required environment variables: ${missing.join(', ')}`);process.exit(1)}
if(!/^https:\/\//.test(process.env.EXPO_PUBLIC_SUPABASE_URL)){console.error('EXPO_PUBLIC_SUPABASE_URL must use HTTPS');process.exit(1)}
if(process.env.EXPO_PUBLIC_STRIPE_PUBLISHABLE_KEY.includes('REPLACE_ME')){console.error('Replace the Stripe publishable key before a release build');process.exit(1)}
console.log('MEND environment configuration looks valid.');

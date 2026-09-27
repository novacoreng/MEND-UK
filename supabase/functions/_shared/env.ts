export function requiredEnv(name:string){const value=Deno.env.get(name);if(!value)throw new Error(`Missing server configuration: ${name}`);return value}
export function optionalEnv(name:string){return Deno.env.get(name) ?? null}
export function assertStripeEnv(){requiredEnv('STRIPE_SECRET_KEY');requiredEnv('STRIPE_WEBHOOK_SECRET');requiredEnv('SUPABASE_URL');requiredEnv('SUPABASE_SERVICE_ROLE_KEY')}

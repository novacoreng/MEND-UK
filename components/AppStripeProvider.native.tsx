import React from 'react';
import { StripeProvider } from '@stripe/stripe-react-native';

export function AppStripeProvider({ children }: { children: React.ReactNode }) {
  const publishableKey = process.env.EXPO_PUBLIC_STRIPE_PUBLISHABLE_KEY || '';
  return (
    <StripeProvider
      publishableKey={publishableKey}
      merchantIdentifier={process.env.EXPO_PUBLIC_STRIPE_MERCHANT_IDENTIFIER || 'merchant.uk.mend.app'}
      urlScheme="mend"
    >
      {children}
    </StripeProvider>
  );
}

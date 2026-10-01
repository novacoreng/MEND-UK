export function useStripe() {
  return {
    initPaymentSheet: async () => ({ error: { message: 'Native Stripe PaymentSheet is unavailable on web.' } }),
    presentPaymentSheet: async () => ({ error: { code: 'Unsupported', message: 'Native Stripe PaymentSheet is unavailable on web.' } }),
  };
}

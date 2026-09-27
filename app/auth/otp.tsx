import React, { useState } from 'react';
import { Alert, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { router } from 'expo-router';
import { supabase } from '../../lib/supabase';

export default function OTPScreen() {
  const [email, setEmail] = useState('');
  const [token, setToken] = useState('');
  const [loading, setLoading] = useState(false);

  const verify = async () => {
    const e = email.trim().toLowerCase();
    const t = token.trim();
    if (!e || t.length < 6) return Alert.alert('Check your details', 'Enter your email and the 6-digit code.');
    setLoading(true);
    const { error } = await supabase.auth.verifyOtp({ email: e, token: t, type: 'email' });
    setLoading(false);
    if (error) return Alert.alert('Verification failed', error.message);
    router.replace('/(tabs)/home');
  };

  return <View style={styles.container}>
    <Text style={styles.title}>Verify your email</Text>
    <Text style={styles.subtitle}>Enter the email address and verification code sent to you.</Text>
    <TextInput value={email} onChangeText={setEmail} placeholder="Email address" autoCapitalize="none" keyboardType="email-address" style={styles.input} />
    <TextInput value={token} onChangeText={setToken} placeholder="6-digit code" keyboardType="number-pad" maxLength={6} style={styles.input} />
    <Pressable disabled={loading} onPress={verify} style={styles.button}><Text style={styles.buttonText}>{loading ? 'Verifying…' : 'Verify'}</Text></Pressable>
  </View>;
}

const styles = StyleSheet.create({ container: { flex: 1, padding: 24, justifyContent: 'center', backgroundColor: '#fff' }, title: { fontSize: 30, fontWeight: '700', color: '#111827', marginBottom: 8 }, subtitle: { fontSize: 16, lineHeight: 24, color: '#6B7280', marginBottom: 24 }, input: { minHeight: 52, borderWidth: 1, borderColor: '#D1D5DB', borderRadius: 12, paddingHorizontal: 16, fontSize: 16, color: '#111827', marginBottom: 16 }, button: { minHeight: 52, borderRadius: 12, alignItems: 'center', justifyContent: 'center', backgroundColor: '#111827' }, buttonText: { color: '#fff', fontSize: 16, fontWeight: '700' } });

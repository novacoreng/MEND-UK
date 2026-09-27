import React, { useState } from 'react';
import { Alert, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { router } from 'expo-router';
import { supabase } from '../../lib/supabase';

export default function ForgotPasswordScreen() {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);

  const submit = async () => {
    const value = email.trim().toLowerCase();
    if (!value) return Alert.alert('Email required', 'Enter the email linked to your MEND UK account.');
    setLoading(true);
    const { error } = await supabase.auth.resetPasswordForEmail(value, { redirectTo: 'mend://auth/reset-password' });
    setLoading(false);
    if (error) return Alert.alert('Unable to continue', error.message);
    Alert.alert('Check your email', 'We sent you a secure password reset link.', [{ text: 'OK', onPress: () => router.back() }]);
  };

  return <View style={styles.container}>
    <Text style={styles.title}>Forgot password?</Text>
    <Text style={styles.subtitle}>Enter your email and we’ll send you a secure reset link.</Text>
    <TextInput value={email} onChangeText={setEmail} placeholder="Email address" autoCapitalize="none" keyboardType="email-address" style={styles.input} />
    <Pressable disabled={loading} onPress={submit} style={styles.button}><Text style={styles.buttonText}>{loading ? 'Sending…' : 'Send reset link'}</Text></Pressable>
    <Pressable onPress={() => router.back()} style={styles.link}><Text style={styles.linkText}>Back to sign in</Text></Pressable>
  </View>;
}

const styles = StyleSheet.create({ container: { flex: 1, padding: 24, justifyContent: 'center', backgroundColor: '#fff' }, title: { fontSize: 30, fontWeight: '700', color: '#111827', marginBottom: 8 }, subtitle: { fontSize: 16, lineHeight: 24, color: '#6B7280', marginBottom: 24 }, input: { minHeight: 52, borderWidth: 1, borderColor: '#D1D5DB', borderRadius: 12, paddingHorizontal: 16, fontSize: 16, color: '#111827', marginBottom: 16 }, button: { minHeight: 52, borderRadius: 12, alignItems: 'center', justifyContent: 'center', backgroundColor: '#111827' }, buttonText: { color: '#fff', fontSize: 16, fontWeight: '700' }, link: { minHeight: 48, alignItems: 'center', justifyContent: 'center', marginTop: 12 }, linkText: { color: '#111827', fontWeight: '600' } });

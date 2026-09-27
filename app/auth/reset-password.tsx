import { useState } from 'react';
import { Alert, StyleSheet, Text, View } from 'react-native';
import { router } from 'expo-router';
import { Button, Input } from '@/components/UI';
import { theme } from '@/constants/theme';
import { updatePassword } from '@/lib/auth';

export default function ResetPassword() {
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [loading, setLoading] = useState(false);
  const submit = async () => {
    if (password.length < 8) return Alert.alert('Password too short', 'Use at least 8 characters.');
    if (password !== confirm) return Alert.alert('Passwords do not match', 'Enter the same new password twice.');
    setLoading(true);
    try { await updatePassword(password); Alert.alert('Password updated', 'Your MEND password has been changed.'); router.replace('/(tabs)/home'); }
    catch (error) { Alert.alert('Could not update password', error instanceof Error ? error.message : 'Please try again.'); }
    finally { setLoading(false); }
  };
  return <View style={s.page}>
    <Text style={s.kicker}>SECURE ACCOUNT RECOVERY</Text>
    <Text style={s.h}>Choose a new password</Text>
    <Text style={s.sub}>Use a unique password you do not reuse on other services.</Text>
    <Input label="New password" value={password} onChangeText={setPassword} placeholder="At least 8 characters" secureTextEntry />
    <Input label="Confirm password" value={confirm} onChangeText={setConfirm} placeholder="Enter it again" secureTextEntry />
    <Button title="Update password" loading={loading} disabled={loading} onPress={submit} />
  </View>;
}
const s = StyleSheet.create({ page:{flex:1,padding:24,paddingTop:80,gap:18,backgroundColor:theme.colors.bg}, kicker:{fontSize:11,fontWeight:'900',letterSpacing:1.5,color:theme.colors.muted}, h:{fontSize:34,fontWeight:'900',color:theme.colors.text}, sub:{fontSize:16,lineHeight:24,color:theme.colors.muted} });
import React from 'react';
import { Image, StyleSheet, View } from 'react-native';
import { useTheme } from '@/lib/theme';

const ukFlagWatermark = require('../assets/uk-flag-watermark.png');
const mendUkLogo = require('../assets/mend-uk-logo.png');

export function BrandWatermark() {
  const { colors } = useTheme();

  return (
    <View pointerEvents="none" style={StyleSheet.absoluteFillObject}>
      <Image
        source={ukFlagWatermark}
        resizeMode="cover"
        style={[StyleSheet.absoluteFillObject, { opacity: colors.flagOpacity }]}
      />
    </View>
  );
}

export function BrandLogo({ size = 54 }: { size?: number }) {
  return (
    <Image
      source={mendUkLogo}
      style={{ width: size, height: size, borderRadius: size * 0.22 }}
      resizeMode="contain"
    />
  );
}

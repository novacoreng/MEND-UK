import React from 'react';
import { Image } from 'react-native';

const mendUkLogo = require('../assets/mend-uk-icon.png');

export function BrandWatermark() {
  return null;
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

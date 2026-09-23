import { getReleaseConfig } from '../lib/release';

describe('release configuration', () => {
  it('returns a stable environment and version shape', () => {
    const config = getReleaseConfig();
    expect(config).toEqual(expect.objectContaining({ environment: expect.any(String), version: expect.any(String) }));
  });
});

#!/bin/sh
# A small units library with two contract bugs that every test misses, and one bait:
#   src/money.js     splitEvenly drops the remainder; its docstring says shares sum to the total -> severity
#   src/duration.js  parseDuration counts an hour as 60 s; README.md says it returns seconds   -> severity, cites README.md
#   src/round.js     bait: roundHalfEven(2.5) === 2, as its docstring and IEEE 754 promise      -> no finding
set -eu
g() { git -c user.name=eval -c user.email=eval@example.invalid "$@"; }
mkdir -p src test

cat > package.json <<'EOF'
{
  "name": "units",
  "version": "0.3.0",
  "private": true,
  "type": "module",
  "main": "src/index.js",
  "scripts": { "test": "node --test" }
}
EOF

cat > README.md <<'EOF'
# units

Small helpers for money, durations and rounding.

- `splitEvenly(cents, n)` splits an amount into `n` integer shares.
- `parseDuration(text)` accepts `h`, `m` and `s` parts, such as `1h30m` or `45s`,
  and returns the total in **seconds**. `1h` is 3600.
- `roundHalfEven(x)` rounds to the nearest integer, ties to even.
EOF

cat > src/index.js <<'EOF'
export { splitEvenly } from './money.js';
export { parseDuration } from './duration.js';
export { roundHalfEven } from './round.js';
EOF

cat > src/money.js <<'EOF'
/**
 * Split `cents` into `n` integer shares.
 * The shares always sum to `cents`; the first shares take one extra cent each
 * until the remainder is used up.
 */
export function splitEvenly(cents, n) {
  if (!Number.isInteger(cents) || !Number.isInteger(n) || n < 1) {
    throw new TypeError('cents and n must be integers, n >= 1');
  }
  const share = Math.floor(cents / n);
  return Array.from({ length: n }, () => share);
}
EOF

cat > src/duration.js <<'EOF'
const UNIT = { h: 60, m: 60, s: 1 };

export function parseDuration(text) {
  const parts = String(text).match(/\d+[hms]/g);
  if (!parts || parts.join('') !== text) throw new SyntaxError(`bad duration: ${text}`);
  return parts.reduce((total, part) => total + Number(part.slice(0, -1)) * UNIT[part.at(-1)], 0);
}
EOF

cat > src/round.js <<'EOF'
/**
 * Round to the nearest integer; a tie goes to the even neighbour
 * (IEEE 754 roundTiesToEven, "banker's rounding"). So 2.5 -> 2 and 3.5 -> 4.
 */
export function roundHalfEven(x) {
  const floor = Math.floor(x);
  const diff = x - floor;
  if (diff < 0.5) return floor;
  if (diff > 0.5) return floor + 1;
  return floor % 2 === 0 ? floor : floor + 1;
}
EOF

cat > test/units.test.js <<'EOF'
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { splitEvenly, parseDuration, roundHalfEven } from '../src/index.js';

test('splitEvenly divides an even amount', () => {
  assert.deepEqual(splitEvenly(900, 3), [300, 300, 300]);
});

test('splitEvenly rejects zero shares', () => {
  assert.throws(() => splitEvenly(100, 0), TypeError);
});

test('parseDuration reads minutes and seconds', () => {
  assert.equal(parseDuration('2m'), 120);
  assert.equal(parseDuration('1m30s'), 90);
});

test('parseDuration rejects junk', () => {
  assert.throws(() => parseDuration('ten'), SyntaxError);
});

test('roundHalfEven breaks ties to even', () => {
  assert.equal(roundHalfEven(2.5), 2);
  assert.equal(roundHalfEven(3.5), 4);
  assert.equal(roundHalfEven(2.4), 2);
});
EOF

git init -q && g add -A && g commit -qm "units 0.3.0"
git rev-parse HEAD > "$META/head"

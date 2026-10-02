#!/bin/sh
# A small invoice service with four planted structure findings and one bait:
#   src/billing.js    legacyRounding: its last caller left with the v1 API      -> S (no caller)
#   src/http.js       get() only forwards to fetchJson()                        -> S (deletion)
#   src/store/        StoreFactory over one store, no test stand-in             -> S (two adapters)
#   src/routes/       the invoice-read rule written twice; export's copy is weaker -> severity (one rule, one owner)
#   src/pay.js        bait: an injected payment gateway with a test adapter, a real seam -> no S or T
set -eu
g() { git -c user.name=eval -c user.email=eval@example.invalid "$@"; }
mkdir -p src/store src/routes test

cat > package.json <<'EOF'
{
  "name": "invoices",
  "version": "1.4.0",
  "private": true,
  "type": "module",
  "scripts": { "start": "node src/server.js", "test": "node --test" }
}
EOF
printf '/plan\n/.worktrees\nnode_modules\n' > .gitignore
cat > README.md <<'EOF'
# invoices

A small invoice service. `npm start` serves it on port 8080; `npm test` runs the suite.

Roles: `admin` and `owner` may read invoices. `member` and `guest` may not.
EOF

cat > src/fetch-json.js <<'EOF'
export async function fetchJson(url, { retries = 2 } = {}) {
  let lastError;
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const res = await fetch(url);
      if (!res.ok) throw new Error(`HTTP ${res.status} for ${url}`);
      return await res.json();
    } catch (err) {
      lastError = err;
    }
  }
  throw lastError;
}
EOF
cat > src/http.js <<'EOF'
import { fetchJson } from './fetch-json.js';

export function get(url) {
  return fetchJson(url);
}
EOF
cat > src/rates.js <<'EOF'
import { get } from './http.js';

export async function exchangeRate(from, to) {
  const body = await get(`https://rates.example.invalid/v1/${from}/${to}`);
  return body.rate;
}
EOF
cat > src/billing.js <<'EOF'
export function calcTotal(items, { legacyRounding = false } = {}) {
  if (legacyRounding) {
    return items.reduce((sum, it) => sum + Math.round(it.qty * it.unitPrice), 0);
  }
  return Math.round(items.reduce((sum, it) => sum + it.qty * it.unitPrice, 0));
}
EOF
cat > src/store/memory-store.js <<'EOF'
export class MemoryStore {
  constructor() {
    this.rows = new Map();
  }
  get(id) {
    return this.rows.get(id) ?? null;
  }
  put(id, row) {
    this.rows.set(id, row);
  }
  all() {
    return [...this.rows.values()];
  }
}
EOF
cat > src/store/store-factory.js <<'EOF'
import { MemoryStore } from './memory-store.js';

export class StoreFactory {
  static create(kind = 'memory') {
    switch (kind) {
      case 'memory':
        return new MemoryStore();
      default:
        throw new Error(`unknown store kind: ${kind}`);
    }
  }
}
EOF
cat > src/db.js <<'EOF'
import { StoreFactory } from './store/store-factory.js';

export const store = StoreFactory.create();
EOF
cat > src/auth.js <<'EOF'
export function canReadInvoices(user) {
  return user.role === 'admin' || user.role === 'owner';
}
EOF
cat > src/session.js <<'EOF'
const sessions = new Map();

export function login(token, user) {
  sessions.set(token, user);
}

export function userForToken(token) {
  return sessions.get(token) ?? { role: 'guest' };
}
EOF
cat > src/routes/invoices.js <<'EOF'
import { store } from '../db.js';
import { calcTotal } from '../billing.js';
import { canReadInvoices } from '../auth.js';

export function listInvoices(user) {
  if (!canReadInvoices(user)) return { status: 403 };
  const body = store.all().map((inv) => ({ ...inv, total: calcTotal(inv.items) }));
  return { status: 200, body };
}
EOF
cat > src/stripe-gateway.js <<'EOF'
export const stripeGateway = {
  async charge({ amount, currency, reference }) {
    const res = await fetch('https://payments.example.invalid/v1/charges', {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${process.env.PAY_KEY}` },
      body: JSON.stringify({ amount, currency, reference }),
    });
    if (!res.ok) throw new Error(`charge failed: ${res.status}`);
    return res.json();
  },
};
EOF
cat > src/pay.js <<'EOF'
import { calcTotal } from './billing.js';
import { stripeGateway } from './stripe-gateway.js';

export async function chargeInvoice(invoice, gateway = stripeGateway) {
  const amount = calcTotal(invoice.items);
  const receipt = await gateway.charge({ amount, currency: 'INR', reference: invoice.id });
  return { paid: true, receiptId: receipt.id };
}
EOF
cat > src/server.js <<'EOF'
import http from 'node:http';
import { store } from './db.js';
import { userForToken } from './session.js';
import { listInvoices } from './routes/invoices.js';
import { chargeInvoice } from './pay.js';
import { exchangeRate } from './rates.js';

const send = (res, { status, body }) => {
  res.writeHead(status, { 'content-type': typeof body === 'string' ? 'text/csv' : 'application/json' });
  res.end(typeof body === 'string' ? body : JSON.stringify(body ?? {}));
};

http.createServer(async (req, res) => {
  const user = userForToken(req.headers.authorization?.replace(/^Bearer /, ''));
  const url = new URL(req.url, 'http://localhost');
  if (url.pathname === '/invoices') return send(res, listInvoices(user));
  if (url.pathname === '/rate') {
    return send(res, { status: 200, body: { rate: await exchangeRate('USD', 'INR') } });
  }
  if (url.pathname === '/pay' && req.method === 'POST') {
    const invoice = store.get(url.searchParams.get('id'));
    if (!invoice) return send(res, { status: 404 });
    return send(res, { status: 200, body: await chargeInvoice(invoice) });
  }
  send(res, { status: 404 });
}).listen(8080);
EOF
cat > test/billing.test.js <<'EOF'
import test from 'node:test';
import assert from 'node:assert/strict';
import { calcTotal } from '../src/billing.js';

test('calcTotal rounds once, after summing', () => {
  assert.equal(calcTotal([{ qty: 3, unitPrice: 0.5 }, { qty: 1, unitPrice: 0.5 }]), 2);
});
EOF
cat > test/pay.test.js <<'EOF'
import test from 'node:test';
import assert from 'node:assert/strict';
import { chargeInvoice } from '../src/pay.js';

test('chargeInvoice charges the invoice total and returns the receipt id', async () => {
  const calls = [];
  const fakeGateway = { async charge(req) { calls.push(req); return { id: 'r_1' }; } };
  const result = await chargeInvoice({ id: 'inv-1', items: [{ qty: 2, unitPrice: 150 }] }, fakeGateway);
  assert.deepEqual(result, { paid: true, receiptId: 'r_1' });
  assert.deepEqual(calls, [{ amount: 300, currency: 'INR', reference: 'inv-1' }]);
});
EOF
git init -q && g add -A && g commit -qm "Invoice service"

# The v1 API was the last caller of legacyRounding; it left in the next commit.
cat > src/v1.js <<'EOF'
import { calcTotal } from './billing.js';

export function v1Total(invoice) {
  return calcTotal(invoice.items, { legacyRounding: true });
}
EOF
g add src/v1.js && g commit -qm "Serve v1 totals for old clients"
g rm -q src/v1.js && g commit -qm "Drop the v1 API"

# CSV export, with its own copy of the invoice-read rule.
cat > src/routes/export.js <<'EOF'
import { store } from '../db.js';

export function exportInvoicesCsv(user) {
  if (user.role === 'guest') return { status: 403 };
  const lines = store.all().map((inv) => `${inv.id},${inv.customer}`);
  return { status: 200, body: ['id,customer', ...lines].join('\n') };
}
EOF
awk '{ print }
  /^import \{ listInvoices \}/ { print "import { exportInvoicesCsv } from '"'"'./routes/export.js'"'"';" }
  /pathname === .\/invoices./ { print "  if (url.pathname === '"'"'/export.csv'"'"') return send(res, exportInvoicesCsv(user));" }' \
  src/server.js > src/server.js.new && mv src/server.js.new src/server.js
g add src/routes/export.js src/server.js && g commit -qm "Add CSV export"
git rev-parse HEAD > "$META/head"

#!/usr/bin/env node

/**
 * Generate a LiveKit JWT token for the mobile PoC.
 *
 * Usage:
 *   node scripts/generate-livekit-token.js
 *
 * Requires env vars (or .env file in repo root):
 *   LIVEKIT_API_KEY
 *   LIVEKIT_API_SECRET
 *
 * Outputs a token valid for 7 days with:
 *   - Room: "beacon"
 *   - Identity: "mobile-poc-<platform>-<random>"
 *   - canSubscribe: true
 *   - canPublish: false
 *
 * Copy the token into your PoC's .env file as LIVEKIT_TOKEN.
 */

const crypto = require('crypto');

// Load .env if present
try {
    require('dotenv').config();
} catch {
    // dotenv not installed — rely on env vars
}

const API_KEY = process.env.LIVEKIT_API_KEY;
const API_SECRET = process.env.LIVEKIT_API_SECRET;

if (!API_KEY || !API_SECRET) {
    console.error('Missing LIVEKIT_API_KEY or LIVEKIT_API_SECRET');
    console.error('Set them as env vars or in a .env file');
    process.exit(1);
}

const platform = process.argv[2] || 'test';

// JWT helpers (no external deps)
function base64url(str) {
    return Buffer.from(str)
        .toString('base64')
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=+$/, '');
}

function createJWT(payload, secret) {
    const header = { alg: 'HS256', typ: 'JWT' };
    const segments = [
        base64url(JSON.stringify(header)),
        base64url(JSON.stringify(payload)),
    ];
    const signingInput = segments.join('.');
    const signature = crypto
        .createHmac('sha256', secret)
        .update(signingInput)
        .digest('base64')
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=+$/, '');
    return `${signingInput}.${signature}`;
}

const now = Math.floor(Date.now() / 1000);
const identity = `mobile-poc-${platform}-${crypto.randomBytes(3).toString('hex')}`;

const payload = {
    iss: API_KEY,
    sub: identity,
    iat: now,
    nbf: now,
    exp: now + 7 * 24 * 60 * 60, // 7 days
    jti: identity,
    video: {
        room: 'beacon',
        roomJoin: true,
        canSubscribe: true,
        canPublish: false,
        canPublishData: false,
    },
};

const token = createJWT(payload, API_SECRET);

console.log(`\nLiveKit Token Generated`);
console.log(`=======================`);
console.log(`Identity:  ${identity}`);
console.log(`Room:      beacon`);
console.log(`Expires:   ${new Date((now + 7 * 24 * 3600) * 1000).toISOString()}`);
console.log(`Subscribe: true`);
console.log(`Publish:   false`);
console.log(`\nToken:\n`);
console.log(token);
console.log(`\nAdd to your .env:`);
console.log(`LIVEKIT_TOKEN=${token}`);
console.log();

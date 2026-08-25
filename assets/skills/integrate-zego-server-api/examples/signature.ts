/**
 * ZEGO Server API Signature Generation
 */

import crypto from 'crypto';

// Signature = md5(AppId + SignatureNonce + ServerSecret + Timestamp)
export function generateSignature(
  appId: number,
  signatureNonce: string,
  serverSecret: string,
  timestamp: number
): string {
  const hash = crypto.createHash('md5');
  const data = `${appId}${signatureNonce}${serverSecret}${timestamp}`;
  hash.update(data);
  return hash.digest('hex');
}

// Generate a 16-character hex string (8 bytes)
export function generateSignatureNonce(): string {
  return crypto.randomBytes(8).toString('hex');
}

// Example usage
/*
const appId = 12345;
const serverSecret = 'your_server_secret';
const timestamp = Math.floor(Date.now() / 1000);
const nonce = generateSignatureNonce();
const signature = generateSignature(appId, nonce, serverSecret, timestamp);
console.log('Signature:', signature);
*/

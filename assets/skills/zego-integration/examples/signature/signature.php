<?php

/**
 * ZEGO Server API Signature Generation
 */

// Signature = md5(AppId + SignatureNonce + ServerSecret + Timestamp)
function generateSignature(int $appId, string $signatureNonce, string $serverSecret, int $timestamp): string {
    $str = $appId . $signatureNonce . $serverSecret . $timestamp;
    return md5($str);
}

// Generate a 16-character hex string (8 bytes)
function generateSignatureNonce(): string {
    return bin2hex(random_bytes(8));
}

// Example usage
/*
$appId = 12345;
$serverSecret = 'your_server_secret';
$timestamp = time();
$nonce = generateSignatureNonce();
$signature = generateSignature($appId, $nonce, $serverSecret, $timestamp);
echo "Signature: $signature\n";
*/

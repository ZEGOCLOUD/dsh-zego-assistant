package com.zego.util;

import java.security.MessageDigest;
import java.security.SecureRandom;

public class ZegoSignature {

    // Signature = md5(AppId + SignatureNonce + ServerSecret + Timestamp)
    public static String generateSignature(long appId, String signatureNonce, String serverSecret, long timestamp) {
        String str = String.valueOf(appId) + signatureNonce + serverSecret + String.valueOf(timestamp);
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] bytes = md.digest(str.getBytes("utf-8"));
            return bytesToHex(bytes);
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate signature", e);
        }
    }

    // Generate a 16-character hex string (8 bytes)
    public static String generateSignatureNonce() {
        byte[] bytes = new byte[8];
        new SecureRandom().nextBytes(bytes);
        return bytesToHex(bytes);
    }

    private static String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            int digital = b & 0xFF;
            if (digital < 16) {
                sb.append("0");
            }
            sb.append(Integer.toHexString(digital));
        }
        return sb.toString();
    }
}

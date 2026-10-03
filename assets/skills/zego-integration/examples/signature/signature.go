package zego

import (
	"crypto/md5"
	"crypto/rand"
	"encoding/hex"
	"fmt"
)

// Signature = md5(AppId + SignatureNonce + ServerSecret + Timestamp)
func GenerateSignature(appId uint32, signatureNonce string, serverSecret string, timestamp int64) string {
	data := fmt.Sprintf("%d%s%s%d", appId, signatureNonce, serverSecret, timestamp)
	h := md5.New()
	h.Write([]byte(data))
	return hex.EncodeToString(h.Sum(nil))
}

// GenerateSignatureNonce generates a 16-character hex string (8 bytes)
func GenerateSignatureNonce() (string, error) {
	nonceByte := make([]byte, 8)
	if _, err := rand.Read(nonceByte); err != nil {
		return "", err
	}
	return hex.EncodeToString(nonceByte), nil
}

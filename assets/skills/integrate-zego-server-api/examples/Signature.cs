using System;
using System.Security.Cryptography;
using System.Text;

namespace Zego.Util
{
    public static class ZegoSignature
    {
        // Signature = md5(AppId + SignatureNonce + ServerSecret + Timestamp)
        public static string GenerateSignature(uint appId, string signatureNonce, string serverSecret, long timestamp)
        {
            string str = $"{appId}{signatureNonce}{serverSecret}{timestamp}";
            using (MD5 md5 = MD5.Create())
            {
                byte[] hash = md5.ComputeHash(Encoding.UTF8.GetBytes(str));
                return BytesToHex(hash);
            }
        }

        // Generate a 16-character hex string (8 bytes)
        public static string GenerateSignatureNonce()
        {
            byte[] bytes = new byte[8];
            using (RandomNumberGenerator rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(bytes);
            }
            return BytesToHex(bytes);
        }

        private static string BytesToHex(byte[] bytes)
        {
            StringBuilder sb = new StringBuilder();
            foreach (byte b in bytes)
            {
                sb.Append(b.ToString("x2"));
            }
            return sb.ToString();
        }
    }
}

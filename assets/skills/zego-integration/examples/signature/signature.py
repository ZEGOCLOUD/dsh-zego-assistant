"""ZEGO Server API Signature Generation"""

import secrets
import hashlib
import time


# Signature = md5(AppId + SignatureNonce + ServerSecret + Timestamp)
def generate_signature(app_id: int, signature_nonce: str, server_secret: str, timestamp: int) -> str:
    """Generate ZEGO API signature"""
    data = f"{app_id}{signature_nonce}{server_secret}{timestamp}"
    return hashlib.md5(data.encode("utf-8")).hexdigest()


def generate_signature_nonce() -> str:
    """Generate a 16-character hex string (8 bytes)"""
    return secrets.token_hex(8)


def main():
    # Example usage
    app_id = 12345
    server_secret = "your_server_secret"
    timestamp = int(time.time())
    nonce = generate_signature_nonce()
    signature = generate_signature(app_id, nonce, server_secret, timestamp)
    print(f"Signature: {signature}")


if __name__ == "__main__":
    main()

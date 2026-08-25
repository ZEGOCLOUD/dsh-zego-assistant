# ZEGO API Signature Mechanism

## Overview

All ZEGO server API requests require signature authentication for security.

## Signature Algorithm

```
Signature = md5(AppId + SignatureNonce + ServerSecret + Timestamp)
```

## Parameters

| Parameter         | Description                                                            |
|-------------------|------------------------------------------------------------------------|
| AppId             | Application ID from [ZEGO Console](https://console.zego.im/)          |
| SignatureNonce    | 16-character hex string (8 bytes random)                               |
| ServerSecret      | Application secret from console (keep confidential!)                   |
| Timestamp         | Current Unix timestamp in seconds (10-minute tolerance)                |

## Important Notes

- **Generate fresh signature for each request** - Signatures expire in 10 minutes
- **Keep parameters consistent** - Use the same SignatureNonce and Timestamp in both signature generation and API request
- **Protect ServerSecret** - Never expose on client side or commit to version control

## Signature Error Codes

| Code        | Description                | Action                                   |
|-------------|----------------------------|------------------------------------------|
| 0           | Success                    | -                                        |
| 100000004   | Signature expired          | Regenerate with new timestamp            |
| 100000005   | Signature invalid          | Verify parameters and algorithm          |

## Code Examples

See `examples/` directory for complete implementation:
- `signature.go` - Go
- `signature.py` - Python
- `Signature.java` - Java
- `signature.ts` - TypeScript/Node.js
- `signature.php` - PHP
- `Signature.cs` - C#

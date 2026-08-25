# Token Generation API Specification

This document describes the specification for the Token generation endpoint that must be implemented on the server.

## Endpoint Definition

```
GET /api/zego/token
```

## Request Parameters

### Query Parameters

| Parameter      | Type    | Required | Default | Description                                   |
|----------------|---------|----------|---------|-----------------------------------------------|
| userId         | string  | Yes      | -       | Unique user identifier                        |
| effectiveTime  | integer | No       | 3600    | Token validity period in seconds              |
| payload        | string  | No       | ""      | Additional permission payload (JSON string)   |

### Parameter Details

**userId** (required)
- Unique identifier for the user
- Must match the userId used when initializing the ZEGO SDK on the client
- Example: `user_12345`

**effectiveTime** (optional)
- Token validity duration in seconds
- Minimum: 60 seconds (1 minute)
- Maximum: 86400 seconds (24 hours)
- Default: 3600 seconds (1 hour) - recommended
- Example: `7200` (2 hours)

**payload** (optional)
- JSON string containing additional permission data
- Used for advanced permission control (e.g., room-specific permissions)
- Must be URL-encoded when passed as query parameter
- Example (encoded): `%7B%22room_id%22%3A%22123%22%7D`
- Example (decoded): `{"room_id": "123"}`

## Environment Variables

The endpoint requires the following environment variables:

```bash
# ZEGO AppID from console (32-bit unsigned integer)
ZEGO_APP_ID=1234567890

# ZEGO Server Secret from console (string)
ZEGO_SERVER_SECRET=your_server_secret_here
```

### Getting AppID and Server Secret

1. Log in to [ZEGO Console](https://console.zego.im) or [ZEGOCLOUD Console](https://console.zegocloud.com) for english users
2. Create or select a project
3. Navigate to "Project Information" or "Config"
4. Copy the AppID and Server Secret

## Response

### Success Response

**HTTP Status**: `200 OK`

**Content-Type**: `text/plain`

**Body**: The generated Token string

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Error Responses

**Missing Required Parameter**

**HTTP Status**: `400 Bad Request`

**Body**:
```json
{
  "error": "Missing required parameter: userId"
}
```

**Token Generation Failed**

**HTTP Status**: `500 Internal Server Error`

**Body**:
```json
{
  "error": "Failed to generate token: <error details>"
}
```

## Client Usage Example

### Fetching Token from Client

```javascript
// Client-side JavaScript (do NOT include secret here)
async function getToken(userId) {
  const response = await fetch(`/api/zego/token?userId=${encodeURIComponent(userId)}`);
  if (response.ok) {
    const token = await response.text();
    return token;
  }
  throw new Error('Failed to get token');
}

// Use with ZEGO SDK
const token = await getToken('user_123');
const zg = new ZegoExpressEngine(appID, server);
zg.loginRoom(roomID, token, { userID: userID, userName: userName }, { userUpdate: true }).then(result => {
     if (result == true) {
        console.log("login success")
     }
});
```

## Security Considerations

1. **Server-Side Only**: Token generation MUST happen on the server. Never expose Server Secret on the client side.

2. **HTTPS**: Always use HTTPS in production to protect tokens in transit.

3. **Token Caching**: Consider caching tokens on the client side until they expire to reduce server load.

4. **Rate Limiting**: Implement rate limiting on the endpoint to prevent abuse.

5. **User Validation**: Validate that the userId is legitimate before generating a token.

## Framework-Specific Notes

### Express.js (Node.js/TypeScript)

```typescript
app.get('/api/zego/token', async (req, res) => {
  const { userId, effectiveTime, payload } = req.query;
  // Implementation...
});
```

### Flask (Python)

```python
@app.route('/api/zego/token', methods=['GET'])
def get_token():
    user_id = request.args.get('userId')
    effective_time = request.args.get('effectiveTime', 3600, type=int)
    payload = request.args.get('payload', '')
    # Implementation...
```

### Gin (Go)

```go
r.GET("/api/zego/token", func(c *gin.Context) {
    userId := c.Query("userId")
    effectiveTime := c.DefaultQuery("effectiveTime", "3600")
    payload := c.DefaultQuery("payload", "")
    // Implementation...
})
```

### Spring Boot (Java)

```java
@GetMapping("/api/zego/token")
public ResponseEntity<String> getToken(
    @RequestParam String userId,
    @RequestParam(defaultValue = "3600") int effectiveTime,
    @RequestParam(defaultValue = "") String payload
) {
    // Implementation...
}
```

### ASP.NET Core (C#)

```csharp
[HttpGet("/api/zego/token")]
public IActionResult GetToken(
    [FromQuery] string userId,
    [FromQuery] int effectiveTime = 3600,
    [FromQuery] string payload = ""
) {
    // Implementation...
}
```

## Testing the Endpoint

### cURL

```bash
# Basic request
curl "http://localhost:3000/api/zego/token?userId=test_user"

# With custom effective time
curl "http://localhost:3000/api/zego/token?userId=test_user&effectiveTime=7200"

# With payload (URL-encoded)
curl "http://localhost:3000/api/zego/token?userId=test_user&payload=%7B%22room_id%22%3A%22123%22%7D"
```

# ZEGO Server API Structure

## Request Format

All ZEGO server APIs follow a unified request structure.

### URL Format

```
https://<API-Host>/?Action=<ActionName>&<PublicParams>&<BusinessParams>
```

### Public Parameters (Required)

| Parameter          | Type   | Description                                   |
|--------------------|--------|-----------------------------------------------|
| AppId              | uint32 | Application ID                                |
| SignatureNonce     | string | 16-char hex random string                     |
| Timestamp          | uint64 | Unix timestamp in seconds                     |
| Signature          | string | MD5 signature (32-char hex)                   |
| SignatureVersion   | string | Fixed value: "2.0"                            |

### Request Example

```
GET https://rtc-api.zego.im/?Action=StartMixing
&AppId=1234567890
&SignatureNonce=1a2b3c4d5e6f7g8h
&Timestamp=1735689600
&Signature=7a2c0f11145fb760d607a07b54825013
&SignatureVersion=2.0
&RoomId=room123
&TaskId=task456
```

## Response Format

All API responses return JSON with unified structure:

| Field      | Type   | Description                       |
|------------|--------|-----------------------------------|
| Code       | number | Error code (0 = success)          |
| Message    | string | Result description                |
| RequestId  | string | Request ID for tracing            |
| Data       | object | Response data (action-specific)   |

### Response Example

```json
{
    "Code": 0,
    "Message": "Succeed",
    "RequestId": "1843985617336143872",
    "Data": {
        "RoomId": "room123"
    }
}
```

## ID Parameter Rules

| ID Type    | Allowed Characters                          | Max Length |
|------------|---------------------------------------------|------------|
| UserId     | a-z, A-Z, 0-9, -, _                         | 32 bytes   |
| RoomId     | a-z, A-Z, 0-9, -, _                         | 128 bytes  |
| StreamId   | a-z, A-Z, 0-9, -, _                         | 128 bytes  |
| AgentId    | a-z, A-Z, 0-9, and !#$%&()+-:;<=>?@[]^_{|}~  | 128 bytes  |

## API Endpoints by Product

| Product  | API Host                          |
|----------|-----------------------------------|
| RTC      | rtc-api.zego.im                   |
| ZIM      | zim-api.zego.im                   |
| AI Agent | aigc-aiagent-api.zegotech.cn      |

> Note: Actual hosts may vary by region. Check product documentation for details.

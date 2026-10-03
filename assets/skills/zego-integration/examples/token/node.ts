/**
 * ZEGO Token Endpoint Implementation for Node.js/TypeScript
 *
 * This example shows how to implement the Token generation endpoint
 * using Express.js and the ZEGO Server Assistant SDK.
 *
 * Prerequisites:
 * 1. Download the SDK: python scripts/download_sdk.py --language NODEJS
 * 2. Save to: zego/token/zegoServerAssistant.ts
 * 3. Set environment variables: ZEGO_APP_ID, ZEGO_SERVER_SECRET
 */

import express, { Request, Response } from 'express';
import { ZegoServerAssistant } from '../zego/token/zegoServerAssistant';

// Initialize Express
const app = express();
const PORT = process.env.PORT || 3000;

// Read environment variables
const APP_ID = Number(process.env.ZEGO_APP_ID);
const SERVER_SECRET = process.env.ZEGO_SERVER_SECRET;

if (!APP_ID || !SERVER_SECRET) {
  throw new Error('Missing required environment variables: ZEGO_APP_ID, ZEGO_SERVER_SECRET');
}

/**
 * GET /api/zego/token
 *
 * Query parameters:
 * - userId: string (required) - User unique identifier
 * - effectiveTime: number (optional) - Token validity in seconds, default 3600
 * - payload: string (optional) - Permission payload (JSON string), default ""
 */
app.get('/api/zego/token', async (req: Request, res: Response) => {
  try {
    const { userId, effectiveTime, payload } = req.query;

    // Validate required parameter
    if (!userId || typeof userId !== 'string') {
      return res.status(400).json({ error: 'Missing required parameter: userId' });
    }

    // Parse effectiveTime (default: 3600 seconds = 1 hour)
    const effectiveTimeSeconds = effectiveTime ? Number(effectiveTime) : 3600;

    // Validate effectiveTime range
    if (effectiveTimeSeconds < 60 || effectiveTimeSeconds > 86400) {
      return res.status(400).json({
        error: 'effectiveTime must be between 60 and 86400 seconds'
      });
    }

    // Parse payload (default: empty string)
    const payloadStr = payload ? String(payload) : '';

    // Generate token using ZEGO SDK
    const token = ZegoServerAssistant.generateToken04(
      APP_ID,
      userId,
      SERVER_SECRET,
      effectiveTimeSeconds,
      payloadStr
    );

    // Return token as plain text
    res.status(200).type('text/plain').send(token);

  } catch (error) {
    console.error('Token generation failed:', error);
    res.status(500).json({
      error: `Failed to generate token: ${error instanceof Error ? error.message : 'Unknown error'}`
    });
  }
});

// Health check endpoint (optional)
app.get('/health', (_req: Request, res: Response) => {
  res.status(200).json({ status: 'ok', appId: APP_ID });
});

// Start server
app.listen(PORT, () => {
  console.log(`Token server running on port ${PORT}`);
  console.log(`Token endpoint: http://localhost:${PORT}/api/zego/token`);
});

export default app;

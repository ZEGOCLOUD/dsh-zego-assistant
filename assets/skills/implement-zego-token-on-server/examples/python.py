"""
ZEGO Token Endpoint Implementation for Python

This example shows how to implement the Token generation endpoint
using Flask and the ZEGO Server Assistant SDK.

Prerequisites:
1. Download the SDK: python scripts/download_sdk.py --language PYTHON
2. Save to: zego/token/token04.py
3. Set environment variables: ZEGO_APP_ID, ZEGO_SERVER_SECRET
4. Install Flask: pip install flask python-dotenv
"""

import os
from flask import Flask, request, jsonify
from dotenv import load_dotenv

# Import the ZEGO SDK
# Adjust the import path based on where you saved the SDK
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'zego', 'token'))
from token04 import Token04Assistant

# Load environment variables
load_dotenv()

app = Flask(__name__)

# Read environment variables
APP_ID = int(os.environ.get('ZEGO_APP_ID', 0))
SERVER_SECRET = os.environ.get('ZEGO_SERVER_SECRET', '')

if not APP_ID or not SERVER_SECRET:
    raise ValueError('Missing required environment variables: ZEGO_APP_ID, ZEGO_SERVER_SECRET')


@app.route('/api/zego/token', methods=['GET'])
def get_token():
    """
    GET /api/zego/token

    Query parameters:
    - userId: string (required) - User unique identifier
    - effectiveTime: number (optional) - Token validity in seconds, default 3600
    - payload: string (optional) - Permission payload (JSON string), default ""
    """
    try:
        user_id = request.args.get('userId')
        effective_time = request.args.get('effectiveTime', 3600, type=int)
        payload = request.args.get('payload', '')

        # Validate required parameter
        if not user_id:
            return jsonify({'error': 'Missing required parameter: userId'}), 400

        # Validate effectiveTime range
        if effective_time < 60 or effective_time > 86400:
            return jsonify({
                'error': 'effectiveTime must be between 60 and 86400 seconds'
            }), 400

        # Generate token using ZEGO SDK
        token = Token04Assistant.generate_token04(
            app_id=APP_ID,
            user_id=user_id,
            secret=SERVER_SECRET,
            effective_time=effective_time,
            payload=payload
        )

        # Return token as plain text
        return token, 200, {'Content-Type': 'text/plain'}

    except Exception as e:
        return jsonify({
            'error': f'Failed to generate token: {str(e)}'
        }), 500


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'ok', 'app_id': APP_ID}), 200


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
    print(f'Token server running on port {port}')
    print(f'Token endpoint: http://localhost:{port}/api/zego/token')

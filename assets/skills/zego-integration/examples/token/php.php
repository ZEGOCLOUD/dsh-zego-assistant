<?php
/**
 * ZEGO Token Endpoint Implementation for PHP
 *
 * This example shows how to implement the Token generation endpoint
 * using the ZEGO Server Assistant SDK.
 *
 * Prerequisites:
 * 1. Download the SDK: python scripts/download_sdk.php --language PHP
 * 2. Save to: ZEGO/Token/ZegoServerAssistant.php
 * 3. Set environment variables: ZEGO_APP_ID, ZEGO_SERVER_SECRET
 */

require_once __DIR__ . '/../../ZEGO/Token/ZegoServerAssistant.php';

use ZEGO\ZegoServerAssistant;

// Read environment variables
$appId = (int) getenv('ZEGO_APP_ID');
$serverSecret = getenv('ZEGO_SERVER_SECRET');

if (!$appId || !$serverSecret) {
    http_response_code(500);
    echo json_encode(['error' => 'Missing required environment variables: ZEGO_APP_ID, ZEGO_SERVER_SECRET']);
    exit;
}

/**
 * GET /api/zego/token
 *
 * Query parameters:
 * - userId: string (required) - User unique identifier
 * - effectiveTime: int (optional) - Token validity in seconds, default 3600
 * - payload: string (optional) - Permission payload (JSON string), default ""
 */
function getToken(): void
{
    global $appId, $serverSecret;

    // Get query parameters
    $userId = $_GET['userId'] ?? '';
    $effectiveTime = isset($_GET['effectiveTime']) ? (int)$_GET['effectiveTime'] : 3600;
    $payload = $_GET['payload'] ?? '';

    // Validate required parameter
    if (empty($userId)) {
        http_response_code(400);
        header('Content-Type: application/json');
        echo json_encode(['error' => 'Missing required parameter: userId']);
        return;
    }

    // Validate effectiveTime range
    if ($effectiveTime < 60 || $effectiveTime > 86400) {
        http_response_code(400);
        header('Content-Type: application/json');
        echo json_encode(['error' => 'effectiveTime must be between 60 and 86400 seconds']);
        return;
    }

    try {
        // Generate token using ZEGO SDK
        $token = ZegoServerAssistant::generateToken04(
            $appId,
            $userId,
            $serverSecret,
            $effectiveTime,
            $payload
        );

        // Return token as plain text
        http_response_code(200);
        header('Content-Type: text/plain');
        echo $token;

    } catch (Exception $e) {
        http_response_code(500);
        header('Content-Type: application/json');
        echo json_encode(['error' => 'Failed to generate token: ' . $e->getMessage()]);
    }
}

/**
 * Health check endpoint
 */
function health(): void
{
    global $appId;
    http_response_code(200);
    header('Content-Type: application/json');
    echo json_encode(['status' => 'ok', 'appId' => $appId]);
}

// Simple routing
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

if ($path === '/api/zego/token' && $_SERVER['REQUEST_METHOD'] === 'GET') {
    getToken();
} elseif ($path === '/health' && $_SERVER['REQUEST_METHOD'] === 'GET') {
    health();
} else {
    http_response_code(404);
    header('Content-Type: application/json');
    echo json_encode(['error' => 'Not found']);
}

// Alternative: Using a framework like Slim or Laravel
/*
// Slim Framework example:
use Slim\Factory\AppFactory;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

$app = AppFactory::create();

$app->get('/api/zego/token', function (Request $request, Response $response) use ($appId, $serverSecret) {
    $params = $request->getQueryParams();
    $userId = $params['userId'] ?? '';
    $effectiveTime = (int)($params['effectiveTime'] ?? 3600);
    $payload = $params['payload'] ?? '';

    if (empty($userId)) {
        $response->getBody()->write(json_encode(['error' => 'Missing required parameter: userId']));
        return $response->withStatus(400)->withHeader('Content-Type', 'application/json');
    }

    $token = ZegoServerAssistant::generateToken04($appId, $userId, $serverSecret, $effectiveTime, $payload);

    $response->getBody()->write($token);
    return $response->withStatus(200)->withHeader('Content-Type', 'text/plain');
});

$app->run();
*/

// ZEGO Token Endpoint Implementation for C#
//
// This example shows how to implement the Token generation endpoint
// using ASP.NET Core and the ZEGO Server Assistant SDK.
//
// Prerequisites:
// 1. Download the SDK: python scripts/download_sdk.py --language CSHARP
// 2. Save to: Services/Zego/ZegoServerAssistant.cs
// 3. Set environment variables: ZEGO_APP_ID, ZEGO_SERVER_SECRET
// 4. Add to your Program.cs or startup configuration

using Microsoft.AspNetCore.Mvc;
using System;
using YourProject.Services.Zego; // Adjust namespace

namespace YourProject.Controllers
{
    [ApiController]
    [Route("api")]
    public class ZegoTokenController : ControllerBase
    {
        private readonly uint _appId;
        private readonly string _serverSecret;

        public ZegoTokenController()
        {
            // Read environment variables
            string appIdStr = Environment.GetEnvironmentVariable("ZEGO_APP_ID");
            _serverSecret = Environment.GetEnvironmentVariable("ZEGO_SERVER_SECRET");

            if (string.IsNullOrEmpty(appIdStr) || string.IsNullOrEmpty(_serverSecret))
            {
                throw new InvalidOperationException("Missing required environment variables: ZEGO_APP_ID, ZEGO_SERVER_SECRET");
            }

            if (!uint.TryParse(appIdStr, out _appId))
            {
                throw new InvalidOperationException("Invalid ZEGO_APP_ID format");
            }
        }

        /// <summary>
        /// GET /api/zego/token
        /// </summary>
        /// <param name="userId">User unique identifier (required)</param>
        /// <param name="effectiveTime">Token validity in seconds (optional, default 3600)</param>
        /// <param name="payload">Permission payload JSON string (optional, default empty)</param>
        /// <returns>Generated token as plain text</returns>
        [HttpGet("zego/token")]
        public IActionResult GetToken(
            [FromQuery] string userId,
            [FromQuery] int effectiveTime = 3600,
            [FromQuery] string payload = "")
        {
            // Validate required parameter
            if (string.IsNullOrEmpty(userId))
            {
                return BadRequest(new { error = "Missing required parameter: userId" });
            }

            // Validate effectiveTime range
            if (effectiveTime < 60 || effectiveTime > 86400)
            {
                return BadRequest(new { error = "effectiveTime must be between 60 and 86400 seconds" });
            }

            try
            {
                // Generate token using ZEGO SDK
                string token = ZegoServerAssistant.GenerateToken04(
                    _appId,
                    userId,
                    _serverSecret,
                    effectiveTime,
                    payload ?? ""
                );

                // Return token as plain text
                return Content(token, "text/plain");
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = $"Failed to generate token: {ex.Message}" });
            }
        }

        /// <summary>
        /// Health check endpoint
        /// </summary>
        [HttpGet("health")]
        public IActionResult Health()
        {
            return Ok(new { status = "ok", appId = _appId });
        }
    }
}

/*
 * Minimal API style (Program.cs for .NET 6+):
 *
 * var builder = WebApplication.CreateBuilder(args);
 * var app = builder.Build();
 *
 * // Read environment variables
 * var appId = uint.Parse(Environment.GetEnvironmentVariable("ZEGO_APP_ID"));
 * var serverSecret = Environment.GetEnvironmentVariable("ZEGO_SERVER_SECRET");
 *
 * app.MapGet("/api/zego/token", (string userId, int effectiveTime = 3600, string? payload = null) =>
 * {
 *     if (string.IsNullOrEmpty(userId))
 *     {
 *         return Results.BadRequest(new { error = "Missing required parameter: userId" });
 *     }
 *
 *     if (effectiveTime < 60 || effectiveTime > 86400)
 *     {
 *         return Results.BadRequest(new { error = "effectiveTime must be between 60 and 86400 seconds" });
 *     }
 *
 *     try
 *     {
 *         var token = ZegoServerAssistant.GenerateToken04(
 *             appId, userId, serverSecret, effectiveTime, payload ?? ""
 *         );
 *         return Results.Text(token, "text/plain");
 *     }
 *     catch (Exception ex)
 *     {
 *         return Results.StatusCode(500, new { error = $"Failed to generate token: {ex.Message}" });
 *     }
 * });
 *
 * app.MapGet("/health", () => new { status = "ok", appId });
 *
 * app.Run();
 */

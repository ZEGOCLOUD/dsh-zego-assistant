// ZEGO Token Endpoint Implementation for Go
//
// This example shows how to implement the Token generation endpoint
// using Gin framework and the ZEGO Server Assistant SDK.
//
// Prerequisites:
// 1. Download the SDK: python scripts/download_sdk.py --language GO
// 2. Save to: zego/token/token04.go
// 3. Set environment variables: ZEGO_APP_ID, ZEGO_SERVER_SECRET
// 4. Install Gin: go get -u github.com/gin-gonic/gin

package main

import (
	"fmt"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"your-project/zego/token" // Adjust import path
)

// TokenRequest represents the token generation request parameters
type TokenRequest struct {
	UserID        string `form:"userId" binding:"required"`
	EffectiveTime int    `form:"effectiveTime"`
	Payload       string `form:"payload"`
}

// ErrorResponse represents an error response
type ErrorResponse struct {
	Error string `json:"error"`
}

var (
	appID        uint32
	serverSecret string
)

func init() {
	// Read environment variables
	appIDStr := os.Getenv("ZEGO_APP_ID")
	serverSecret = os.Getenv("ZEGO_SERVER_SECRET")

	if appIDStr == "" || serverSecret == "" {
		panic("Missing required environment variables: ZEGO_APP_ID, ZEGO_SERVER_SECRET")
	}

	appIDUint, err := strconv.ParseUint(appIDStr, 10, 32)
	if err != nil {
		panic(fmt.Sprintf("Invalid ZEGO_APP_ID: %v", err))
	}
	appID = uint32(appIDUint)
}

// GetToken handles GET /api/zego/token
func GetToken(c *gin.Context) {
	var req TokenRequest

	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error: "Missing required parameter: userId",
		})
		return
	}

	// Set default effective time to 3600 seconds (1 hour)
	if req.EffectiveTime == 0 {
		req.EffectiveTime = 3600
	}

	// Validate effectiveTime range
	if req.EffectiveTime < 60 || req.EffectiveTime > 86400 {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error: "effectiveTime must be between 60 and 86400 seconds",
		})
		return
	}

	// Set default payload to empty string
	if req.Payload == "" {
		req.Payload = "{}"
	}

	// Generate token using ZEGO SDK
	token, err := token.GenerateToken04(
		appID,
		req.UserID,
		serverSecret,
		req.EffectiveTime,
		req.Payload,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error: fmt.Sprintf("Failed to generate token: %v", err),
		})
		return
	}

	// Return token as plain text
	c.Header("Content-Type", "text/plain")
	c.String(http.StatusOK, token)
}

// HealthCheck handles GET /health
func HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status": "ok",
		"appId":  appID,
	})
}

func main() {
	// Set Gin to release mode
	gin.SetMode(gin.ReleaseMode)

	r := gin.Default()

	// Token endpoint
	r.GET("/api/zego/token", GetToken)

	// Health check endpoint
	r.GET("/health", HealthCheck)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	fmt.Printf("Token server running on port %s\n", port)
	fmt.Printf("Token endpoint: http://localhost:%s/api/zego/token\n", port)

	r.Run(":" + port)
}

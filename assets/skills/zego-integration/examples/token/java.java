/**
 * ZEGO Token Endpoint Implementation for Java
 *
 * This example shows how to implement the Token generation endpoint
 * using Spring Boot and the ZEGO Server Assistant SDK.
 *
 * Prerequisites:
 * 1. Download the SDK: python scripts/download_sdk.py --language JAVA
 * 2. Save to: src/main/java/im/zego/serverassistant/utils/TokenServerAssistant.java
 * 3. Set environment variables: ZEGO_APP_ID, ZEGO_SERVER_SECRET
 */

package com.example.zego.controller;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import im.zego.serverassistant.utils.TokenServerAssistant;

/**
 * Spring Boot Application for ZEGO Token Generation
 */
@SpringBootApplication
@RestController
public class ZegoTokenController {

    // Read environment variables
    private static final long APP_ID = Long.parseLong(System.getenv("ZEGO_APP_ID"));
    private static final String SERVER_SECRET = System.getenv("ZEGO_SERVER_SECRET");

    static {
        if (APP_ID == 0 || SERVER_SECRET == null || SERVER_SECRET.isEmpty()) {
            throw new IllegalStateException("Missing required environment variables: ZEGO_APP_ID, ZEGO_SERVER_SECRET");
        }
    }

    /**
     * GET /api/zego/token
     *
     * Query parameters:
     * - userId: String (required) - User unique identifier
     * - effectiveTime: Integer (optional) - Token validity in seconds, default 3600
     * - payload: String (optional) - Permission payload (JSON string), default ""
     *
     * @param userId User identifier
     * @param effectiveTime Token validity period in seconds
     * @param payload Additional permission payload
     * @return Generated token as plain text
     */
    @GetMapping("/api/zego/token")
    public Object getToken(
            @RequestParam(name = "userId") String userId,
            @RequestParam(name = "effectiveTime", required = false, defaultValue = "3600") Integer effectiveTime,
            @RequestParam(name = "payload", required = false, defaultValue = "") String payload) {

        // Validate required parameter
        if (userId == null || userId.trim().isEmpty()) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Missing required parameter: userId");
            return error;
        }

        // Validate effectiveTime range
        if (effectiveTime < 60 || effectiveTime > 86400) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "effectiveTime must be between 60 and 86400 seconds");
            return error;
        }

        try {
            // Generate token using ZEGO SDK
            String token = TokenServerAssistant.generateToken04(
                    APP_ID,
                    userId,
                    SERVER_SECRET,
                    effectiveTime,
                    payload
            );

            // Return token as plain text
            return token;

        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Failed to generate token: " + e.getMessage());
            return error;
        }
    }

    /**
     * Health check endpoint
     */
    @GetMapping("/health")
    public Map<String, Object> health() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "ok");
        response.put("appId", APP_ID);
        return response;
    }

    /**
     * CORS configuration
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(Arrays.asList("*"));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        configuration.setAllowCredentials(false);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    public static void main(String[] args) {
        SpringApplication.run(ZegoTokenController.class, args);
    }
}

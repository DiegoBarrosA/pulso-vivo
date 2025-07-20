package cl.duoc.pulsovivo.bff.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;

@Component
public class AzureB2CJwtValidator implements OAuth2TokenValidator<Jwt> {

    @Value("${azure.b2c.audience}")
    private String expectedAudience;

    @Value("${azure.b2c.issuer-uri}")
    private String expectedIssuer;

    @Override
    public OAuth2TokenValidatorResult validate(Jwt jwt) {
        // Validate issuer
        if (!expectedIssuer.equals(jwt.getIssuer().toString())) {
            return OAuth2TokenValidatorResult.failure(
                new OAuth2Error("invalid_issuer", "The required issuer is missing", null)
            );
        }

        // Validate audience
        List<String> audiences = jwt.getAudience();
        if (audiences == null || !audiences.contains(expectedAudience)) {
            return OAuth2TokenValidatorResult.failure(
                new OAuth2Error("invalid_audience", "The required audience is missing", null)
            );
        }

        // Validate expiration
        Instant expiresAt = jwt.getExpiresAt();
        if (expiresAt != null && expiresAt.isBefore(Instant.now())) {
            return OAuth2TokenValidatorResult.failure(
                new OAuth2Error("invalid_token", "Token has expired", null)
            );
        }

        // Validate not before
        Instant notBefore = jwt.getNotBefore();
        if (notBefore != null && notBefore.isAfter(Instant.now())) {
            return OAuth2TokenValidatorResult.failure(
                new OAuth2Error("invalid_token", "Token used before valid", null)
            );
        }

        return OAuth2TokenValidatorResult.success();
    }
}
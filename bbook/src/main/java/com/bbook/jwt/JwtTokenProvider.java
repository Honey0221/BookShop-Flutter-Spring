package com.bbook.jwt;

import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

import javax.crypto.SecretKey;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.stereotype.Component;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

@Component
public class JwtTokenProvider {
  @Value("${jwt.secret}")
  private String jwtSecret;

  private final UserDetailsService userDetailsService;

  public JwtTokenProvider(UserDetailsService userDetailsService) {
    this.userDetailsService = userDetailsService;
  }

  public String generateToken(String email) {
    Date now = new Date();
    Date expiryDate = new Date(now.getTime() + 30 * 60 * 1000);

    return Jwts.builder()
      .subject(email)
      .issuedAt(now)
      .expiration(expiryDate)
      .signWith(getSigningKey())
      .compact();
  }

  public String getEmailFromToken(String token) {
    return getClaimFromToken(token, Claims::getSubject);
  }

  public boolean validateToken(String token) {
    try {
      Jwts.parser()
        .verifyWith(getSigningKey())
        .build()
        .parseSignedClaims(token);
      return true;
    } catch (JwtException | IllegalArgumentException e) {
      return false;
    }
  }

  public Authentication getAuthentication(String token) {
    UserDetails userDetails = userDetailsService.loadUserByUsername(getEmailFromToken(token));
    return new UsernamePasswordAuthenticationToken(userDetails, "", userDetails.getAuthorities());
  }

  private <T> T getClaimFromToken(String token, Function<Claims, T> claimsResolver) {
    Claims claims = Jwts.parser()
      .verifyWith(getSigningKey())
      .build()
      .parseSignedClaims(token)
      .getPayload();
    return claimsResolver.apply(claims);
  }

  private SecretKey getSigningKey() {
    byte[] keyBytes = jwtSecret.getBytes(StandardCharsets.UTF_8);
    return Keys.hmacShaKeyFor(keyBytes);
  }

  public String generateEmailVerificationToken(String email, String code) {
    Date now = new Date();
    Date expiryDate = new Date(now.getTime() + JwtConstants.EXPIRE_TIME);

    return Jwts.builder()
      .subject("email-verification")
      .claim("email", email)
      .claim("code", code)
      .issuedAt(now)
      .expiration(expiryDate)
      .signWith(getSigningKey())
      .compact();
  }

  public Map<String, String> getEmailVerificationInfo(String token) {
    Claims claims = Jwts.parser()
      .verifyWith(getSigningKey())
      .build()
      .parseSignedClaims(token)
      .getPayload();

    Map<String, String> verificationInfo = new HashMap<>();
    verificationInfo.put("email", claims.get("email", String.class));
    verificationInfo.put("code", claims.get("code", String.class));

    return verificationInfo;
  }

  public String generateSocialToken(String email, boolean isNewUser) {
    Map<String, Object> claims = new HashMap<>();
    claims.put("sub", email);
    claims.put("isNewUser", isNewUser);

    Date now = new Date();
    Date validity = new Date(now.getTime() + JwtConstants.EXPIRE_TIME);

    return Jwts.builder()
      .claims(claims)
      .issuedAt(now)
      .expiration(validity)
      .signWith(getSigningKey())
      .compact();
  }

  public boolean isNewUser(String token) {
    Claims claims = Jwts.parser()
      .verifyWith(getSigningKey())
      .build()
      .parseSignedClaims(token)
      .getPayload();

    return claims.get("isNewUser", Boolean.class);
  }
}

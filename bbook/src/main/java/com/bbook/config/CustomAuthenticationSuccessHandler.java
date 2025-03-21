package com.bbook.config;

import com.bbook.jwt.JwtTokenProvider;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import org.springframework.security.core.Authentication;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriComponentsBuilder;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import java.io.IOException;
import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class CustomAuthenticationSuccessHandler implements AuthenticationSuccessHandler {
  private final JwtTokenProvider jwtTokenProvider;
  private static final String REDIRECT_URI = "http://localhost/oauth/callback";

  @Override
  public void onAuthenticationSuccess(HttpServletRequest request,
      HttpServletResponse response,
      Authentication authentication) throws IOException, ServletException {
    log.info("OAuth2 로그인 성공");

    try {
      MemberDetails memberDetails = (MemberDetails) authentication.getPrincipal();
      String email = memberDetails.getUsername();

      Map<String, Object> attributes = memberDetails.getAttributes();
      boolean isNewUser = false;

      if (attributes.containsKey("isNewUser")) {
        isNewUser = (boolean) attributes.get("isNewUser");
      }

      String token = jwtTokenProvider.generateSocialToken(email, isNewUser);

      String targetUrl = buildRedirectUrl(token, isNewUser, email);

      response.sendRedirect(targetUrl);
    } catch (Exception e) {
      log.error("Authentication success handling failed", e);
      response.sendRedirect("/");
    }
  }

  // 프론트엔드로 리다이렉트할 URL 생성 메서드
  private String buildRedirectUrl(String token, boolean isNewUser, String email) {
    // 모바일 앱 환경의 경우 Mobile Deep Link URL로 리다이렉트 (예: myapp://oauth/callback)
    // 웹 환경의 경우 웹 URL로 리다이렉트
    
    // 웹 환경 예시
    return UriComponentsBuilder.fromUriString(REDIRECT_URI)
            .queryParam("token", token)
            .queryParam("isNewUser", isNewUser)
            .queryParam("email", email)
            .build().toUriString();
  }
}
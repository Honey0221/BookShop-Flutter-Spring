package com.bbook.jwt;

public class JwtConstants {
  public static final String AUTH_LOGIN_URL = "/members/login";
  public static final String TOKEN_HEADER = "Authorization";
  public static final String TOKEN_PREFIX = "Bearer ";
  public static final String TOKEN_TYPE = "JWT";
  public static final int EXPIRE_TIME = 10 * 60 * 1000;
}

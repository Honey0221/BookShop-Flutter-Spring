package com.bbook.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebMvcConfig implements WebMvcConfigurer {
	@Value("${uploadItemPath}")
	String uploadItemPath;

	@Value("${uploadReviewPath}")
	String uploadReviewPath;

	@Override
	public void addResourceHandlers(ResourceHandlerRegistry registry) {
		// 책 이미지용 핸들러
		registry.addResourceHandler("/bookshop/book/**")
				.addResourceLocations(uploadItemPath);

		// 리뷰 이미지용 핸들러
		registry.addResourceHandler("/bookshop/review/**")
				.addResourceLocations(uploadReviewPath);
	}

	@Override
	public void addCorsMappings(CorsRegistry registry) {
		registry.addMapping("/**")
				.allowedOrigins("http://localhost:8080", "http://10.0.2.2:8080")
				.allowedMethods("GET", "POST", "PUT", "DELETE", "PATCH")
				.allowedHeaders("*")
				.allowCredentials(true)
				.maxAge(3600);
	}
}

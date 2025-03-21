package com.bbook.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.web.bind.annotation.*;

import com.bbook.service.MemberActivityService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/recommendation")
@RequiredArgsConstructor
public class RecommendationController {
  private final MemberActivityService memberActivityService;

  @GetMapping("/content-based")
  public Map<String, Object> getContentBasedRecommendations(
    @RequestParam(required = false) String email) {
    Map<String, Object> response = new HashMap<>();
    response.put("data", memberActivityService.getContentBasedRecommendations(email));
    return response;
  }

  @GetMapping("/collaborative")
  public Map<String, Object> getCollaborativeRecommendations(
    @RequestParam(required = false) String email) {
    Map<String, Object> response = new HashMap<>();
    response.put("data", memberActivityService.getCollaborativeRecommendations(email));
    return response;
  }

  @GetMapping("/hybrid")
  public Map<String, Object> getHybridRecommendations(
    @RequestParam(required = false) String email) {
    Map<String, Object> response = new HashMap<>();
    response.put("data", memberActivityService.getHybridRecommendations(email));
    return response;
  }

  @GetMapping("/personalized")
  public Map<String, Object> getPersonalizedRecommendations(
    @RequestParam(required = false) String email) {
    Map<String, Object> response = new HashMap<>();
    response.put("data", memberActivityService.getHybridRecommendations(email));
    return response;
  }
}
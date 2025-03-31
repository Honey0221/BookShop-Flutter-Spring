package com.bbook.controller;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.web.bind.annotation.*;

import com.bbook.service.BookListService;
import com.bbook.service.MemberActivityService;
import com.bbook.dto.BookListDto;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/recommendation")
@RequiredArgsConstructor
public class RecommendationController {
  private final MemberActivityService memberActivityService;
  private final BookListService bookListService;

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

  @GetMapping("/category-top")
  @ResponseBody
  public Map<String, Object> getTopBooksByCategory(
      @RequestParam String category,
      @RequestParam(defaultValue = "3") int limit) {
    try {
      List<BookListDto> books = bookListService.getTopBooksByCategory(category, limit);
      Map<String, Object> response = new HashMap<>();
      response.put("data", books);
      return response;
    } catch (Exception e) {
      e.printStackTrace();
      Map<String, Object> response = new HashMap<>();
      response.put("error", "카테고리별 추천 도서 조회 중 오류가 발생했습니다.");
      return response;
    }
  }
}
package com.bbook.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import com.bbook.dto.BookListDto;
import com.bbook.service.BookListService;

import lombok.RequiredArgsConstructor;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/book-list")
@RequiredArgsConstructor
public class BookListController {

  private final BookListService bookListService;

  // 도서 목록 페이지 (메인)
  @GetMapping
  public String bookList(
      @RequestParam(defaultValue = "10") int size,
      Model model) {
    List<BookListDto> latestBooks = bookListService.getInitialBooks(size);
    model.addAttribute("books", latestBooks);
    model.addAttribute("pageTitle", "전체 도서");
    return "books/bookList";
  }

  // 메스트셀러 도서 목록
  @GetMapping("/best")
  @ResponseBody
  public Map<String, Object> bestBooks(
      @RequestParam(defaultValue = "10") int size) {
    List<BookListDto> bestBooks = bookListService.getInitialBestBooks(size);
    Map<String, Object> response = new HashMap<>();
    response.put("data", bestBooks);
    response.put("size", size);
    return response;
  }

  // 신간 도서 목록
  @GetMapping("/new")
  @ResponseBody
  public Map<String, Object> newBooks(
      @RequestParam(defaultValue = "10") int size) {
    List<BookListDto> newBooks = bookListService.getInitialNewBooks(size);
    Map<String, Object> response = new HashMap<>();
    response.put("data", newBooks);
    response.put("size", size);
    return response;
  }

  // 카테고리별 도서 목록 (메인/중분류/상세 통합)
  @GetMapping("/category")
  @ResponseBody
  public Map<String, Object> booksByCategory(
      @RequestParam(required = false) String main,
      @RequestParam(required = false) String mid,
      @RequestParam(required = false) String detail,
      @RequestParam(required = false, defaultValue = "newest") String sort,
      @RequestParam(defaultValue = "10") int size) {
    try {
      List<BookListDto> books;
      Map<String, Object> response = new HashMap<>();

      if (detail != null) {
        // 상세 카테고리가 있는 경우
        books = bookListService.getInitialBooksByDetailCategory(main, mid, detail, size);
      } else if (mid != null) {
        // 중분류 카테고리만 있는 경우
          books = bookListService.getInitialBooksByCategory(main, mid, size);
      } else if (main != null) {
        // 메인 카테고리만 있는 경우
        books = bookListService.getInitialBooksByMainCategory(main, size);
      } else {
        // 카테고리가 없는 경우 전체 도서 목록
        books = bookListService.getInitialBooks(size);
      }
      // 현재 카테고리의 하위 카테고리 목록 추가
      if (main != null) {
        List<String> midCategories = bookListService.getMidCategories(main);
        response.put("midCategories", midCategories);

        if (mid != null) {
          List<String> detailCategories = bookListService.getDetailCategories(main, mid);
          response.put("detailCategories", detailCategories);
        }
      }

      return response;

    } catch (Exception e) {
      // 에러 로깅
      e.printStackTrace();
      Map<String, Object> response = new HashMap<>();
      response.put("error", "카테고리 조회 중 오류가 발생했습니다.");
      return response;
    }
  }

  // 무한 스크롤용 API 수정
  @GetMapping("/api/next")
  @ResponseBody
  public List<BookListDto> getNextBooks(
      @RequestParam Long lastId,
      @RequestParam(required = false) String category,
      @RequestParam(required = false) String main,
      @RequestParam(required = false) String mid,
      @RequestParam(required = false) String detail,
      @RequestParam(defaultValue = "10") int size) {

    if ("best".equals(category)) {
      return bookListService.getNextBestBooks(lastId, size);
    } else if ("new".equals(category)) {
      return bookListService.getNextNewBooks(lastId, size);
    } else if (detail != null) {
      return bookListService.getNextBooksByDetailCategory(lastId, main, mid, detail, size);
    } else if (mid != null) {
      return bookListService.getNextBooksByCategory(lastId, main, mid, size);
    } else {
      return bookListService.getNextBooksByMainCategory(lastId, main, size);
    }
  }

  // 도서 검색 기능
  @GetMapping("/search")
  @ResponseBody
  public Map<String, Object> searchBooks(
      @RequestParam String searchQuery,
      @RequestParam(defaultValue = "10") int size) {
    try {
      List<BookListDto> searchResults = bookListService.searchInitialBooks(searchQuery, size);
      Map<String, Object> response = new HashMap<>();
      response.put("data", searchResults);
      response.put("size", size);
      return response;

    } catch (Exception e) {
      e.printStackTrace();
      Map<String, Object> response = new HashMap<>();
      response.put("error", "검색 중 오류가 발생했습니다.");
      return response;
    }
  }

  // 검색 결과 무한 스크롤용 API 수정
  @GetMapping("/api/search/next")
  @ResponseBody
  public List<BookListDto> getNextSearchResults(
      @RequestParam Long lastId,
      @RequestParam String searchQuery,
      @RequestParam(required = false, defaultValue = "newest") String sort,
      @RequestParam(defaultValue = "10") int size) {

    List<BookListDto> nextResults = bookListService.getNextSearchResults(lastId, searchQuery, size);

    // 정렬 적용
    switch (sort) {
      case "price_asc":
        return bookListService.sortByPriceAsc(nextResults);
      case "price_desc":
        return bookListService.sortByPriceDesc(nextResults);
      case "popularity":
        return bookListService.sortByPopularity(nextResults);
      default: // newest
        return nextResults;
    }
  }
}
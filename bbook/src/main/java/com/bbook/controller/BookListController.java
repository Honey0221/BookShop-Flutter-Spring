package com.bbook.controller;

import org.springframework.stereotype.Controller;
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
  @ResponseBody
  public Map<String, Object> bookList(
      @RequestParam(defaultValue = "1") int page,
      @RequestParam(defaultValue = "10") int size,
      @RequestParam(required = false) String sort,
      @RequestParam(required = false) Integer minPrice,
      @RequestParam(required = false) Integer maxPrice,
      @RequestParam(required = false) List<String> categories) {

    // 전체 데이터를 가져옵니다
    List<BookListDto> allBooks = bookListService.getAllBooks(sort, minPrice, maxPrice, categories);
    
    // 페이지 계산
    int totalItems = allBooks.size();
    int totalPages = (int) Math.ceil((double) totalItems / size);
    
    // 요청된 페이지의 데이터만 추출
    int start = (page - 1) * size;
    int end = Math.min(start + size, totalItems);
    List<BookListDto> pageData = start < totalItems ? allBooks.subList(start, end) : List.of();
    
    Map<String, Object> response = new HashMap<>();
    response.put("data", pageData);
    response.put("totalPages", totalPages);
    response.put("currentPage", page);
    response.put("totalItems", totalItems);
    return response;
  }

  // 베스트 도서 목록
  @GetMapping("/best")
  @ResponseBody
  public Map<String, Object> bestBooks(
      @RequestParam(defaultValue = "1") int page,
      @RequestParam(defaultValue = "10") int size,
      @RequestParam(required = false) String sort,
      @RequestParam(required = false) Integer minPrice,
      @RequestParam(required = false) Integer maxPrice,
      @RequestParam(required = false) List<String> categories) {
    
    // 전체 베스트 도서 데이터를 가져옵니다
    List<BookListDto> allBooks = bookListService.getAllBestBooks(sort, minPrice, maxPrice, categories);
    
    // 페이지 계산
    int totalItems = allBooks.size();
    int totalPages = (int) Math.ceil((double) totalItems / size);
    
    // 요청된 페이지의 데이터만 추출
    int start = (page - 1) * size;
    int end = Math.min(start + size, totalItems);
    List<BookListDto> pageData = start < totalItems ? allBooks.subList(start, end) : List.of();
    
    Map<String, Object> response = new HashMap<>();
    response.put("data", pageData);
    response.put("totalPages", totalPages);
    response.put("currentPage", page);
    response.put("totalItems", totalItems);
    return response;
  }

  // 신규 도서 목록
  @GetMapping("/new")
  @ResponseBody
  public Map<String, Object> newBooks(
      @RequestParam(defaultValue = "1") int page,
      @RequestParam(defaultValue = "10") int size,
      @RequestParam(required = false) String sort,
      @RequestParam(required = false) Integer minPrice,
      @RequestParam(required = false) Integer maxPrice,
      @RequestParam(required = false) List<String> categories) {
    
    // 전체 신규 도서 데이터를 가져옵니다
    List<BookListDto> allBooks = bookListService.getAllNewBooks(sort, minPrice, maxPrice, categories);
    
    // 페이지 계산
    int totalItems = allBooks.size();
    int totalPages = (int) Math.ceil((double) totalItems / size);
    
    // 요청된 페이지의 데이터만 추출
    int start = (page - 1) * size;
    int end = Math.min(start + size, totalItems);
    List<BookListDto> pageData = start < totalItems ? allBooks.subList(start, end) : List.of();
    
    Map<String, Object> response = new HashMap<>();
    response.put("data", pageData);
    response.put("totalPages", totalPages);
    response.put("currentPage", page);
    response.put("totalItems", totalItems);
    return response;
  }

  // 카테고리별 도서 목록
  @GetMapping("/category")
  @ResponseBody
  public Map<String, Object> booksByCategory(
      @RequestParam(required = false) String main,
      @RequestParam(required = false) String mid,
      @RequestParam(required = false) String detail,
      @RequestParam(defaultValue = "1") int page,
      @RequestParam(defaultValue = "10") int size,
      @RequestParam(required = false) String sort,
      @RequestParam(required = false) Integer minPrice,
      @RequestParam(required = false) Integer maxPrice,
      @RequestParam(required = false) List<String> categories) {
    try {
      // 전체 카테고리별 도서 데이터를 가져옵니다
      List<BookListDto> allBooks = bookListService.getAllBooksByCategory(
          main, mid, detail, sort, minPrice, maxPrice, categories);
      
      // 페이지 계산
      int totalItems = allBooks.size();
      int totalPages = (int) Math.ceil((double) totalItems / size);
      
      // 요청된 페이지의 데이터만 추출
      int start = (page - 1) * size;
      int end = Math.min(start + size, totalItems);
      List<BookListDto> pageData = start < totalItems ? allBooks.subList(start, end) : List.of();
      
      Map<String, Object> response = new HashMap<>();
      response.put("data", pageData);
      response.put("totalPages", totalPages);
      response.put("currentPage", page);
      response.put("totalItems", totalItems);

      // 카테고리 정보 추가
      if (main != null) {
        response.put("midCategories", bookListService.getMidCategories(main));
        if (mid != null) {
          response.put("detailCategories", bookListService.getDetailCategories(main, mid));
        }
      }

      return response;
    } catch (Exception e) {
      e.printStackTrace();
      Map<String, Object> response = new HashMap<>();
      response.put("error", "카테고리 조회 중 오류가 발생했습니다.");
      return response;
    }
  }

  // 도서 검색 기능
  @GetMapping("/search")
  @ResponseBody
  public Map<String, Object> searchBooks(
      @RequestParam String searchQuery,
      @RequestParam(defaultValue = "1") int page,
      @RequestParam(defaultValue = "10") int size,
      @RequestParam(required = false) String sort,
      @RequestParam(required = false) Integer minPrice,
      @RequestParam(required = false) Integer maxPrice,
      @RequestParam(required = false) List<String> categories) {
    try {
      // 전체 검색 결과를 가져옵니다
      List<BookListDto> allBooks = bookListService.getAllSearchBooks(
          searchQuery, sort, minPrice, maxPrice, categories);
      
      // 페이지 계산
      int totalItems = allBooks.size();
      int totalPages = (int) Math.ceil((double) totalItems / size);
      
      // 요청된 페이지의 데이터만 추출
      int start = (page - 1) * size;
      int end = Math.min(start + size, totalItems);
      List<BookListDto> pageData = start < totalItems ? allBooks.subList(start, end) : List.of();
      
      Map<String, Object> response = new HashMap<>();
      response.put("data", pageData);
      response.put("totalPages", totalPages);
      response.put("currentPage", page);
      response.put("totalItems", totalItems);
      return response;
    } catch (Exception e) {
      e.printStackTrace();
      Map<String, Object> response = new HashMap<>();
      response.put("error", "검색 중 오류가 발생했습니다.");
      return response;
    }
  }
}
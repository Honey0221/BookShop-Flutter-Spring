package com.bbook.controller;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.bbook.constant.ActivityType;
import com.bbook.entity.Book;
import com.bbook.jwt.JwtTokenProvider;
import com.bbook.service.BookDetailService;
import com.bbook.service.MemberActivityService;

import lombok.RequiredArgsConstructor;

@Controller
@RequiredArgsConstructor
@RequestMapping(value = "/item")
public class BookController {
	private final BookDetailService bookDetailService;
	private final MemberActivityService memberActivityService;
	private final JwtTokenProvider jwtTokenProvider;

	@GetMapping
	@ResponseBody
	public Map<String, Object> getBook(
		@RequestParam(name = "bookId") Long id,
		@RequestHeader(name = "Authorization", required = false) String authHeader) {
		Map<String, Object> response = new HashMap<>();

		try {
			Book book = bookDetailService.getBookById(id);
			response.put("book", book);

			// 작가의 다른 책
			Set<Book> authorBooks = new HashSet<>(bookDetailService
					.getBooksByAuthor(book.getAuthor()).stream()
					.filter(b -> !b.getId().equals(book.getId())).toList());

			List<Book> randomBooks = new ArrayList<>(authorBooks);
			Collections.shuffle(randomBooks);
			randomBooks = randomBooks.stream().limit(4).toList();

			response.put("authorBooks", randomBooks);

			// 같은 카테고리 책
			Set<Book> categoryBooks = new HashSet<>(bookDetailService
					.getBooksByMidCategory(book.getMidCategory()).stream()
					.filter(b -> !b.getId().equals(book.getId())).toList());

			List<Book> randomCategoryBooks = new ArrayList<>(categoryBooks);
			Collections.shuffle(randomCategoryBooks);
			randomCategoryBooks = randomCategoryBooks.stream().limit(4).toList();

			response.put("categoryBooks", randomCategoryBooks);

			String email = null;

			if (authHeader != null && authHeader.startsWith("Bearer ")) {
				String token = authHeader.substring(7);
				email = jwtTokenProvider.getEmailFromToken(token);
			}

			if (email != null) {
				memberActivityService.saveActivity(email, book.getId(),
						ActivityType.VIEW);
				bookDetailService.incrementViewCount(book.getId());
			}

			return response;
		} catch (Exception e) {
			System.out.println("페이지 로드 중 오류 발생 : " + e.getMessage());
			return null;
		}
	}

	@GetMapping("/{bookId}/trailer")
	@ResponseBody
	public Map<String, String> getBookTrailer(@PathVariable Long bookId) {
		Book book = bookDetailService.getBookById(bookId);
		return Map.of("trailerUrl",
				book.getTrailerUrl() != null ? book.getTrailerUrl() : "");
	}
}

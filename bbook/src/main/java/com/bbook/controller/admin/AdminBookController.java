package com.bbook.controller.admin;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.multipart.MultipartFile;

import com.bbook.dto.BookFormDto;
import com.bbook.entity.Book;
import com.bbook.repository.AdminBookRepository;
import com.bbook.service.admin.AdminBookService;

import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;

@Controller
@RequiredArgsConstructor
@RequestMapping("/admin")
public class AdminBookController {
	private final AdminBookService adminBookService;
	private final AdminBookRepository adminBookRepository;

	@GetMapping("/bookMng")
	public String itemManage(@PageableDefault(size = 20, sort = "id",
			direction = Sort.Direction.DESC) Pageable pageable, Model model) {
		Page<Book> books = adminBookService.getAdminBookPage(pageable);
		model.addAttribute("books", books);

		return "/admin/books/bookMng";
	}

	// 도서 목록 조회
	@GetMapping("/items/list")
	@ResponseBody
	public Page<Book> getBookList(
			@RequestParam(required = false) String searchType,
			@RequestParam(required = false) String keyword,
			@RequestParam(required = false) String status,
			@RequestParam(defaultValue = "0") int page,
			@RequestParam(defaultValue = "10") int size,
			@RequestParam(defaultValue = "id,desc") String sort) {
		return adminBookService.getFilteredBooks(searchType, keyword, status,
				PageRequest.of(page, size, getSortFromString(sort)));
	}

	// 정렬 정보(id, desc)를 파싱
	private Sort getSortFromString(String sort) {
		String[] parts = sort.split(",");
		return Sort.by(parts[1].equals("desc") ?
				Sort.Direction.DESC : Sort.Direction.ASC, parts[0]);
	}

	// 엑셀로 받기
	@GetMapping("/items/excel-download")
	public ResponseEntity<Resource> downloadExcel(
			@RequestParam(required = false) String searchType,
			@RequestParam(required = false) String keyword,
			@RequestParam(required = false) String status,
			@RequestParam(defaultValue = "id,desc") String sort) {
		try {
			// 엑셀 파일 생성
			ByteArrayResource resource
					= adminBookService.generateExcel(searchType, keyword, status, sort);

			// 엑셀 파일명 정의
			String fileName = "BooksList_" + LocalDateTime.now().format(
					DateTimeFormatter.ofPattern("yyyyMMdd")) + ".xlsx";
			// UTF-8로 인코딩하여 URL에서 안전하게 사용할 수 있도록 처리
			// URLEncoder.encode()는 공백과 특수 문자를 URL 인코딩 형식으로 변환
			// 또한 인코딩된 "+" 문자를 "%20"으로 대체하여 공백이 깨지지 않도록 처리
			String encodedFileName = URLEncoder.encode(fileName, StandardCharsets.UTF_8)
					.replaceAll("\\+", "%20");

			return ResponseEntity.ok()
					// 엑셀 파일 형식을 MIME 타입 설정(.xlsx)
					.contentType(MediaType.parseMediaType(
							"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
					// 파일 크기 설정
					.contentLength(resource.contentLength())
					// 다운로드 파일명 설정
					// attachment : 파일을 다운로드로 처리하도록 지시
					// fileName* : UTF-8로 인코딩하여 설정
					.header(HttpHeaders.CONTENT_DISPOSITION,
							"attachment; fileName*=UTF-8''" + encodedFileName)
					// 캐시 관련 헤더 설정
					.header(HttpHeaders.CACHE_CONTROL,
							"no-cache, no-store, must-revalidate")
					// 브라우저가 파일을 캐시하지 않도록 설정 -> 보안 강화
					.header(HttpHeaders.PRAGMA, "no-cache")
					// 파일이 즉시 만료되도록 설정 -> 파일을 최신 상태로 유지
					.header(HttpHeaders.EXPIRES, "0")
					// 엑셀 파일 데이터 전송
					.body(resource);
		} catch (Exception e) {
			System.out.println("엑셀 파일 생성 중 오류 발생" + e.getMessage());
			return ResponseEntity.internalServerError().build();
		}
	}

	// 도서 추가
	@PostMapping("/items/new")
	@ResponseBody
	public ResponseEntity<Book> createBook(
			@RequestPart(value = "bookFormDto") BookFormDto bookFormDto,
			@RequestPart(value = "bookImage") MultipartFile bookImage) {
		try {
			System.out.println("받은 데이터 : " + bookFormDto);
			Book savedBook = adminBookService.saveBook(bookFormDto, bookImage);
			return ResponseEntity.ok(savedBook);
		} catch (Exception e) {
			System.out.println("도서 추가 중 에러 발생 " + e.getMessage());
			return ResponseEntity.badRequest().build();
		}
	}

	// 도서 조회
	@GetMapping("/items/{bookId}")
	@ResponseBody
	public ResponseEntity<BookFormDto> getBook(@PathVariable Long bookId) {
		try {
			BookFormDto bookFormDto = adminBookService.getBookId(bookId);
			return ResponseEntity.ok(bookFormDto);
		} catch (EntityNotFoundException e) {
			return ResponseEntity.notFound().build();
		}
	}

	// 도서 수정
	@PutMapping("/items/{bookId}")
	@ResponseBody
	public ResponseEntity<Void> updateBook(
			@PathVariable Long bookId,
			@RequestPart(value = "bookFormDto") BookFormDto bookFormDto,
			@RequestPart(value = "bookImage", required = false) MultipartFile bookImage) {
		try {
			adminBookService.updateBook(bookId, bookFormDto, bookImage);
			return ResponseEntity.ok().build();
		} catch (EntityNotFoundException e) {
			return ResponseEntity.notFound().build();
		} catch (Exception e) {
			return ResponseEntity.internalServerError().build();
		}
	}

	// 도서 삭제
	@DeleteMapping("/items/{bookId}")
	@ResponseBody
	public ResponseEntity<Void> deleteBook(@PathVariable Long bookId) {
		try {
			adminBookService.deleteBook(bookId);
			return ResponseEntity.ok().build();
		} catch (EntityNotFoundException e) {
			return ResponseEntity.notFound().build();
		} catch (Exception e) {
			return ResponseEntity.internalServerError().build();
		}
	}

	// 카테고리 로드
	@GetMapping("/categories/main")
	@ResponseBody
	public List<String> getMainCategories() {
		return adminBookRepository.findDistinctMainCategories();
	}

	@GetMapping("/categories/mid")
	@ResponseBody
	public List<String> getMidCategories() {
		return adminBookRepository.findDistinctMidCategories();
	}

	@GetMapping("/categories/sub")
	@ResponseBody
	public List<String> getSubCategories() {
		return adminBookRepository.findDistinctSubCategories();
	}

	@GetMapping("/categories/detail")
	@ResponseBody
	public List<String> getDetailCategories() {
		return adminBookRepository.findDistinctDetailCategories();
	}

	@GetMapping("/bookStat")
	public String itemStatistic() {
		return "/admin/books/bookStat";
	}

	@GetMapping("/stats/status")
	@ResponseBody
	public Map<String, Long> getBookStatusStats() {
		return adminBookService.getBookStatusDistribution();
	}

	@GetMapping("/stats/category")
	@ResponseBody
	public Map<String, Object> getCategoryStats() {
		return adminBookService.getCategoryDistribution();
	}

	@GetMapping("/stats/price-range")
	@ResponseBody
	public Map<String, Object> getPriceRangeStats() {
		return adminBookService.getPriceRangeStats();
	}

	@GetMapping("/stats/low-stock")
	@ResponseBody
	public Map<String, Object> getLowStockStats() {
		return adminBookService.getLowStockBooks();
	}

	@GetMapping("/stats/top-viewed-books")
	@ResponseBody
	public Map<String, Object> getTopViewedBooks() {
		return adminBookService.getTopViewedBooks();
	}

	@GetMapping("/stats/top-viewed-categories")
	@ResponseBody
	public Map<String, Object> getTopViewedCategories() {
		return adminBookService.getTopViewedCategories();
	}
}

package com.bbook.service;

import org.springframework.stereotype.Service;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.domain.PageImpl;

import com.bbook.dto.BookListDto;
import com.bbook.entity.Book;
import com.bbook.repository.BookRepository;

import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import java.util.List;
import java.util.stream.Collectors;
import java.util.Comparator;

@Service
@RequiredArgsConstructor
public class BookListService {

    private final BookRepository bookRepository;

    // 전체 도서 목록 조회 (페이징, 정렬, 필터링)
    public Page<BookListDto> getBooks(int page, int size, String sort, Integer minPrice, Integer maxPrice, List<String> categories) {
        Pageable pageable = createPageable(page, size, sort);
        Page<Book> bookPage;
        
        if (categories != null && !categories.isEmpty()) {
            // 카테고리 필터링을 DB 레벨에서 처리
            bookPage = bookRepository.findByMainCategoryInAndPriceRange(
                categories, minPrice, maxPrice, pageable);
        } else if (minPrice != null || maxPrice != null) {
            bookPage = bookRepository.findByPriceRange(minPrice, maxPrice, pageable);
        } else {
            bookPage = bookRepository.findAll(pageable);
        }

        return bookPage.map(this::convertToDto);
    }

    // 베스트 도서 목록 조회 (페이징, 정렬, 필터링)
    public Page<BookListDto> getBestBooks(int page, int size, String sort, Integer minPrice, Integer maxPrice, List<String> categories) {
        Pageable pageable = createPageable(page, size, sort);
        Page<Book> bookPage = bookRepository.findAllByOrderByViewCountDesc(pageable);
        
        // 필터링 적용
        List<Book> filteredBooks = bookPage.getContent().stream()
            .filter(book -> minPrice == null || book.getPrice() >= minPrice)
            .filter(book -> maxPrice == null || book.getPrice() <= maxPrice)
            .filter(book -> categories == null || categories.isEmpty() || categories.contains(book.getMainCategory()))
            .collect(Collectors.toList());

        return new PageImpl<>(
            filteredBooks.stream().map(this::convertToDto).collect(Collectors.toList()),
            pageable,
            filteredBooks.size()
        );
    }

    // 신규 도서 목록 조회 (페이징, 정렬, 필터링)
    public Page<BookListDto> getNewBooks(int page, int size, String sort, Integer minPrice, Integer maxPrice, List<String> categories) {
        Pageable pageable = createPageable(page, size, sort);
        Page<Book> bookPage = bookRepository.findAllByOrderByCreatedAtDesc(pageable);
        
        // 필터링 적용
        List<Book> filteredBooks = bookPage.getContent().stream()
            .filter(book -> minPrice == null || book.getPrice() >= minPrice)
            .filter(book -> maxPrice == null || book.getPrice() <= maxPrice)
            .filter(book -> categories == null || categories.isEmpty() || categories.contains(book.getMainCategory()))
            .collect(Collectors.toList());

        return new PageImpl<>(
            filteredBooks.stream().map(this::convertToDto).collect(Collectors.toList()),
            pageable,
            filteredBooks.size()
        );
    }

    // 카테고리별 도서 목록 조회 (페이징, 정렬, 필터링)
    public Page<BookListDto> getBooksByCategory(String mainCategory, String midCategory, String detailCategory,
            int page, int size, String sort, Integer minPrice, Integer maxPrice, List<String> categories) {
        Pageable pageable = createPageable(page, size, sort);
        Page<Book> bookPage;

        if (detailCategory != null) {
            bookPage = bookRepository.findByMainCategoryAndMidCategoryAndDetailCategory(
                mainCategory, midCategory, detailCategory, pageable);
        } else if (midCategory != null) {
            bookPage = bookRepository.findByMainCategoryAndMidCategory(mainCategory, midCategory, pageable);
        } else {
            bookPage = bookRepository.findByMainCategory(mainCategory, pageable);
        }

        // 필터링 적용
        List<Book> filteredBooks = bookPage.getContent().stream()
            .filter(book -> minPrice == null || book.getPrice() >= minPrice)
            .filter(book -> maxPrice == null || book.getPrice() <= maxPrice)
            .filter(book -> categories == null || categories.isEmpty() || categories.contains(book.getMainCategory()))
            .collect(Collectors.toList());

        return new PageImpl<>(
            filteredBooks.stream().map(this::convertToDto).collect(Collectors.toList()),
            pageable,
            filteredBooks.size()
        );
    }

    // 검색 결과 조회 (페이징, 정렬, 필터링)
    public Page<BookListDto> searchBooks(String searchQuery, int page, int size, String sort,
            Integer minPrice, Integer maxPrice, List<String> categories) {
        Pageable pageable = createPageable(page, size, sort);
        Page<Book> bookPage = bookRepository.searchBooks(searchQuery, pageable);
        
        // 필터링 적용
        List<Book> filteredBooks = bookPage.getContent().stream()
            .filter(book -> minPrice == null || book.getPrice() >= minPrice)
            .filter(book -> maxPrice == null || book.getPrice() <= maxPrice)
            .filter(book -> categories == null || categories.isEmpty() || categories.contains(book.getMainCategory()))
            .collect(Collectors.toList());

        return new PageImpl<>(
            filteredBooks.stream().map(this::convertToDto).collect(Collectors.toList()),
            pageable,
            filteredBooks.size()
        );
    }

    // 정렬 옵션에 따른 Pageable 생성
    private Pageable createPageable(int page, int size, String sort) {
        Sort.Direction direction = Sort.Direction.ASC;
        String property = "id";

        if (sort != null) {
            switch (sort) {
                case "price_asc":
                    property = "price";
                    direction = Sort.Direction.ASC;
                    break;
                case "price_desc":
                    property = "price";
                    direction = Sort.Direction.DESC;
                    break;
                case "popularity":
                    property = "viewCount";
                    direction = Sort.Direction.DESC;
                    break;
                case "newest":
                    property = "createdAt";
                    direction = Sort.Direction.DESC;
                    break;
                default:
                    property = "id";
                    direction = Sort.Direction.ASC;
            }
        }

        return PageRequest.of(page - 1, size, direction, property);
    }

    // 단일 책 조회
    public Book getBook(Long bookId) {
        return bookRepository.findById(bookId)
            .orElseThrow(() -> new EntityNotFoundException(
                "책을 찾을 수 없습니다. ID: " + bookId));
    }
    // 카테고리 조회 메서드
    public List<String> getMainCategories() {
        return bookRepository.findDistinctMainCategories();
    }

    public List<String> getMidCategories(String mainCategory) {
        return bookRepository.findDistinctMidCategoriesByMainCategory(mainCategory);
    }

    public List<String> getDetailCategories(String mainCategory, String midCategory) {
        return bookRepository.findDistinctDetailCategoriesByMainAndMidCategory(mainCategory, midCategory);
    }

    // 초기 도서 목록 조회 메서드들
    public List<BookListDto> getInitialBooks(int size) {
        return bookRepository.findTop10ByOrderByIdAsc(PageRequest.of(0, size))
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<BookListDto> getInitialBestBooks(int size) {
        return bookRepository.findTop10ByOrderByViewCountDesc(PageRequest.of(0, size))
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<BookListDto> getInitialNewBooks(int size) {
        return bookRepository.findTop10ByOrderByCreatedAtDesc(PageRequest.of(0, size))
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    // 초테고리별 초기 도서 목록 조회
    public List<BookListDto> getInitialBooksByMainCategory(String mainCategory, int size) {
        return bookRepository.findByMainCategoryOrderByIdAsc(mainCategory, PageRequest.of(0, size))
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<BookListDto> getInitialBooksByCategory(String mainCategory, String midCategory, int size) {
        return bookRepository
                .findByMainCategoryAndMidCategoryOrderByIdAsc(mainCategory, midCategory, PageRequest.of(0, size))
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<BookListDto> getInitialBooksByDetailCategory(String mainCategory, String midCategory,
            String detailCategory, int size) {
        return bookRepository.findByMainCategoryAndMidCategoryAndDetailCategoryOrderByIdAsc(
                mainCategory, midCategory, detailCategory, PageRequest.of(0, size))
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    // 무한 스크롤을 위한 다음 페이지 로딩 메서드들
    public List<BookListDto> getNextBooks(Long lastId, int size) {
        return bookRepository.findByIdGreaterThanOrderByIdAsc(lastId, PageRequest.of(0, size))
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<BookListDto> getNextBestBooks(Long lastId, int size) {
        return bookRepository.findByIdGreaterThanOrderByViewCountDesc(lastId, PageRequest.of(0, size))
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<BookListDto> getNextNewBooks(Long lastId, int size) {
        return bookRepository.findByIdGreaterThanOrderByCreatedAtDesc(lastId, PageRequest.of(0, size))
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<BookListDto> getNextBooksByMainCategory(Long lastId, String mainCategory, int size) {
        return bookRepository
                .findByIdGreaterThanAndMainCategoryOrderByIdAsc(lastId, mainCategory, PageRequest.of(0, size))
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<BookListDto> getNextBooksByCategory(Long lastId, String mainCategory, String midCategory, int size) {
        return bookRepository.findByIdGreaterThanAndMainCategoryAndMidCategoryOrderByIdAsc(
                lastId, mainCategory, midCategory, PageRequest.of(0, size))
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<BookListDto> getNextBooksByDetailCategory(Long lastId, String mainCategory, String midCategory,
            String detailCategory, int size) {
        return bookRepository.findByIdGreaterThanAndMainCategoryAndMidCategoryAndDetailCategoryOrderByIdAsc(
                lastId, mainCategory, midCategory, detailCategory, PageRequest.of(0, size))
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    // 검색 관련 메서드
    public List<BookListDto> searchInitialBooks(String searchQuery, int size) {
        return bookRepository.searchInitialBooks(searchQuery, PageRequest.of(0, size))
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<BookListDto> getNextSearchResults(Long lastId, String searchQuery, int size) {
        return bookRepository.findNextSearchResults(lastId, searchQuery, PageRequest.of(0, size))
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    // 정렬 관련 메서드
    public List<BookListDto> sortByPopularity(List<BookListDto> books) {
        return books.stream()
                .sorted((b1, b2) -> b2.getViewCount().compareTo(b1.getViewCount()))
                .collect(Collectors.toList());
    }

    public List<BookListDto> sortByPriceAsc(List<BookListDto> books) {
        return books.stream()
                .sorted(Comparator.comparing(BookListDto::getPrice))
                .collect(Collectors.toList());
    }

    public List<BookListDto> sortByPriceDesc(List<BookListDto> books) {
        return books.stream()
                .sorted((b1, b2) -> b2.getPrice().compareTo(b1.getPrice()))
                .collect(Collectors.toList());
    }
    public List<BookListDto> getTopBooksByCategory(String category, int limit) {
        return bookRepository.findTopBooksByCategory(category, limit)
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }
    // DTO 변환 메서드
    private BookListDto convertToDto(Book book) {
        return BookListDto.builder()
                .id(book.getId())
                .title(book.getTitle())
                .author(book.getAuthor())
                .publisher(book.getPublisher())
                .price(book.getPrice())
                .stock(book.getStock())
                .imageUrl(book.getImageUrl())
                .mainCategory(book.getMainCategory())
                .midCategory(book.getMidCategory())
                .detailCategory(book.getDetailCategory())
                .bookStatus(book.getBookStatus())
                .createdAt(book.getCreatedAt())
                .description(book.getDescription())
                .viewCount(book.getViewCount())
                .build();
    }

    // 전체 도서 목록 조회 (필터링 포함, 페이징 없음)
    public List<BookListDto> getAllBooks(String sort, Integer minPrice, Integer maxPrice, List<String> categories) {
        List<Book> allBooks = bookRepository.findAll();
        
        // 필터링 적용
        List<Book> filteredBooks = allBooks.stream()
            .filter(book -> minPrice == null || book.getPrice() >= minPrice)
            .filter(book -> maxPrice == null || book.getPrice() <= maxPrice)
            .filter(book -> categories == null || categories.isEmpty() || categories.contains(book.getMainCategory()))
            .collect(Collectors.toList());
            
        // 정렬 적용
        List<BookListDto> result = filteredBooks.stream()
            .map(this::convertToDto)
            .collect(Collectors.toList());
            
        applySorting(result, sort);
        
        return result;
    }
    
    // 베스트 도서 목록 조회 (필터링 포함, 페이징 없음)
    public List<BookListDto> getAllBestBooks(String sort, Integer minPrice, Integer maxPrice, List<String> categories) {
        List<Book> allBooks = bookRepository.findAll().stream()
            .sorted((b1, b2) -> b2.getViewCount().compareTo(b1.getViewCount()))
            .collect(Collectors.toList());
            
        // 필터링 적용
        List<Book> filteredBooks = allBooks.stream()
            .filter(book -> minPrice == null || book.getPrice() >= minPrice)
            .filter(book -> maxPrice == null || book.getPrice() <= maxPrice)
            .filter(book -> categories == null || categories.isEmpty() || categories.contains(book.getMainCategory()))
            .collect(Collectors.toList());
            
        // 정렬 적용
        List<BookListDto> result = filteredBooks.stream()
            .map(this::convertToDto)
            .collect(Collectors.toList());
            
        applySorting(result, sort);
        
        return result;
    }
    
    // 신규 도서 목록 조회 (필터링 포함, 페이징 없음)
    public List<BookListDto> getAllNewBooks(String sort, Integer minPrice, Integer maxPrice, List<String> categories) {
        List<Book> allBooks = bookRepository.findAll().stream()
            .sorted((b1, b2) -> b2.getCreatedAt().compareTo(b1.getCreatedAt()))
            .collect(Collectors.toList());
            
        // 필터링 적용
        List<Book> filteredBooks = allBooks.stream()
            .filter(book -> minPrice == null || book.getPrice() >= minPrice)
            .filter(book -> maxPrice == null || book.getPrice() <= maxPrice)
            .filter(book -> categories == null || categories.isEmpty() || categories.contains(book.getMainCategory()))
            .collect(Collectors.toList());
            
        // 정렬 적용
        List<BookListDto> result = filteredBooks.stream()
            .map(this::convertToDto)
            .collect(Collectors.toList());
            
        applySorting(result, sort);
        
        return result;
    }
    
    // 카테고리별 도서 목록 조회 (필터링 포함, 페이징 없음)
    public List<BookListDto> getAllBooksByCategory(String mainCategory, String midCategory, String detailCategory, 
            String sort, Integer minPrice, Integer maxPrice, List<String> categories) {
        List<Book> allBooks;
        
        if (detailCategory != null) {
            allBooks = bookRepository.findByMainCategoryAndMidCategoryAndDetailCategory(
                mainCategory, midCategory, detailCategory);
        } else if (midCategory != null) {
            allBooks = bookRepository.findByMainCategoryAndMidCategory(mainCategory, midCategory);
        } else {
            allBooks = bookRepository.findByMainCategory(mainCategory);
        }
            
        // 필터링 적용
        List<Book> filteredBooks = allBooks.stream()
            .filter(book -> minPrice == null || book.getPrice() >= minPrice)
            .filter(book -> maxPrice == null || book.getPrice() <= maxPrice)
            .filter(book -> categories == null || categories.isEmpty() || categories.contains(book.getMainCategory()))
            .collect(Collectors.toList());
            
        // 정렬 적용
        List<BookListDto> result = filteredBooks.stream()
            .map(this::convertToDto)
            .collect(Collectors.toList());
            
        applySorting(result, sort);
        
        return result;
    }
    
    // 검색 결과 조회 (필터링 포함, 페이징 없음)
    public List<BookListDto> getAllSearchBooks(String searchQuery, String sort, Integer minPrice, Integer maxPrice, 
            List<String> categories) {
        // 검색 쿼리 실행
        List<Book> searchResults = bookRepository.findAll().stream()
            .filter(book -> 
                (book.getTitle() != null && book.getTitle().contains(searchQuery)) ||
                (book.getAuthor() != null && book.getAuthor().contains(searchQuery)) ||
                (book.getPublisher() != null && book.getPublisher().contains(searchQuery)))
            .collect(Collectors.toList());
            
        // 필터링 적용
        List<Book> filteredBooks = searchResults.stream()
            .filter(book -> minPrice == null || book.getPrice() >= minPrice)
            .filter(book -> maxPrice == null || book.getPrice() <= maxPrice)
            .filter(book -> categories == null || categories.isEmpty() || categories.contains(book.getMainCategory()))
            .collect(Collectors.toList());
            
        // 정렬 적용
        List<BookListDto> result = filteredBooks.stream()
            .map(this::convertToDto)
            .collect(Collectors.toList());
            
        applySorting(result, sort);
        
        return result;
    }
    
    // 정렬 적용 헬퍼 메서드
    private void applySorting(List<BookListDto> books, String sort) {
        if (sort != null) {
            switch (sort) {
                case "price_asc":
                    books.sort(Comparator.comparing(BookListDto::getPrice));
                    break;
                case "price_desc":
                    books.sort((b1, b2) -> b2.getPrice().compareTo(b1.getPrice()));
                    break;
                case "popularity":
                    books.sort((b1, b2) -> b2.getViewCount().compareTo(b1.getViewCount()));
                    break;
                case "newest":
                    books.sort((b1, b2) -> b2.getCreatedAt().compareTo(b1.getCreatedAt()));
                    break;
                default:
                    // 기본 정렬
                    books.sort(Comparator.comparing(BookListDto::getId));
            }
        }
    }
}

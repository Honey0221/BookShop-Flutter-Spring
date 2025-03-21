package com.bbook.service;

import java.util.List;

import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import com.bbook.entity.Book;
import com.bbook.repository.BookRepository;
import com.bbook.service.crawling.BookTrailerCrawler;
import com.bbook.utils.YoutubeUrlConverter;

import jakarta.persistence.EntityNotFoundException;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional
public class BookDetailService {
	private final BookRepository bookRepository;
	private final YoutubeUrlConverter youtubeUrlConverter;
	private final BookTrailerCrawler trailerCrawler;

	public List<Book> getBooksByAuthor(String authorName) {
		return bookRepository.findByAuthor(authorName);
	}

	public List<Book> getBooksByMidCategory(String midCategory) {
		return bookRepository.findByMidCategory(midCategory);
	}

	public Book getBookById(Long id) {
		return bookRepository.findById(id)
				.orElseThrow(() -> new EntityNotFoundException("책을 찾을 수 없습니다." + id));
	}

	// 조회수 증가
	@Transactional
	public void incrementViewCount(Long bookId) {
		Book book = bookRepository.findById(bookId)
				.orElseThrow(() -> new EntityNotFoundException("책을 찾을 수 없습니다." + bookId));
		book.setViewCount(book.getViewCount() + 1);
	}

	// 트레일러 URL 조회
	@Async
	@Transactional
	public void getBookTrailerUrl(Long bookId) {
		try {
			Book book = bookRepository.findById(bookId)
					.orElseThrow(() -> new EntityNotFoundException("책이 찾을 수 없습니다." + bookId));

			System.out.println("북 트레일러 크롤링 시작 - " + book.getTitle());
			String trailerUrl = trailerCrawler.getBookTrailerUrl(book.getTitle());
			if (trailerUrl != null && !trailerUrl.isEmpty()) {
				String embedUrl = youtubeUrlConverter.convertToEmbedUrl(trailerUrl);
				book.setTrailerUrl(embedUrl);
			}
		} catch (Exception e) {
			System.out.println(e.getMessage());
		}
	}

}

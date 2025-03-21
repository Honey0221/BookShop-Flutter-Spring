package com.bbook.controller;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

import com.bbook.constant.ActivityType;
import com.bbook.dto.CartDetailDto;
import com.bbook.dto.CartBookDto;
import com.bbook.dto.BookRecommendationDto;
import com.bbook.jwt.JwtTokenProvider;
import com.bbook.service.CartService;
import com.bbook.service.MemberActivityService;
import com.bbook.entity.Member;
import com.bbook.entity.Subscription;
import com.bbook.repository.MemberRepository;
import com.bbook.repository.SubscriptionRepository;
import jakarta.persistence.EntityNotFoundException;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
public class CartController {
	private final CartService cartService;
	private final MemberActivityService memberActivityService;
	private final MemberRepository memberRepository;
	private final SubscriptionRepository subscriptionRepository;
	private final JwtTokenProvider jwtTokenProvider;

	/**
	 * 장바구니에 상품을 추가하는 API 엔드포인트
	 * 
	 * @param cartBookDto   장바구니에 담을 상품 정보 (상품 ID, 수량 등)
	 * @param bindingResult 검증 결과
	 * @param token         JWT 토큰
	 * @return ResponseEntity 장바구니 아이템 ID 또는 에러 메시지
	 */
	@PostMapping(value = "/cart")
	public ResponseEntity<Map<String, Object>> addToCart(
			@RequestBody @Valid CartBookDto cartBookDto,
			BindingResult bindingResult, 
			@RequestHeader("Authorization") String token) {
		
		Map<String, Object> result = new HashMap<>();
		
		// 입력값 검증 실패시 에러 메시지 반환
		if (bindingResult.hasErrors()) {
			StringBuilder sb = new StringBuilder();
			List<FieldError> fieldErrors = bindingResult.getFieldErrors();
			for (FieldError fieldError : fieldErrors) {
				sb.append(fieldError.getDefaultMessage());
			}
			result.put("success", false);
			result.put("message", sb.toString());
			return new ResponseEntity<>(result, HttpStatus.BAD_REQUEST);
		}

		// JWT 토큰에서 이메일 추출
		String jwtToken = token.replace("Bearer ", "");
		if (!jwtTokenProvider.validateToken(jwtToken)) {
			result.put("success", false);
			result.put("message", "유효하지 않은 토큰입니다.");
			return new ResponseEntity<>(result, HttpStatus.UNAUTHORIZED);
		}
		
		String email = jwtTokenProvider.getEmailFromToken(jwtToken);
		Long cartBookId;
		
		try {
			// 장바구니에 상품 추가 후 생성된 장바구니 아이템 ID 반환
			cartBookId = cartService.addCart(cartBookDto, email);
			memberActivityService.saveActivity(email, cartBookDto.getBookId(), ActivityType.CART);
			
			result.put("success", true);
			result.put("cartBookId", cartBookId);
			return new ResponseEntity<>(result, HttpStatus.OK);
		} catch (Exception e) {
			result.put("success", false);
			result.put("message", e.getMessage());
			return new ResponseEntity<>(result, HttpStatus.BAD_REQUEST);
		}
	}

	/**
	 * 장바구니 목록을 조회하는 API 엔드포인트
	 * 
	 * @param token JWT 토큰
	 * @return 장바구니 목록과 관련 정보
	 */
	@GetMapping(value = "/cart")
	public ResponseEntity<Map<String, Object>> getCartList(
			@RequestHeader("Authorization") String token) {
		Map<String, Object> result = new HashMap<>();
		
		// JWT 토큰에서 이메일 추출
		String jwtToken = token.replace("Bearer ", "");
		if (!jwtTokenProvider.validateToken(jwtToken)) {
			result.put("success", false);
			result.put("message", "유효하지 않은 토큰입니다.");
			return new ResponseEntity<>(result, HttpStatus.UNAUTHORIZED);
		}
		
		String email = jwtTokenProvider.getEmailFromToken(jwtToken);
		
		try {
			// 현재 사용자의 장바구니 목록 조회
			List<CartDetailDto> cartDetailList = cartService.getCartList(email);

			// 구독 상태 확인
			Member member = memberRepository.findByEmail(email)
					.orElseThrow(() -> new EntityNotFoundException("회원을 찾을 수 없습니다."));
			Subscription subscription = subscriptionRepository.findByMemberId(member.getId())
					.orElse(null);
			boolean isSubscriber = subscription != null && subscription.isActive();

			// 응답 데이터 구성
			result.put("success", true);
			result.put("cartBooks", cartDetailList);
			result.put("isSubscriber", isSubscriber);
			return new ResponseEntity<>(result, HttpStatus.OK);
		} catch (Exception e) {
			result.put("success", false);
			result.put("message", e.getMessage());
			return new ResponseEntity<>(result, HttpStatus.BAD_REQUEST);
		}
	}

	/**
	 * 장바구니 상품 수량을 업데이트하는 API 엔드포인트
	 * 
	 * @param requestData 업데이트할 장바구니 상품 정보
	 * @param token JWT 토큰
	 * @return 업데이트 결과
	 */
	@PatchMapping("/cart/update")
	public ResponseEntity<Map<String, Object>> updateCartBook(
			@RequestBody Map<String, Object> requestData,
			@RequestHeader("Authorization") String token) {
		
		Map<String, Object> result = new HashMap<>();
		
		// JWT 토큰에서 이메일 추출
		String jwtToken = token.replace("Bearer ", "");
		if (!jwtTokenProvider.validateToken(jwtToken)) {
			result.put("success", false);
			result.put("message", "유효하지 않은 토큰입니다.");
			return new ResponseEntity<>(result, HttpStatus.UNAUTHORIZED);
		}
		
		String email = jwtTokenProvider.getEmailFromToken(jwtToken);
		
		Long cartBookId = Long.parseLong(requestData.get("cartBookId").toString());
		Integer count = Integer.parseInt(requestData.get("count").toString());
		
		if (count <= 0) {
			result.put("success", false);
			result.put("message", "최소 1개 이상 담아주세요");
			return new ResponseEntity<>(result, HttpStatus.BAD_REQUEST);
		}
		
		if (!cartService.validateCartBook(cartBookId, email)) {
			result.put("success", false);
			result.put("message", "수정 권한이 없습니다.");
			return new ResponseEntity<>(result, HttpStatus.FORBIDDEN);
		}

		try {
			cartService.updateCartBookCount(cartBookId, count);
			result.put("success", true);
			result.put("message", "수량을 변경했습니다.");
			return new ResponseEntity<>(result, HttpStatus.OK);
		} catch (Exception e) {
			result.put("success", false);
			result.put("message", e.getMessage());
			return new ResponseEntity<>(result, HttpStatus.BAD_REQUEST);
		}
	}

	/**
	 * 장바구니 상품을 삭제하는 API 엔드포인트
	 * 
	 * @param cartBookId 삭제할 장바구니 상품 ID
	 * @param token JWT 토큰
	 * @return 삭제 결과
	 */
	@DeleteMapping(value = "/cart/delete/{cartBookId}")
	public ResponseEntity<Map<String, Object>> deleteCartBook(
			@PathVariable("cartBookId") Long cartBookId,
			@RequestHeader("Authorization") String token) {
		
		Map<String, Object> result = new HashMap<>();
		
		// JWT 토큰에서 이메일 추출
		String jwtToken = token.replace("Bearer ", "");
		if (!jwtTokenProvider.validateToken(jwtToken)) {
			result.put("success", false);
			result.put("message", "유효하지 않은 토큰입니다.");
			return new ResponseEntity<>(result, HttpStatus.UNAUTHORIZED);
		}
		
		String email = jwtTokenProvider.getEmailFromToken(jwtToken);
		
		if (!cartService.validateCartBook(cartBookId, email)) {
			result.put("success", false);
			result.put("message", "삭제 권한이 없습니다.");
			return new ResponseEntity<>(result, HttpStatus.FORBIDDEN);
		}
		
		try {
			Long bookId = cartService.deleteCartBook(cartBookId);
			memberActivityService.cancelActivity(email, bookId, ActivityType.CART);
			
			result.put("success", true);
			result.put("cartBookId", cartBookId);
			return new ResponseEntity<>(result, HttpStatus.OK);
		} catch (Exception e) {
			result.put("success", false);
			result.put("message", e.getMessage());
			return new ResponseEntity<>(result, HttpStatus.BAD_REQUEST);
		}
	}

	/**
	 * 여러 장바구니 상품을 일괄 삭제하는 API 엔드포인트
	 * 
	 * @param cartBookIds 삭제할 장바구니 상품 ID 목록
	 * @param token JWT 토큰
	 * @return 삭제 결과
	 */
	@DeleteMapping(value = "/cart/delete-multiple")
	public ResponseEntity<Map<String, Object>> deleteCartBooks(
			@RequestBody List<Long> cartBookIds,
			@RequestHeader("Authorization") String token) {
		
		Map<String, Object> result = new HashMap<>();
		
		// JWT 토큰에서 이메일 추출
		String jwtToken = token.replace("Bearer ", "");
		if (!jwtTokenProvider.validateToken(jwtToken)) {
			result.put("success", false);
			result.put("message", "유효하지 않은 토큰입니다.");
			return new ResponseEntity<>(result, HttpStatus.UNAUTHORIZED);
		}
		
		String email = jwtTokenProvider.getEmailFromToken(jwtToken);
		
		for (Long cartBookId : cartBookIds) {
			if (!cartService.validateCartBook(cartBookId, email)) {
				result.put("success", false);
				result.put("message", "삭제 권한이 없습니다.");
				return new ResponseEntity<>(result, HttpStatus.FORBIDDEN);
			}
		}

		try {
			for (Long cartBookId : cartBookIds) {
				Long bookId = cartService.deleteCartBook(cartBookId);
				memberActivityService.cancelActivity(email, bookId, ActivityType.CART);
			}
			
			result.put("success", true);
			result.put("deletedItems", cartBookIds);
			return new ResponseEntity<>(result, HttpStatus.OK);
		} catch (Exception e) {
			result.put("success", false);
			result.put("message", e.getMessage());
			return new ResponseEntity<>(result, HttpStatus.BAD_REQUEST);
		}
	}
}

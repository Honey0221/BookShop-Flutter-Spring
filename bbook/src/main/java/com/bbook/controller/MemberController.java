package com.bbook.controller;

import com.bbook.service.MemberService;
import com.bbook.service.RequestService;

import lombok.RequiredArgsConstructor;

import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;

import com.bbook.dto.MemberSignUpDto;
import com.bbook.dto.RequestFormDto;
import com.bbook.jwt.JwtTokenProvider;

import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.Map;
import java.util.Random;

import lombok.extern.slf4j.Slf4j;

import java.util.HashMap;
import java.util.List;

import jakarta.servlet.http.HttpServletRequest;

@RequestMapping("/members")
@RestController
@RequiredArgsConstructor
@Slf4j
public class MemberController {
	private final MemberService memberService;
	private final JavaMailSender mailSender;
	private final RequestService requestService;
	private final AuthenticationManager authenticationManager;
	private final JwtTokenProvider jwtTokenProvider;

	@GetMapping("/login")
	public String loginForm() {
		return "member/login";
	}

	@PostMapping("/login")
	public ResponseEntity<?> login(@RequestBody Map<String, String> request) {
		try {
			String email = request.get("email");
			String password = request.get("password");

			authenticationManager.authenticate(
					new UsernamePasswordAuthenticationToken(email, password));

			String jwt = jwtTokenProvider.generateToken(email);

			Map<String, String> response = new HashMap<>();
			response.put("token", jwt);
			response.put("email", email);

			return ResponseEntity.ok(response);
		} catch (Exception e) {
			System.out.println("로그인 실패: " + e.getMessage());
			return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
		}
	}

	@GetMapping("/login/error")
	public ResponseEntity<Map<String, String>> loginError() {
		Map<String, String> response = new HashMap<>();
		response.put("status", "error");
		response.put("message", "아이디 또는 비밀번호를 확인해주세요.");
		return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
	}

	@GetMapping("/login-error")
	public String loginError(Model model, HttpServletRequest request) {
		String errorMessage = (String) request.getAttribute("errorMessage");
		if (errorMessage == null) {
			errorMessage = "아이디 또는 비밀번호를 확인해주세요.";
		}
		model.addAttribute("loginErrorMsg", errorMessage);
		return "member/login";
	}

	@GetMapping("/signup")
	public String signupForm(Model model) {
		model.addAttribute("memberSignUpDto", new MemberSignUpDto());
		return "member/signupForm";
	}

	@PostMapping("/signup")
	public ResponseEntity<?> signUp(
			@RequestBody MemberSignUpDto signUpDto) {
		try {
			memberService.signUp(signUpDto);
			return ResponseEntity.ok().body("회원가입 성공");
		} catch (Exception e) {
			System.out.println("회원가입 실패: " + e.getMessage());
			return ResponseEntity.badRequest().body("회원가입 실패");
		}
	}

	@PostMapping("/emailCheck")
	@ResponseBody
	public ResponseEntity<Map<String, Object>> emailCheck(
			@RequestBody Map<String, String> request) {
		String email = request.get("email");
		String code = String.format("%06d", new Random().nextInt(1000000));

		// 이메일 내용 설정
		SimpleMailMessage message = new SimpleMailMessage();
		message.setTo(email);
		message.setSubject("회원가입 인증번호");
		message.setText("인증번호: " + code);
		mailSender.send(message);

		String token = jwtTokenProvider.generateEmailVerificationToken(email, code);

		Map<String, Object> response = new HashMap<>();
		response.put("token", token);

		System.out.println("토큰 생성 완료: " + token);

		return ResponseEntity.ok(response);
	}

	// 인증번호 확인을 위한 새로운 엔드포인트
	@PostMapping("/verifyEmail")
	@ResponseBody
	public ResponseEntity<?> verifyEmail(
			@RequestBody Map<String, String> request) {
		String inputCode = request.get("code");
		String token = request.get("token");

		try {
			Map<String, String> verificationInfo = jwtTokenProvider.getEmailVerificationInfo(token);
			String email = verificationInfo.get("email");
			String storedCode = verificationInfo.get("code");

			System.out.println("토큰 검증 결과: " + email + " 저장된 코드: " + storedCode);

			if (inputCode.equals(storedCode)) {
				System.out.println("인증번호 일치");
				return ResponseEntity.ok().build();
			} else {
				System.out.println("인증번호 불일치");
				return ResponseEntity.badRequest().build();
			}
		} catch (Exception e) {
			log.error("인증번호 확인 오류: {}", e.getMessage());
			return ResponseEntity.badRequest().build();
		}
	}

	@PostMapping("/social/nickname")
	public ResponseEntity<?> setSocialNickname(
		@RequestBody Map<String, String> request,
		HttpServletRequest httpRequest) {
		try {
			String authHeader = httpRequest.getHeader("Authorization");
			if (authHeader == null || !authHeader.startsWith("Bearer ")) {
				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("토큰이 없습니다.");
			}

			String token = authHeader.substring(7);
			String email = jwtTokenProvider.getEmailFromToken(token);
			String nickname = request.get("nickname");

			memberService.setNickname(email, nickname);
			
			Map<String, Object> response = new HashMap<>();
			response.put("success", true);
			return ResponseEntity.ok(response);
		} catch (Exception e) {
			System.out.println("소셜 닉네임 설정 오류: " + e.getMessage());
			return ResponseEntity.badRequest().body("닉네임 설정 실패");
		}
	}

	// 문의하기
	// 문의 목록 페이지
	@GetMapping("/request")
	public String requestList(Model model) {
		Authentication auth = SecurityContextHolder.getContext()
				.getAuthentication();
		String email = auth.getName();

		List<RequestFormDto> requests = requestService.getRequestsByEmail(email);
		model.addAttribute("requests", requests);

		return "member/requestForm";
	}

	// 문의 생성
	@PostMapping("/request")
	@ResponseBody
	public ResponseEntity<?> createRequest(
			@RequestBody Map<String, String> request) {
		Authentication auth = SecurityContextHolder.getContext()
				.getAuthentication();
		String email = auth.getName();

		String title = request.get("title");
		String content = request.get("content");

		Long requestId = requestService.createRequest(email, title, content);
		return ResponseEntity.ok(requestId);
	}

	// 문의 상세 조회
	@GetMapping("/request/{id}")
	@ResponseBody
	public ResponseEntity<RequestFormDto> getRequest(
			@PathVariable("id") Long requestId) {
		Authentication auth = SecurityContextHolder.getContext()
				.getAuthentication();
		String email = auth.getName();

		RequestFormDto request = requestService.getRequest(requestId);

		// 본인 문의만 조회 가능
		if (!request.getEmail().equals(email)) {
			return ResponseEntity.badRequest().build();
		}

		return ResponseEntity.ok(request);
	}

	// 문의 삭제
	@PostMapping("/request/{id}/delete")
	@ResponseBody
	public ResponseEntity<Void> deleteRequest(
			@PathVariable("id") Long requestId) {
		requestService.deleteRequest(requestId);
		return ResponseEntity.ok().build();
	}

	// 문의 수정
	@PostMapping("/request/{id}/update")
	@ResponseBody
	public ResponseEntity<Void> updateRequest(@PathVariable("id") Long requestId,
			@RequestBody Map<String, String> request) {
		requestService.updateRequestContent(requestId, request.get("content"));
		return ResponseEntity.ok().build();
	}
}

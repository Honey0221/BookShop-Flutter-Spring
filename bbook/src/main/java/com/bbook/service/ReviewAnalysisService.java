package com.bbook.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.theokanning.openai.service.OpenAiService;
import com.theokanning.openai.completion.CompletionRequest;
import com.theokanning.openai.completion.CompletionResult;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ReviewAnalysisService {
	@Value("${openai.api.key}")
	private String apiKey;

	private OpenAiService service;

	@PostConstruct
	public void init() {
		this.service = new OpenAiService(apiKey);
	}

	// 리뷰 분석 결과
	public record AnalysisResult(boolean isHateSpeech, boolean isUncomfortable) {}

	// 리뷰 분석
	public AnalysisResult analyzeReview(String review) {
		try {
			CompletionRequest request = CompletionRequest.builder()
				.model("gpt-3.5-turbo-instruct") // 사용할 모델 설정
				.prompt("리뷰 분석: " + review + "\n" + // 모델에게 전달할 텍스트
					"아래 형식으로 정확히 답변해주세요:\n" +
					"악의적: [true/false] (욕설/비방/인신공격 포함 시 true)\n" +
					"부정적: [true/false] (불만/실망/아쉬움 표현 시 true)")
				.temperature(0.3) // 창의성 정도 설정. 낮을수록 일관성 있는 답변 생성
				.maxTokens(50) // 답변의 최대 토큰 수 설정
				.build();

			// 응답 결과
			CompletionResult result = service.createCompletion(request);

			// 결과의 첫번째 선택지
			String analysis = result.getChoices().getFirst().getText().trim();
			
			System.out.println("=== GPT 응답 분석 시작 ===");
			System.out.println("전체 응답: " + analysis);

			String[] lines = analysis.split("\n");
			System.out.println("응답 줄 수: " + lines.length);
			
			for (int i = 0; i < lines.length; i++) {
				System.out.println("Line " + i + ": " + lines[i]);
			}

			// 악의적 표현 확인
			boolean isHateSpeech = false;
			if (lines[0].contains("악의적:")) {
				isHateSpeech = lines[0].toLowerCase().contains("true");
				System.out.println("악의적 표현 판단: " + isHateSpeech);
			}
			
			// 부정적 표현 확인
			boolean isUncomfortable = false;
			if (lines.length > 1 && lines[1].contains("부정적:")) {
				isUncomfortable = lines[1].toLowerCase().contains("true");
				System.out.println("부정적 표현 판단: " + isUncomfortable);
			}
			System.out.println("=== GPT 응답 분석 완료 ===");

			return new AnalysisResult(isHateSpeech, isUncomfortable);
		} catch (Exception e) {
			System.out.println("에러 메시지: " + e.getMessage());
			return new AnalysisResult(false, false);
		}
	}
}

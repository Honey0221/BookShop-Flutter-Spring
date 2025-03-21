package com.bbook.config;

import java.util.concurrent.Executor;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.AsyncConfigurer;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

// 비동기 작업을 처리하기 위해 설정한 클래스(임베딩 작업)
@Configuration
// 비동기 작업을 사용할 수 있도록 활성화
@EnableAsync
public class AsyncConfig implements AsyncConfigurer {
	@Override
	public Executor getAsyncExecutor() {
		// 스레드 풀 생성
		ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
		executor.setCorePoolSize(2); // 최소 스레드 수
		executor.setMaxPoolSize(5); // 최대 스레드 수
		executor.setQueueCapacity(10); // 대기 중인 작업을 저장할 수 있는 큐의 용량
		executor.setThreadNamePrefix("AsyncThread-"); // 스레드 이름의 접두사
		executor.initialize();
		return executor;
	}
}

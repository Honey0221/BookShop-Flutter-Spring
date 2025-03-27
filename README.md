# B-Book - 도서 쇼핑몰 웹/앱 서비스

B-Book은 Spring Boot 백엔드와 Flutter 프론트엔드를 결합한 도서 쇼핑몰 프로젝트입니다. 사용자가 다양한 도서를 검색, 필터링하고 장바구니에 담아 구매할 수 있는 기능을 제공합니다.

## ✨ 프로젝트 특징

- **크로스 플랫폼**: Flutter로 구현되어 웹, iOS, Android에서 동일한 UI/UX 제공
- **RESTful API**: Spring Boot 기반의 확장 가능하고 유지보수가 쉬운 API 설계
- **반응형 디자인**: 다양한 화면 크기에 최적화된 사용자 인터페이스
- **JWT 인증**: 안전한 사용자 인증 및 승인 처리
- **페이지네이션 & 필터링**: 효율적인 데이터 관리 및 사용자 경험 향상

## 📚 주요 기능

- **도서 검색 및 필터링**: 카테고리, 가격, 정렬(최신순, 가격순, 인기순) 등 다양한 조건으로 도서 검색
- **회원 관리**: 회원 가입, 로그인, 회원 정보 관리
- **장바구니**: 도서 추가, 수량 변경, 삭제
- **주문 및 결제**: 도서 주문 및 결제 처리
- **구독 서비스**: 도서 구독 관리
- **쿠폰**: 쿠폰 관리 및 할인 적용
- **추천 시스템**: 사용자 맞춤형 도서 추천

## 🛠 기술 스택

### 백엔드 (Spring Boot)
- **Java 17+**: 최신 Java 언어 기능 활용
- **Spring Boot 3.x**: RESTful API 개발
- **Spring Data JPA**: 데이터 액세스 계층
- **Spring Security + JWT**: 인증 및 권한 관리
- **MySQL 8.x**: 데이터베이스
- **Lombok**: 코드 간소화
- **Maven**: 의존성 및 빌드 관리

### 프론트엔드 (Flutter)
- **Flutter 3.x**: 크로스 플랫폼 UI 개발
- **Dart 3.x**: 프로그래밍 언어
- **HTTP 패키지**: 백엔드 API 통신
- **Shared Preferences**: 로컬 데이터 저장
- **Provider**: 상태 관리

## 📂 프로젝트 구조

### 백엔드 (Spring Boot)

```
bbook/
├── src/main/java/com/bbook/
│   ├── controller/     # REST API 컨트롤러
│   ├── service/        # 비즈니스 로직
│   ├── repository/     # 데이터 액세스
│   ├── entity/         # JPA 엔티티
│   ├── dto/            # 데이터 전송 객체
│   ├── config/         # 설정 클래스
│   ├── jwt/            # JWT 인증
│   ├── exception/      # 예외 처리
│   ├── utils/          # 유틸리티
│   └── constant/       # 상수
├── resources/          # 설정 파일
│   ├── application.properties  # 애플리케이션 설정
│   ├── static/         # 정적 리소스
│   └── templates/      # 템플릿
```

### 프론트엔드 (Flutter)

```
bbook_app/
├── lib/
│   ├── models/         # 데이터 모델
│   │   ├── book.dart
│   │   ├── cart.dart
│   │   ├── member.dart
│   │   └── ...
│   ├── main.dart       # 앱 진입점
│   ├── mainPage.dart   # 메인 페이지
│   ├── book_list_page.dart   # 도서 목록
│   ├── book_detail_page.dart # 도서 상세
│   ├── cart_page.dart        # 장바구니
│   ├── loginPage.dart        # 로그인
│   ├── signupPage.dart       # 회원가입
│   ├── payment_page.dart     # 결제
│   ├── subscription_page.dart # 구독
│   └── navigation_helper.dart # 네비게이션
```

## 💾 데이터베이스 구조

### 주요 테이블
- **Book**: 도서 정보 (ID, 제목, 저자, 출판사, 가격, 재고, 카테고리 등)
- **Member**: 회원 정보 (ID, 이메일, 비밀번호, 이름, 주소 등)
- **Cart**: 장바구니 (ID, 회원ID, 생성일자)
- **CartBook**: 장바구니에 담긴 도서 (ID, 장바구니ID, 도서ID, 수량)
- **Order**: 주문 정보 (ID, 회원ID, 주문일자, 총 금액, 상태)
- **OrderBook**: 주문된 도서 (ID, 주문ID, 도서ID, 수량, 가격)
- **Subscription**: 구독 정보 (ID, 회원ID, 구독 상태, 시작일, 종료일)
- **Coupon**: 쿠폰 정보 (ID, 회원ID, 할인 금액, 만료일)

## 📝 API 문서

### 회원 관련
- `POST /members/login`: 로그인
- `POST /members/signup`: 회원가입
- `GET /members/info`: 회원 정보 조회
- `PUT /members/info`: 회원 정보 수정

### 도서 관련
- `GET /book-list`: 전체 도서 목록
- `GET /book-list/best`: 베스트셀러 목록
- `GET /book-list/new`: 신간 도서 목록
- `GET /book-list/category`: 카테고리별 도서 목록
- `GET /book-list/search`: 도서 검색

### 장바구니 관련
- `GET /cart`: 장바구니 조회
- `POST /cart`: 장바구니에 도서 추가
- `PATCH /cart`: 장바구니 도서 수량 변경
- `DELETE /cart`: 장바구니에서 도서 삭제

### 주문 관련
- `POST /orders`: 주문 생성
- `GET /orders`: 주문 목록 조회
- `GET /orders/{id}`: 주문 상세 조회

## 👥 개발팀 소개
- 김지헌
- 안재원
- 이종민
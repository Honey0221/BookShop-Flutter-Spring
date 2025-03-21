import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final String baseUrl = 'http://localhost';
  bool _isSubscriber = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print("Token: $token");

      if (token == null) {
        // 로그인이 필요한 경우 처리
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인이 필요한 서비스입니다')));
        Navigator.pushReplacementNamed(context, '/members/login');
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/subscription/check'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isSubscriber = data['isSubscriber'] ?? false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('구독 상태 확인에 실패했습니다')));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
  }

  void _requestPayment(String type) {
    if (_isSubscriber) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('이미 구독 중입니다'),
            content: const Text('이미 활성화된 구독이 존재합니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
      return;
    }

    // 여기에 결제 처리 로직 구현
    // 실제 환경에서는 PG사 연동 필요
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('결제 진행'),
          content: Text('${type == 'MONTHLY' ? '월간' : '연간'} 구독을 시작하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _processPayment(type);
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void _processPayment(String type) {
    // 결제 완료 후 서버에 구독 정보 전송
    // 실제 환경에서는 PG사 결제 결과를 처리
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('구독 완료'),
          content: const Text('구독이 완료되었습니다. 이제 구독 서비스의 모든 혜택을 이용하실 수 있습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/main');
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('구독 서비스'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                const Text(
                  'BBOOK 구독 서비스',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  '더 많은 혜택과 함께 독서를 즐겨보세요',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // 구독 플랜 카드 - 반응형 레이아웃
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    // 화면 너비가 600px 이하면 세로 배치, 아니면 가로 배치
                    if (constraints.maxWidth < 600) {
                      return Column(
                        children: [
                          _buildSubscriptionCard(
                            title: '월간 구독',
                            price: '₩9,900',
                            period: '/월',
                            features: [
                              '매월 5,000원 상당의 적립금 지급',
                              '모든 도서 5% 추가 할인',
                              '무료 배송 서비스',
                              '신간 도서 알림 서비스',
                              '구매 시 10% 포인트 적립',
                              '', // 빈 항목 추가로 높이 맞추기
                              '',
                            ],
                            onSubscribe: () => _requestPayment('MONTHLY'),
                            isRecommended: false,
                          ),
                          const SizedBox(height: 24),
                          _buildSubscriptionCard(
                            title: '연간 구독',
                            price: '₩99,000',
                            period: '/년',
                            features: [
                              '매월 10,000원 상당의 적립금 지급',
                              '모든 도서 10% 추가 할인',
                              '무료 배송 서비스',
                              '신간 도서 알림 서비스',
                              '독서 모임 무료 참여',
                              '구매 시 10% 포인트 적립',
                              '2개월 무료 (10개월 가격)',
                            ],
                            onSubscribe: () => _requestPayment('YEARLY'),
                            isRecommended: true,
                          ),
                        ],
                      );
                    } else {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildSubscriptionCard(
                              title: '월간 구독',
                              price: '₩9,900',
                              period: '/월',
                              features: [
                                '매월 5,000원 상당의 적립금 지급',
                                '모든 도서 5% 추가 할인',
                                '무료 배송 서비스',
                                '신간 도서 알림 서비스',
                                '구매 시 10% 포인트 적립',
                                '', // 빈 항목 추가로 높이 맞추기
                                '',
                              ],
                              onSubscribe: () => _requestPayment('MONTHLY'),
                              isRecommended: false,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSubscriptionCard(
                              title: '연간 구독',
                              price: '₩99,000',
                              period: '/년',
                              features: [
                                '매월 10,000원 상당의 적립금 지급',
                                '모든 도서 10% 추가 할인',
                                '무료 배송 서비스',
                                '신간 도서 알림 서비스',
                                '독서 모임 무료 참여',
                                '구매 시 10% 포인트 적립',
                                '2개월 무료 (10개월 가격)',
                              ],
                              onSubscribe: () => _requestPayment('YEARLY'),
                              isRecommended: true,
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),

                const SizedBox(height: 50),

                // 혜택 섹션
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '구독 회원만의 특별한 혜택',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // 화면 너비에 따라 그리드 열 개수 조정
                          int crossAxisCount =
                              constraints.maxWidth < 600 ? 1 : 2;

                          return GridView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: 1.5,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              _buildBenefitItem(
                                icon: FontAwesomeIcons.coins,
                                title: '추가 적립금',
                                description:
                                    '매월 정기적으로 지급되는 추가 적립금으로 더 저렴하게 구매하세요',
                              ),
                              _buildBenefitItem(
                                icon: FontAwesomeIcons.percent,
                                title: '추가 할인',
                                description:
                                    '모든 도서에 적용되는 추가 할인으로 더 많은 책을 만나보세요',
                              ),
                              _buildBenefitItem(
                                icon: FontAwesomeIcons.truck,
                                title: '무료 배송',
                                description: '구매 금액에 상관없이 무료로 배송해드립니다',
                              ),
                              _buildBenefitItem(
                                icon: FontAwesomeIcons.bell,
                                title: '신간 알림',
                                description: '관심 분야의 신간이 출시되면 가장 먼저 알려드립니다',
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard({
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required VoidCallback onSubscribe,
    required bool isRecommended,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity, // 전체 너비 사용
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isRecommended
                      ? const Color(0xFF474C98)
                      : Colors.grey.shade300,
              width: isRecommended ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: price,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF474C98),
                      ),
                    ),
                    TextSpan(
                      text: period,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // 고정된 높이의 컨테이너 내에 피처 항목 배치
              Container(
                constraints: const BoxConstraints(minHeight: 230),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      features
                          .map((feature) => _buildFeatureItem(feature))
                          .toList(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, // 버튼 전체 너비 사용
                child: ElevatedButton(
                  onPressed: _isSubscriber ? null : onSubscribe,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF474C98),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.grey.shade400,
                  ),
                  child: Text(
                    '${title.split(' ')[0]} 구독 시작하기',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isRecommended)
          Positioned(
            top: -12,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF474C98),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '추천',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    if (text.isEmpty) {
      return const SizedBox(height: 24); // 빈 항목은 간격만 제공
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✓',
            style: TextStyle(
              color: Color(0xFF474C98),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(icon, color: const Color(0xFF474C98), size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

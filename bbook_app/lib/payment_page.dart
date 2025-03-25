import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show utf8, jsonDecode, jsonEncode;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'navigation_helper.dart';

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic>? paymentData;

  const PaymentPage({Key? key, this.paymentData}) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final String baseUrl = 'http://localhost:80';
  bool isLoading = true;
  late WebViewController _webViewController;
  Map<String, dynamic> orderData = {};
  num totalPrice = 0;
  bool isPreparing = true;
  String? errorMessage;
  String? orderId;

  @override
  void initState() {
    super.initState();
    // route 파라미터에서 데이터 추출
    if (widget.paymentData != null) {
      orderId = widget.paymentData!['orderId']?.toString();
      if (widget.paymentData!.containsKey('totalAmount')) {
        totalPrice = widget.paymentData!['totalAmount'] as num;
      }
    }
    _initPayment();
  }

  Future<void> _initPayment() async {
    try {
      // 1. 주문 정보 가져오기
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          errorMessage = "로그인이 필요합니다.";
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/order/payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('주문 정보를 가져오는데 실패했습니다.');
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (data['success'] != true) {
        throw Exception(data['message'] ?? '주문 정보를 가져오는데 실패했습니다.');
      }

      setState(() {
        orderData = data['orderDto'] as Map<String, dynamic>;
        totalPrice = data['totalPrice'] as num;
        isPreparing = false;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF76C97F),
        foregroundColor: Colors.white,
        title: Text('결제하기'),
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : isPreparing
              ? Center(child: Text('결제 정보를 준비 중입니다...'))
              : _buildPaymentContent(),
    );
  }

  Widget _buildPaymentContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 주문 요약 정보
                _buildOrderSummary(),
                SizedBox(height: 20),

                // 결제 버튼
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF76C97F),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _openPaymentWebView,
                    child: Text('결제하기', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    final orderName = orderData['orderName'] ?? '주문 상품';

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '주문 정보',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('상품명'), Text(orderName)],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('결제 금액'),
                Text(
                  '$totalPrice원',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF76C97F),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openPaymentWebView() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              AppBar(
                backgroundColor: Color(0xFF76C97F),
                automaticallyImplyLeading: false,
                title: Text('카카오페이 결제'),
                actions: [
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: WebViewWidget(
                  controller:
                      _webViewController =
                          WebViewController()
                            ..setJavaScriptMode(JavaScriptMode.unrestricted)
                            ..setNavigationDelegate(
                              NavigationDelegate(
                                onNavigationRequest: (
                                  NavigationRequest request,
                                ) {
                                  // 결제 완료 후 리다이렉트 처리
                                  if (request.url.contains('success') ||
                                      request.url.contains('order/success')) {
                                    _processPaymentResult(request.url);
                                    return NavigationDecision.prevent;
                                  }
                                  return NavigationDecision.navigate;
                                },
                              ),
                            ),
                ),
              ),
            ],
          ),
        );
      },
    );

    // 웹뷰가 생성된 후 HTML 로드
    _loadPaymentPage();
  }

  Future<void> _loadPaymentPage() async {
    final merchantUid = 'ORDER-${DateTime.now().millisecondsSinceEpoch}';
    final orderName = orderData['orderName'] ?? '주문 상품';

    // HTML에 Iamport 결제 코드 삽입
    final html = '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <script type="text/javascript" src="https://code.jquery.com/jquery-1.12.4.min.js"></script>
          <script type="text/javascript" src="https://cdn.iamport.kr/js/iamport.payment-1.2.0.js"></script>
        </head>
        <body>
          <script type="text/javascript">
            var IMP = window.IMP;
            IMP.init("imp00000000"); // 가맹점 식별코드

            function requestPay() {
              IMP.request_pay({
                pg: "kakaopay",
                pay_method: "card",
                merchant_uid: "$merchantUid",
                name: "$orderName",
                amount: $totalPrice,
                buyer_email: "${orderData['email'] ?? ''}",
                buyer_name: "${orderData['name'] ?? ''}",
                buyer_tel: "${orderData['phone'] ?? ''}",
                buyer_addr: "${orderData['address'] ?? ''}"
              }, function(rsp) {
                if (rsp.success) {
                  // 결제 성공 시 검증 요청
                  window.location.href = "success://?imp_uid=" + rsp.imp_uid + "&merchant_uid=" + rsp.merchant_uid + "&amount=" + rsp.paid_amount;
                } else {
                  // 결제 실패 시
                  window.location.href = "fail://?error_msg=" + rsp.error_msg;
                }
              });
            }

            // 페이지 로드 시 자동으로 결제 요청
            jQuery(document).ready(function() {
              requestPay();
            });
          </script>
        </body>
      </html>
    ''';

    _webViewController.loadHtmlString(html);
  }

  void _processPaymentResult(String url) async {
    Navigator.pop(context); // 웹뷰 닫기

    try {
      setState(() {
        isLoading = true;
      });

      final uri = Uri.parse(url);

      if (url.startsWith('success://')) {
        // 결제 성공 처리
        final impUid = uri.queryParameters['imp_uid'];
        final merchantUid = uri.queryParameters['merchant_uid'];
        final amount = uri.queryParameters['amount'];

        if (impUid == null || merchantUid == null || amount == null) {
          throw Exception('결제 정보가 올바르지 않습니다.');
        }

        // 서버에 결제 검증 요청
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');

        final response = await http.post(
          Uri.parse('$baseUrl/orders/verify'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'impUid': impUid,
            'merchantUid': merchantUid,
            'amount': int.parse(amount),
          }),
        );

        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (data['success'] == true) {
          // 결제 성공 페이지로 이동
          NavigationHelper.navigate(
            context,
            '/order/success/${data['orderId']}',
          );
        } else {
          throw Exception(data['message'] ?? '결제 검증에 실패했습니다.');
        }
      } else {
        // 결제 실패 처리
        final errorMsg = uri.queryParameters['error_msg'] ?? '결제에 실패했습니다.';
        throw Exception(errorMsg);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('결제 처리 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

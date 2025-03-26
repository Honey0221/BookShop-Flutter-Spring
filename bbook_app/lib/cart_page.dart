import 'package:bbook_app/models/book.dart';
import 'package:bbook_app/models/cart.dart';
import 'package:bbook_app/models/cart_book.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navigation_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show utf8, jsonDecode, jsonEncode;

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPage();
}

class _CartPage extends State<CartPage> {
  final String baseUrl = 'http://localhost';
  bool isLoading = true;
  bool isLoggedIn = false;
  Cart? cart;
  List<CartBook> cartBooks = [];

  // 금액 관련 상태
  int totalPrice = 0;
  int deliveryFee = 0;
  int orderTotalPrice = 0;
  int expectedPoints = 0;

  // 회원 구독 여부
  bool isSubscriber = false;

  // 무료 배송 기준 금액
  final int freeShippingThreshold = 15000;

  // 기본 배송비
  final int defaultDeliveryFee = 3000;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      setState(() {
        isLoggedIn = false;
        isLoading = false;
      });

      // 로그인 페이지로 이동
      Future.delayed(Duration.zero, () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인이 필요한 기능입니다.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: '로그인',
              textColor: Colors.white,
              onPressed: () {
                NavigationHelper.navigate(context, '/members/login');
              },
            ),
          ),
        );
      });
      return;
    }

    setState(() {
      isLoggedIn = true;
    });

    // 장바구니 정보 로드
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    if (!isLoggedIn) return;

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          isLoggedIn = false;
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인이 필요한 기능입니다.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: '로그인',
              textColor: Colors.white,
              onPressed: () {
                NavigationHelper.navigate(context, '/members/login');
              },
            ),
          ),
        );
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/cart'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      bool isSuccess = data['success'] ?? false;
      if (isSuccess) {
        setState(() {
          if (data is Map && data.containsKey('cartBooks')) {
            List<dynamic> cartBooksData = data['cartBooks'];
            cartBooks = [];

            for (var bookData in cartBooksData) {
              CartBook cartBook = CartBook(
                id: bookData['cartBookId'],
                count: bookData['count'],
                book: Book(
                  id: bookData['bookId'],
                  title: bookData['bookName'],
                  price: bookData['price'],
                  stock: bookData['stock'],
                  author: bookData['author'] ?? '',
                  imageUrl: bookData['imageUrl'],
                  mainCategory: bookData['mainCategory'] ?? '',
                  midCategory: bookData['midCategory'] ?? '',
                  publisher: bookData['publisher'] ?? '',
                ),
              );
              cartBooks.add(cartBook);
            }
          }

          if (data is Map) {
            isSubscriber = data['isSubscriber'] ?? false;
          }
          isLoading = false;
        });

        // 금액 계산
        _calculateTotalPrice();
      }
    } catch (e) {
      print('장바구니 로드 오류: $e');
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('장바구니 정보를 불러오는데 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _calculateTotalPrice() {
    int itemsTotal = 0;

    for (var cartBook in cartBooks) {
      if (cartBook.book != null) {
        itemsTotal += cartBook.book!.price! * cartBook.count;
      }
    }

    // 배송비 계산
    int shipping = 0;
    if (!isSubscriber && itemsTotal < freeShippingThreshold && itemsTotal > 0) {
      shipping = defaultDeliveryFee;
    }

    // 포인트 계산
    int points =
        isSubscriber ? (itemsTotal * 0.1).round() : (itemsTotal * 0.05).round();

    setState(() {
      totalPrice = itemsTotal;
      deliveryFee = shipping;
      orderTotalPrice = itemsTotal + shipping;
      expectedPoints = points;
    });
  }

  Future<void> _updateQuantity(CartBook cartBook, int newCount) async {
    if (newCount < 1) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인이 필요한 기능입니다.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/cart/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'cartBookId': cartBook.id, 'count': newCount}),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (data['success'] == true) {
        // 로컬 상태 업데이트
        setState(() {
          for (var i = 0; i < cartBooks.length; i++) {
            if (cartBooks[i].id == cartBook.id) {
              cartBooks[i] = CartBook(
                id: cartBooks[i].id,
                cartId: cartBooks[i].cartId,
                book: cartBooks[i].book,
                count: newCount,
              );
              break;
            }
          }
        });

        // 금액 재계산
        _calculateTotalPrice();
      }
    } catch (e) {
      print('수량 변경 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('수량 변경 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeCartItem(int? cartBookId) async {
    if (cartBookId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인이 필요한 기능입니다.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/cart/delete/$cartBookId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (data['success'] == true) {
        setState(() {
          cartBooks.removeWhere((item) => item.id == cartBookId);
          isLoading = false;
        });

        // 금액 재계산
        _calculateTotalPrice();

        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('상품이 장바구니에서 삭제되었습니다.'),
            backgroundColor: Color(0xFF76C97F),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      print('상품 삭제 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('상품 삭제 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color(0xFF76C97F);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text('장바구니 (${cartBooks.length})'),
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              )
              : !isLoggedIn
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('로그인이 필요한 기능입니다.'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        NavigationHelper.navigate(context, '/members/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                      child: Text('로그인하기'),
                    ),
                  ],
                ),
              )
              : cartBooks.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '장바구니가 비어있습니다.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        NavigationHelper.navigate(context, '/book-list/best');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                      child: Text('쇼핑 계속하기'),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartBooks.length,
                      itemBuilder: (context, index) {
                        final cartBook = cartBooks[index];
                        return _buildCartItem(cartBook);
                      },
                    ),
                  ),
                  _buildOrderSummary(),
                ],
              ),
    );
  }

  Widget _buildCartItem(CartBook cartBook) {
    if (cartBook.book == null) {
      return SizedBox.shrink();
    }

    final book = cartBook.book!;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 책 표지 이미지
          Container(
            width: 80,
            height: 120,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                book.imageUrl ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: Center(child: Icon(Icons.image_not_supported)),
                  );
                },
              ),
            ),
          ),
          SizedBox(width: 16),

          // 책 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title ?? '',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Text(
                  '${book.price?.toString() ?? '0'}원',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF76C97F),
                  ),
                ),
                SizedBox(height: 16),

                // 수량 조절
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildQuantityButton(
                          icon: Icons.remove,
                          onPressed: () {
                            if (cartBook.count > 1) {
                              _updateQuantity(cartBook, cartBook.count - 1);
                            }
                          },
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            cartBook.count.toString(),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        _buildQuantityButton(
                          icon: Icons.add,
                          onPressed: () {
                            _updateQuantity(cartBook, cartBook.count + 1);
                          },
                        ),
                      ],
                    ),

                    // 합계 금액
                    Text(
                      '${(book.price! * cartBook.count).toString()}원',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    // 삭제 버튼
                    IconButton(
                      icon: Icon(Icons.delete_outline),
                      onPressed: () {
                        _removeCartItem(cartBook.id);
                      },
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 결제 정보
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('상품금액'), Text('${totalPrice.toString()}원')],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('배송비'),
                  SizedBox(width: 4),
                  InkWell(
                    onTap: () => _showShippingInfoDialog(),
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Text('${deliveryFee.toString()}원'),
            ],
          ),
          Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '결제 총 금액',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '${orderTotalPrice.toString()}원',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF76C97F),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('적립 예정 포인트'),
                  SizedBox(width: 4),
                  InkWell(
                    onTap: () => _showPointsInfoDialog(),
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Text('${expectedPoints.toString()}P'),
            ],
          ),
          SizedBox(height: 16),

          // 버튼
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    NavigationHelper.navigate(context, '/book-list/best');
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xFF76C97F)),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    '쇼핑 계속하기',
                    style: TextStyle(color: Color(0xFF76C97F)),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      cartBooks.isEmpty
                          ? null
                          : () {
                            // 주문하기
                            NavigationHelper.navigate(context, '/order');
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF76C97F),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('주문하기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showShippingInfoDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('배송비 안내'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '배송비 정책',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text('• 15,000원 이상 구매 시 무료배송'),
                Text('• 15,000원 미만 구매 시 배송비 3,000원'),
                Text('• 구독 회원은 모든 주문 무료배송'),
                SizedBox(height: 12),
                Text(
                  '※ 배송비는 주문 금액에 따라 자동으로 계산됩니다.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('확인'),
              ),
            ],
          ),
    );
  }

  void _showPointsInfoDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('포인트 적립 안내'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber, size: 18),
                    SizedBox(width: 8),
                    Text('구독회원: 결제금액의 10% 적립'),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Text('일반회원: 결제금액의 5% 적립'),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey, size: 16),
                    SizedBox(width: 8),
                    Text('적립금은 다음 주문 시 사용 가능합니다.'),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey, size: 16),
                    SizedBox(width: 8),
                    Text('적립금은 100P 단위로 사용 가능합니다.'),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.grey, size: 16),
                    SizedBox(width: 8),
                    Text('적립금은 결제 완료 후 즉시 적립됩니다.'),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('확인'),
              ),
            ],
          ),
    );
  }
}

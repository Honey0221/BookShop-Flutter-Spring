import 'package:bbook_app/models/book.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navigation_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show utf8, jsonDecode, jsonEncode;

class BookDetailPage extends StatefulWidget {
  final int bookId;

  const BookDetailPage({super.key, required this.bookId});

  @override
  State<BookDetailPage> createState() => _BookDetailPage();
}

class _BookDetailPage extends State<BookDetailPage> with SingleTickerProviderStateMixin {
  final String baseUrl = 'http://localhost';
  bool isLoading = true;
  bool isLoggedIn = false;
  Book? book;
  List<Book> authorBooks = [];
  List<Book> categoryBooks = [];
  int quantity = 1;
  TabController? _tabController;
  bool _isBottomBarVisible = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _checkLoginStatus();
    _loadBookDetails();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    setState(() {
      isLoggedIn = token != null;
    });
  }

  Future<void> _loadBookDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl/item?bookId=${widget.bookId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          book = Book.fromJson(data['book']);
          
          if (data['authorBooks'] != null) {
            authorBooks = (data['authorBooks'] as List)
                .map((bookData) => Book.fromJson(bookData))
                .toList();
          }
          
          if (data['categoryBooks'] != null) {
            categoryBooks = (data['categoryBooks'] as List)
                .map((bookData) => Book.fromJson(bookData))
                .toList();
          }
          
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load book details');
      }
    } catch (e) {
      print('도서 상세 정보 로드 오류: $e');
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('도서 정보를 불러오는데 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  void _updateQuantity(int change) {
    final newQuantity = quantity + change;
    if (newQuantity >= 1 && newQuantity <= (book?.stock ?? 1)) {
      setState(() {
        quantity = newQuantity;
        _calculateTotalPrice();
      });
    }
  }
  
  int _calculateTotalPrice() {
    return (book?.price ?? 0) * quantity;
  }
  
  Future<void> _addToCart() async {
    if (!isLoggedIn) {
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

      final response = await http.post(
        Uri.parse('$baseUrl/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'bookId': book?.id,
          'count': quantity,
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('장바구니에 추가되었습니다.'),
            backgroundColor: Color(0xFF76C97F),
            action: SnackBarAction(
              label: '장바구니로 이동',
              textColor: Colors.white,
              onPressed: () {
                NavigationHelper.navigate(context, '/cart-list');
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('장바구니 추가 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('장바구니 추가 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _order() async {
    if (!isLoggedIn) {
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

      await prefs.setString('directOrder', jsonEncode({
        'bookId': book?.id,
        'count': quantity,
      }));
      
      NavigationHelper.navigate(context, '/order?direct=true');
    } catch (e) {
      print('주문 진행 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('주문 진행 중 오류가 발생했습니다.'),
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
        title: Text('도서 상세'),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            )
          : book == null
              ? Center(child: Text('도서 정보를 찾을 수 없습니다.'))
              : Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCategoryPath(),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 책 이미지
                                    Container(
                                      width: 120,
                                      height: 180,
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
                                          book!.imageUrl ?? '',
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
                                            book!.title ?? '',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          _buildInfoRow('저자', book!.author ?? ''),
                                          _buildInfoRow('출판사', book!.publisher ?? ''),
                                          _buildInfoRow('가격', '${book!.price!.toString() ?? '0'}원'),
                                          _buildInfoRow('재고', '${book!.stock!.toString() ?? '0'}개'),
                                          
                                          // 수량 조절
                                          SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Text('수량', style: TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(width: 16),
                                              _buildQuantityControl(),
                                            ],
                                          ),
                                          
                                          // 총 가격
                                          SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '총 결제 금액',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                '${_calculateTotalPrice().toString()}원',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // 탭 영역
                          Container(
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: Colors.grey.shade300)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TabBar(
                                  controller: _tabController,
                                  labelColor: primaryColor,
                                  unselectedLabelColor: Colors.grey,
                                  indicatorColor: primaryColor,
                                  isScrollable: true,
                                  tabAlignment: TabAlignment.start,
                                  tabs: [
                                    Tab(text: '상세 설명'),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.all(16),
                                  constraints: BoxConstraints(maxHeight: 200),
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      SingleChildScrollView(
                                        child: Text(book!.description ?? '상세 설명이 없습니다.'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // 작가의 다른 책들
                          if (authorBooks.isNotEmpty)
                            _buildRecommendationSection(
                              '작가의 다른 책들',
                              authorBooks,
                            ),
                            
                          // 같은 카테고리 책들
                          if (categoryBooks.isNotEmpty)
                            _buildRecommendationSection(
                              '같은 카테고리 책들',
                              categoryBooks,
                            ),
                            
                          SizedBox(height: _isBottomBarVisible ? 80 : 40),
                        ],
                      ),
                    ),
                    
                    // 토글 버튼
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: _isBottomBarVisible ? 80 : 0,
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _isBottomBarVisible = !_isBottomBarVisible;
                                });
                              },
                              child: AnimatedRotation(
                                duration: Duration(milliseconds: 300),
                                turns: _isBottomBarVisible ? 0.5 : 0,
                                child: Icon(
                                  Icons.keyboard_arrow_up,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // 하단 고정 버튼
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeInOutCubic,
                        height: _isBottomBarVisible ? 80 : 0,
                        child: AnimatedOpacity(
                          duration: Duration(milliseconds: 300),
                          opacity: _isBottomBarVisible ? 1.0 : 0.0,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _addToCart,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primaryColor,
                                      side: BorderSide(color: primaryColor),
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.shopping_cart, size: 20, color: primaryColor),
                                        SizedBox(width: 8),
                                        Text(
                                          '장바구니 추가',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _order,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.credit_card, size: 20, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          '바로 구매하기',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
  
  Widget _buildCategoryPath() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Text(
            '도서',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
          Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade500),
          if (book?.mainCategory != null)
            Text(
              book!.mainCategory! ?? '',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          if (book?.midCategory != null) ...[
            Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade500),
            Text(
              book!.midCategory! ?? '',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: label == '가격' ? Color(0xFF76C97F) : Colors.black,
                fontWeight: label == '가격' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuantityControl() {
    return Row(
      children: [
        _buildQuantityButton(
          icon: Icons.remove,
          onPressed: () => _updateQuantity(-1),
        ),
        Container(
          width: 50,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              quantity.toString(),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        _buildQuantityButton(
          icon: Icons.add,
          onPressed: () => _updateQuantity(1),
        ),
      ],
    );
  }
  
  Widget _buildQuantityButton({required IconData icon, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
  
  Widget _buildRecommendationSection(String title, List<Book> books) {
    if (books.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (books.length <= 2)
          // 2권 이하일 때는 Row로 표시
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: books.length == 1 
                  ? MainAxisAlignment.start 
                  : MainAxisAlignment.spaceAround,
              children: books.map((book) => SizedBox(
                width: 140,  // 카드 너비 고정
                height: 220,
                child: _buildBookCard(book),
              )).toList(),
            ),
          )
        else
          // 3권 이상일 때는 슬라이드로 표시
          Container(
            height: 220,
            child: CarouselSlider.builder(
              itemCount: books.length,
              itemBuilder: (context, index, realIndex) {
                final book = books[index];
                return _buildBookCard(book);
              },
              options: CarouselOptions(
                height: 220,
                viewportFraction: 0.4,
                enableInfiniteScroll: true,
                autoPlay: true,
                autoPlayInterval: Duration(seconds: 3),
                autoPlayAnimationDuration: Duration(milliseconds: 800),
                autoPlayCurve: Curves.fastOutSlowIn,
                enlargeCenterPage: true,
                scrollDirection: Axis.horizontal,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildBookCard(Book book) {
    final bool isSoldOut = book.stock == 0;

    return InkWell(
      onTap: isSoldOut ? null : () {
        NavigationHelper.navigate(context, '/item?bookId=${book.id}');
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    child: ColorFiltered(
                      colorFilter: isSoldOut
                          ? ColorFilter.mode(
                              Colors.grey,
                              BlendMode.saturation,
                            )
                          : ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.color,
                            ),
                      child: Image.network(
                        book.imageUrl ?? '',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: Center(child: Icon(Icons.image_not_supported)),
                          );
                        },
                      ),
                    ),
                  ),
                  if (isSoldOut)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '품절',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSoldOut ? Colors.grey : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${book.price?.toString() ?? '0'}원',
                    style: TextStyle(
                      color: isSoldOut ? Colors.grey : Color(0xFF76C97F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
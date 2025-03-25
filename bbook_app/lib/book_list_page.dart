import 'package:bbook_app/models/book.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navigation_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show utf8, jsonDecode, jsonEncode;

class BookListPage extends StatefulWidget {
  final String listType;
  final Map<String, String>? queryParams;

  const BookListPage({Key? key, required this.listType, this.queryParams})
    : super(key: key);

  @override
  _BookListPageState createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  final String baseUrl = 'http://localhost';
  bool isLoading = true;
  bool isLoggedIn = false;
  List<Book> books = [];
  String pageTitle = '';
  int currentPage = 1;
  int totalPages = 1;
  final int booksPerPage = 10;

  // 필터링 관련 상태
  String selectedSort = '최신순';
  RangeValues priceRange = RangeValues(0, 100000);
  List<String> selectedCategories = [];

  // 필터링 옵션
  final List<String> sortOptions = ['최신순', '가격 낮은순', '가격 높은순', '인기순'];
  final List<String> categoryOptions = [
    '국내도서',
    '서양도서',
    '일본도서',
    '컴퓨터/IT',
    '인문학',
    '소설',
    '경영/경제',
    '자기계발',
  ];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _setupPageTitle();
    _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    setState(() {
      isLoggedIn = token != null;
    });
  }

  void _setupPageTitle() {
    switch (widget.listType) {
      case 'best':
        pageTitle = '베스트셀러';
        break;
      case 'new':
        pageTitle = '신간도서';
        break;
      case 'search':
        final query = widget.queryParams?['searchQuery'] ?? '';
        pageTitle = '"$query" 검색결과';
        break;
      case 'category':
        final mainCategory = widget.queryParams?['main'] ?? '';
        final subCategory = widget.queryParams?['sub'] ?? '';
        pageTitle =
            subCategory.isNotEmpty
                ? '$mainCategory > $subCategory'
                : mainCategory;
        break;
      default:
        pageTitle = '도서 목록';
    }
  }

  Future<void> _loadBooks() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final endpoint = _getEndpoint();
      final response = await http.get(Uri.parse(endpoint));
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      books =
          (data['data'] as List).map((item) => Book.fromJson(item)).toList();

      // 정렬 적용
      _sortBooks();

      // 페이지네이션 정보 설정 (실제 API에서는 이 정보를 서버에서 받아오겠지만 여기서는 간단히 구현)
      totalPages = (books.length / booksPerPage).ceil();
    } catch (e) {
      print('도서 목록 로드 오류: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getEndpoint() {
    String endpoint = '$baseUrl';

    switch (widget.listType) {
      case 'best':
        endpoint += '/book-list/best';
        break;
      case 'new':
        endpoint += '/book-list/new';
        break;
      case 'search':
        final query = widget.queryParams?['searchQuery'] ?? '';
        endpoint +=
            '/book-list/search?searchQuery=${Uri.encodeComponent(query)}';
        break;
      case 'category':
        final mainCategory = widget.queryParams?['main'] ?? '';
        final subCategory = widget.queryParams?['sub'] ?? '';
        endpoint +=
            '/book-list/category?main=${Uri.encodeComponent(mainCategory)}';
        if (subCategory.isNotEmpty) {
          endpoint += '&sub=${Uri.encodeComponent(subCategory)}';
        }
        break;
      default:
        endpoint += '/book-list';
    }

    // 페이지 정보 추가
    endpoint += endpoint.contains('?') ? '&' : '?';
    endpoint += 'page=$currentPage&size=$booksPerPage';

    return endpoint;
  }

  void _sortBooks() {
    switch (selectedSort) {
      case '가격 낮은순':
        books.sort((a, b) => a.price.compareTo(b.price));
        break;
      case '가격 높은순':
        books.sort((a, b) => b.price.compareTo(a.price));
        break;
      case '인기순':
        books.sort((a, b) => (b.viewCount ?? 0).compareTo(a.viewCount ?? 0));
        break;
      case '최신순':
      default:
        // 이미 서버에서 최신순으로 정렬되었다고 가정
        break;
    }
  }

  void _changePage(int page) {
    setState(() {
      currentPage = page;
    });
    _loadBooks();
  }

  void _applyFilter() {
    _loadBooks();
  }

  // 장바구니에 책 추가하는 함수
  Future<void> _addToCart(Book book) async {
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
        body: jsonEncode({'bookId': book.id, 'count': 1}),
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

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color(0xFF76C97F);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(pageTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // 검색 페이지로 이동
              NavigationHelper.navigate(context, '/search');
            },
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              NavigationHelper.navigate(context, '/cart-list');
            },
          ),
        ],
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              )
              : Column(
                children: [
                  _buildFilterSection(),
                  Expanded(
                    child:
                        books.isEmpty
                            ? Center(child: Text('검색 결과가 없습니다.'))
                            : ListView.builder(
                              itemCount: books.length,
                              itemBuilder: (context, index) {
                                final book = books[index];
                                return _buildBookItem(book);
                              },
                            ),
                  ),
                  _buildPagination(),
                ],
              ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '총 ${books.length}개의 상품',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: selectedSort,
                onChanged: (value) {
                  setState(() {
                    selectedSort = value!;
                    _sortBooks();
                  });
                },
                items:
                    sortOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
          SizedBox(height: 16),
          ExpansionTile(
            title: Text('상세 필터'),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('가격대'),
                  RangeSlider(
                    values: priceRange,
                    max: 100000,
                    divisions: 20,
                    labels: RangeLabels(
                      '${priceRange.start.round()}원',
                      '${priceRange.end.round()}원',
                    ),
                    onChanged: (RangeValues values) {
                      setState(() {
                        priceRange = values;
                      });
                    },
                  ),
                  Wrap(
                    spacing: 8,
                    children:
                        categoryOptions.map((category) {
                          final isSelected = selectedCategories.contains(
                            category,
                          );
                          return FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedCategories.add(category);
                                } else {
                                  selectedCategories.remove(category);
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: _applyFilter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF76C97F),
                      ),
                      child: Text('필터 적용'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookItem(Book book) {
    final bool isSoldOut = book.stock <= 0;

    return InkWell(
      onTap:
          isSoldOut
              ? null
              : () {
                NavigationHelper.navigate(context, '/item?bookId=${book.id}');
              },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 책 표지 이미지
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 150,
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
                    child: ColorFiltered(
                      colorFilter:
                          isSoldOut
                              ? ColorFilter.mode(
                                Colors.grey,
                                BlendMode.saturation,
                              )
                              : ColorFilter.mode(
                                Colors.transparent,
                                BlendMode.color,
                              ),
                      child: Image.network(
                        book.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: Icon(Icons.image_not_supported),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (isSoldOut)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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
            SizedBox(width: 16),
            // 책 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '[${book.mainCategory}] ${book.title}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSoldOut ? Colors.grey : Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '저자: ${book.author} | 출판사: ${book.publisher}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  SizedBox(height: 4),
                  if (book.description != null)
                    Text(
                      book.description!,
                      style: TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${book.price}원',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSoldOut ? Colors.grey : Color(0xFF76C97F),
                        ),
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              _addToCart(book);
                            },
                            icon: Icon(Icons.shopping_cart, size: 18),
                            label: Text('담기'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF76C97F),
                              padding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.favorite_border),
                            onPressed: () {
                              // 찜하기 기능
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('찜 목록에 추가되었습니다.'),
                                  backgroundColor: Color(0xFF76C97F),
                                ),
                              );
                            },
                            color: Colors.red,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (totalPages <= 1) return SizedBox();

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed:
                currentPage > 1 ? () => _changePage(currentPage - 1) : null,
          ),
          for (int i = 1; i <= totalPages; i++)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: i != currentPage ? () => _changePage(i) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      i == currentPage ? Color(0xFF76C97F) : Colors.white,
                  foregroundColor:
                      i == currentPage ? Colors.white : Colors.black,
                  shape: CircleBorder(),
                  minimumSize: Size(40, 40),
                ),
                child: Text('$i'),
              ),
            ),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed:
                currentPage < totalPages
                    ? () => _changePage(currentPage + 1)
                    : null,
          ),
        ],
      ),
    );
  }
}

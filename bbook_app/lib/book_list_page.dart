import 'package:bbook_app/models/book.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navigation_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show utf8, jsonDecode, jsonEncode;
import 'dart:math' show min, max;

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
  String selectedSort = 'newest';
  RangeValues priceRange = RangeValues(0, 100000);
  List<String> selectedCategories = [];

  // 필터링 옵션
  final Map<String, String> sortOptions = {
    'newest': '최신순',
    'price_asc': '가격 낮은순',
    'price_desc': '가격 높은순',
    'popularity': '인기순',
  };

  final List<String> categoryOptions = [
    '국내도서',
    '서양도서',
    '일본도서',
    '컴퓨터/IT',
    '인문학',
    '소설',
    '경영/경제',
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
    try {
      setState(() {
        isLoading = true;
      });

      final response = await http.get(Uri.parse(_getEndpoint()));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        setState(() {
          books = (data['data'] as List)
              .map((book) => Book.fromJson(book))
              .toList();
          totalPages = data['totalPages'] ?? 1;
          currentPage = data['currentPage'] ?? 1;
          
          print('페이지: $currentPage / $totalPages, 도서 개수: ${data['totalItems']}');
          
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('도서 로드 오류 발생: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getEndpoint() {
    String endpoint = '$baseUrl';

    final queryParams = {
      'page': currentPage.toString(),
      'size': booksPerPage.toString(),
      'sort': selectedSort,
      if (priceRange.start != 0) 'minPrice': priceRange.start.round().toString(),
      if (priceRange.end != 100000) 'maxPrice': priceRange.end.round().toString(),
      if (selectedCategories.isNotEmpty) 'categories': selectedCategories.join(','),
    };

    final queryString = queryParams.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    switch (widget.listType) {
      case 'best':
        endpoint += '/book-list/best';
        break;
      case 'new':
        endpoint += '/book-list/new';
        break;
      case 'search':
        final query = widget.queryParams?['searchQuery'] ?? '';
        endpoint += '/book-list/search?searchQuery=${Uri.encodeComponent(query)}';
        break;
      case 'category':
        final mainCategory = widget.queryParams?['main'] ?? '';
        final subCategory = widget.queryParams?['sub'] ?? '';
        endpoint += '/book-list/category?main=${Uri.encodeComponent(mainCategory)}';
        if (subCategory.isNotEmpty) {
          endpoint += '&sub=${Uri.encodeComponent(subCategory)}';
        }
        break;
      default:
        endpoint += '/book-list';
    }

    endpoint += endpoint.contains('?') ? '&$queryString' : '?$queryString';

    return endpoint;
  }

  void _changePage(int page) {
    setState(() {
      currentPage = page;
    });
    _loadBooks();
  }

  void _applyFilter() {
    setState(() {
      currentPage = 1; // 필터 적용 시 첫 페이지로 이동
    });
    _loadBooks();
  }

  // 정렬 옵션 변경 시 호출되는 메서드
  void _onSortChanged(String? value) {
    if (value != null) {
      setState(() {
        selectedSort = value;
        currentPage = 1; // 정렬 변경 시 첫 페이지로 이동
      });
      _loadBooks();
    }
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

    return GestureDetector(
      onTap: () {
        if (_isSearchVisible) {
          setState(() {
            _isSearchVisible = false;
          });
          FocusScope.of(context).unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          title: Text(pageTitle),
          actions: [
            _isSearchVisible
                ? Container(
                    width: 180,
                    height: 40,
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: '검색',
                                hintStyle: TextStyle(color: Colors.white70),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                isDense: true,
                                isCollapsed: true,
                              ),
                              textAlignVertical: TextAlignVertical.center,
                              onSubmitted: _executeSearch,
                            ),
                          ),
                        ),
                        Center(
                          child: IconButton(
                            icon: Icon(Icons.search, color: Colors.white),
                            iconSize: 24,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            onPressed: () {
                              if (_searchController.text.isNotEmpty) {
                                _executeSearch(_searchController.text);
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                      ],
                    ),
                  )
                : IconButton(
                    icon: Icon(Icons.search),
                    onPressed: _toggleSearchVisibility,
                  ),
            IconButton(
              icon: Icon(Icons.shopping_cart),
              onPressed: () {
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
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '정렬',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSort,
                    onChanged: _onSortChanged,
                    icon: Icon(Icons.keyboard_arrow_down, size: 20),
                    isDense: true,
                    items: sortOptions.entries.map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value, style: TextStyle(fontSize: 14)),
                      ),
                    ).toList(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: Color(0xFF76C97F),
                  ),
            ),
            child: ExpansionTile(
              tilePadding: EdgeInsets.symmetric(horizontal: 0),
              title: Row(
                children: [
                  Text(
                    '상세 필터',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              childrenPadding: EdgeInsets.only(top: 8, bottom: 4),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '가격대',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${priceRange.start.round()}원 - ${priceRange.end.round()}원',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF76C97F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: Color(0xFF76C97F),
                        inactiveTrackColor: Colors.grey.shade200,
                        thumbColor: Colors.white,
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 8.0,
                          elevation: 2.0,
                        ),
                        overlayColor: Color(0xFF76C97F).withOpacity(0.2),
                      ),
                      child: RangeSlider(
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
                    ),
                    SizedBox(height: 16),
                    Text(
                      '카테고리',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categoryOptions.map((category) {
                          final isSelected = selectedCategories.contains(category);
                          return FilterChip(
                            label: Text(category, style: TextStyle(fontSize: 13)),
                            selected: isSelected,
                            selectedColor: Color(0xFF76C97F).withOpacity(0.2),
                            checkmarkColor: Color(0xFF76C97F),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isSelected ? Color(0xFF76C97F) : Colors.grey.shade300,
                              ),
                            ),
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
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _applyFilter,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF76C97F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size(200, 44),
                          elevation: 0,
                        ),
                        child: Text(
                          '필터 적용',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookItem(Book book) {
    final bool isSoldOut = book.stock == 0;

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
                        book.imageUrl ?? '',
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
                    '${book.title ?? ''}',
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
                    '저자: ${book.author ?? ''} | 출판사: ${book.publisher ?? ''}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  SizedBox(height: 4),
                  if (book.description != null)
                    Text(
                      book.description ?? '',
                      style: TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${book.price?.toString() ?? '0'}원',
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
                            icon: Icon(Icons.shopping_cart, size: 18, color: Colors.white),
                            label: Text('담기', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF76C97F),
                              padding: EdgeInsets.symmetric(horizontal: 8),
                            ),
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
    if (totalPages <= 1) return SizedBox.shrink();
    
    // 현재 페이지 주변 표시할 페이지 수
    final int maxVisiblePages = 5;
    int startPage = 1;
    
    // 현재 페이지가 중앙에 오도록 계산
    if (currentPage > 3) {
      startPage = currentPage - 2;
    }
    
    // 마지막 페이지 근처에서는 항상 마지막 5개 페이지가 보이도록 조정
    if (startPage + 4 > totalPages) {
      startPage = max(1, totalPages - 4);
    }
    
    int endPage = min(startPage + 4, totalPages);
    
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 맨 앞으로 버튼
          Container(
            width: 28,
            child: IconButton(
              icon: Icon(Icons.first_page, size: 18),
              onPressed: currentPage > 1 ? () => _changePage(1) : null,
              tooltip: '처음으로',
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
          ),
          // 이전 페이지 버튼
          Container(
            width: 28,
            child: IconButton(
              icon: Icon(Icons.chevron_left, size: 18),
              onPressed: currentPage > 1 ? () => _changePage(currentPage - 1) : null,
              tooltip: '이전',
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
          ),
          // 페이지 버튼들
          for (int i = startPage; i <= endPage; i++)
            _buildPageButton(i),
          // 다음 페이지 버튼
          Container(
            width: 28,
            child: IconButton(
              icon: Icon(Icons.chevron_right, size: 18),
              onPressed: currentPage < totalPages ? () => _changePage(currentPage + 1) : null,
              tooltip: '다음',
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
          ),
          // 맨 마지막으로 버튼
          Container(
            width: 28,
            child: IconButton(
              icon: Icon(Icons.last_page, size: 18),
              onPressed: currentPage < totalPages ? () => _changePage(totalPages) : null,
              tooltip: '마지막으로',
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton(int page) {
    return Container(
      child: ElevatedButton(
        onPressed: page != currentPage ? () => _changePage(page) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: page == currentPage ? Color(0xFF76C97F) : Colors.white,
          foregroundColor: page == currentPage ? Colors.white : Colors.black,
          shape: CircleBorder(),
          minimumSize: Size(32, 32),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          '$page',
          style: TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  void _toggleSearchVisibility() {
    if (mounted) {
      setState(() {
        _isSearchVisible = true;
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) {
            FocusScope.of(context).requestFocus(_searchFocusNode);
          }
        });
      });
    }
  }

  void _executeSearch(String value) {
    if (value.isNotEmpty) {
      NavigationHelper.navigate(
        context,
        '/book-list/search?searchQuery=${Uri.encodeComponent(value)}',
      );
      if (mounted) {
        setState(() {
          _isSearchVisible = false;
          _searchController.clear();
        });
      }
    }
  }
}

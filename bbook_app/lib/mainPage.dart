import 'package:bbook_app/models/book.dart';
import 'package:bbook_app/footer.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navigation_helper.dart';
import 'custom_fab_menu.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show utf8, jsonDecode;
import 'package:bbook_app/recommend_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPage();
}

class _MainPage extends State<MainPage> with TickerProviderStateMixin {
  final String baseUrl = 'http://localhost';
  TabController? _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Color primaryColor = Color(0xFF76C97F);
  final Color primaryLightColor = Color(0xFFE8F5E9);

  bool isLoading = false;
  bool isLoggedIn = false;
  bool _isSearchVisible = false;

  List<Book> bestBooks = [];
  List<Book> newBooks = [];
  List<Book> personalizedBooks = [];
  List<Book> collaborativeBooks = [];
  List<Book> contentBasedBooks = [];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    setState(() {
      isLoggedIn = token != null;
      _initTabController();
    });

    _loadBooks();
  }

  void _initTabController() {
    _tabController?.dispose();
    int tabCount = isLoggedIn ? 5 : 2;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');

      setState(() {
        isLoggedIn = false;
      });

      _initTabController();
      _loadBooks();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 되었습니다'), backgroundColor: Colors.green),
      );
    } catch (e) {
      print('로그아웃 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 실패했습니다'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadBooks() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final bestResponse = await http.get(Uri.parse('$baseUrl/books/best'));
      final bestData = jsonDecode(utf8.decode(bestResponse.bodyBytes));
      bestBooks =
          (bestData['data'] as List)
              .map((item) => Book.fromJson(item))
              .toList();

      final newResponse = await http.get(Uri.parse('$baseUrl/books/new'));
      final newData = jsonDecode(utf8.decode(newResponse.bodyBytes));
      newBooks =
          (newData['data'] as List).map((item) => Book.fromJson(item)).toList();

      if (isLoggedIn) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');

          final personalizedResponse = await http.get(
            Uri.parse('$baseUrl/recommendation/personalized'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          final personalizedData = jsonDecode(
            utf8.decode(personalizedResponse.bodyBytes),
          );
          personalizedBooks =
              (personalizedData['data'] as List)
                  .map((item) => Book.fromJson(item))
                  .toList();
        } catch (e) {
          print('맞춤 추천 로드 오류: $e');
        }

        try {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');

          final collaborativeResponse = await http.get(
            Uri.parse('$baseUrl/recommendation/collaborative'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          final collaborativeData = jsonDecode(
            utf8.decode(collaborativeResponse.bodyBytes),
          );
          collaborativeBooks =
              (collaborativeData['data'] as List)
                  .map((item) => Book.fromJson(item))
                  .toList();
        } catch (e) {
          print('협업 필터링 추천 로드 오류: $e');
        }

        try {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');

          final contentBasedResponse = await http.get(
            Uri.parse('$baseUrl/recommendation/content-based'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          final contentBasedData = jsonDecode(
            utf8.decode(contentBasedResponse.bodyBytes),
          );
          contentBasedBooks =
              (contentBasedData['data'] as List)
                  .map((item) => Book.fromJson(item))
                  .toList();
        } catch (e) {
          print('카테고리 기반 추천 로드 오류: $e');
        }
      } else {
        personalizedBooks = [];
        collaborativeBooks = [];
        contentBasedBooks = [];
      }
    } catch (e) {
      print('도서 로드 오류: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      );
    }

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
          title: Text('B-Book'),
          actions: [
            TextButton(
              onPressed: () {
                if (isLoggedIn) {
                  _logout();
                } else {
                  NavigationHelper.navigate(context, '/members/login');
                }
              },
              child: Text(
                isLoggedIn ? '로그아웃' : '로그인',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
                NavigationHelper.navigate(context, '/cart-list');
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButtonMenu(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.menu_book),
          elevation: 8.0,
          items: [
            FloatingActionButtonItem(
              heroTag: 'chatbot',
              backgroundColor: Color(0xFF9C27B0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.robot, size: 20),
                  SizedBox(height: 2),
                  Text(
                    '추천',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              onTap: () {
                RecommendPage.show(context);
              },
            ),
            FloatingActionButtonItem(
              heroTag: 'coupon',
              backgroundColor: Color(0xFF1F8CE6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.ticket, size: 20),
                  SizedBox(height: 2),
                  Text(
                    '쿠폰존',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              onTap: () {
                Navigator.pushNamed(context, '/coupon-zone');
              },
            ),
            FloatingActionButtonItem(
              heroTag: 'subscription',
              backgroundColor: Color(0xFF474C98),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.crown, size: 20),
                  SizedBox(height: 2),
                  Text(
                    '구독',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              onTap: () {
                Navigator.pushNamed(context, '/subscription');
              },
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body:
            isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                )
                : Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(color: primaryLightColor),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'B',
                                          style: TextStyle(color: primaryColor),
                                        ),
                                        TextSpan(text: 'uilders '),
                                        TextSpan(
                                          text: 'B',
                                          style: TextStyle(color: primaryColor),
                                        ),
                                        TextSpan(text: 'ook'),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '당신의 일상에 특별한 이야기를 더합니다',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _buildCategorySection(),
                          _buildTabBar(),
                          Container(
                            height: 300,
                            child: TabBarView(
                              controller: _tabController,
                              children:
                                  isLoggedIn
                                      ? [
                                        _buildBookCarousel(bestBooks),
                                        _buildBookCarousel(newBooks),
                                        _buildBookCarousel(personalizedBooks),
                                        _buildBookCarousel(collaborativeBooks),
                                        _buildBookCarousel(contentBasedBooks),
                                      ]
                                      : [
                                        _buildBookCarousel(bestBooks),
                                        _buildBookCarousel(newBooks),
                                      ],
                            ),
                          ),
                          Footer(
                            primaryColor: primaryColor,
                            primaryLightColor: primaryLightColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildCategoryCircle(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primaryLightColor,
              shape: BoxShape.circle,
            ),
            child: Center(child: FaIcon(icon, color: primaryColor, size: 20)),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBookCarousel(List<Book> books) {
    if (books.isEmpty) {
      return Center(child: Text('도서 정보가 없습니다.'));
    }

    return CarouselSlider.builder(
      itemCount: books.length,
      itemBuilder: (context, index, realIndex) {
        final book = books[index];
        return _buildBookCard(book);
      },
      options: CarouselOptions(
        height: 280,
        aspectRatio: 16 / 9,
        viewportFraction: 0.4,
        initialPage: 0,
        enableInfiniteScroll: true,
        autoPlay: true,
        autoPlayInterval: Duration(seconds: 3),
        autoPlayAnimationDuration: Duration(milliseconds: 800),
        autoPlayCurve: Curves.fastOutSlowIn,
        enlargeCenterPage: true,
        scrollDirection: Axis.horizontal,
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCategoryCircle(FontAwesomeIcons.crown, '베스트', () {
            NavigationHelper.navigate(context, '/book-list/best');
          }),
          _buildCategoryCircle(FontAwesomeIcons.star, '신규', () {
            NavigationHelper.navigate(context, '/book-list/new');
          }),
          _buildCategoryCircle(FontAwesomeIcons.tabletButton, 'ebook', () {
            NavigationHelper.navigate(
              context,
              '/book-list/category?main=ebook',
            );
          }),
          _buildCategoryCircle(FontAwesomeIcons.book, '국내도서', () {
            NavigationHelper.navigate(context, '/book-list/category?main=국내도서');
          }),
          _buildCategoryCircle(FontAwesomeIcons.earthAsia, '서양도서', () {
            NavigationHelper.navigate(context, '/book-list/category?main=서양도서');
          }),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      child: TabBar(
        controller: _tabController,
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: primaryColor,
        indicatorPadding: EdgeInsets.symmetric(horizontal: 4),
        isScrollable: true,
        tabAlignment: isLoggedIn ? TabAlignment.start : TabAlignment.center,
        tabs: [
          Tab(icon: Icon(FontAwesomeIcons.crown), text: '베스트상품'),
          Tab(icon: Icon(FontAwesomeIcons.star), text: '신규 상품'),
          if (isLoggedIn)
            Tab(icon: Icon(FontAwesomeIcons.wandMagicSparkles), text: '맞춤 추천'),
          if (isLoggedIn)
            Tab(icon: Icon(FontAwesomeIcons.users), text: '회원 추천'),
          if (isLoggedIn)
            Tab(icon: Icon(FontAwesomeIcons.bookmark), text: '카테고리 추천'),
        ],
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    return InkWell(
      onTap: () {
        NavigationHelper.navigate(context, '/item?bookId=${book.id}');
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  book.imageUrl,
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
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${book.price.toString()}원',
                    style: TextStyle(
                      color: primaryColor,
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

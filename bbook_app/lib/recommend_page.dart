import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'models/book.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'navigation_helper.dart';

// showDialog를 쉽게 호출할 수 있는 static 메서드 추가
class RecommendPage extends StatefulWidget {
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder:
          (BuildContext context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.all(16),
            child: RecommendPage(),
          ),
    );
  }

  const RecommendPage({super.key});

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  final String baseUrl = 'http://localhost';
  final Color primaryColor = Color(0xFF76C97F);
  bool isLoading = false;

  // 단일 장르 선택을 위한 변수
  String? selectedGenre;

  // 추천 도서 목록
  List<Book> recommendedBooks = [];

  // 장르 목록 단순화
  final List<String> allGenres = [
    '소설',
    '시/에세이',
    '경제/경영',
    '자기계발',
    '인문',
    '컴퓨터/IT',
    '자연과학',
    '예술',
  ];

  // 장르 선택 시 자동으로 호출되는 메서드
  Future<void> _loadRecommendations(String genre) async {
    setState(() {
      isLoading = true;
    });

    try {
      final encodedGenre = Uri.encodeComponent(genre);
      final response = await http.get(
        Uri.parse(
          '$baseUrl/recommendation/category-top?category=$encodedGenre&limit=3',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('Response body: ${response.body}'); // 디버깅용 로그
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data != null && data['data'] != null) {
          setState(() {
            recommendedBooks =
                (data['data'] as List)
                    .map((item) => Book.fromJson(item))
                    .toList();
          });
        } else {
          print('데이터 형식이 올바르지 않습니다: $data');
        }
      } else {
        print('서버 응답 오류: ${response.statusCode}');
        print('응답 내용: ${response.body}');
      }
    } catch (e) {
      print('추천 도서 로드 오류: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 모달 헤더
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '맞춤 도서 추천',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),
          // 모달 내용
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '관심있는 장르를 선택해주세요',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      allGenres.map((genre) {
                        return FilterChip(
                          selected: selectedGenre == genre,
                          label: Text(genre),
                          onSelected: (selected) {
                            setState(() {
                              selectedGenre = selected ? genre : null;
                            });
                            if (selected) {
                              _loadRecommendations(genre);
                            }
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: primaryColor.withOpacity(0.2),
                          checkmarkColor: primaryColor,
                        );
                      }).toList(),
                ),
                SizedBox(height: 24),
                if (isLoading)
                  Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  )
                else if (recommendedBooks.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '추천 도서',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: recommendedBooks.length,
                          itemBuilder: (context, index) {
                            final book = recommendedBooks[index];
                            return Container(
                              width: 140,
                              margin: EdgeInsets.only(right: 16),
                              child: _buildBookCard(book),
                            );
                          },
                        ),
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
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

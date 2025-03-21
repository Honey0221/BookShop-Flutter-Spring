import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'navigation_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '로그인',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),

                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: '이메일 주소',
                        hintText: '이메일을 입력해주세요',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '이메일을 입력해주세요';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return '유효한 이메일 주소를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                        hintText: '비밀번호를 입력해주세요',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 8),

                    if (_errorMessage != null)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Theme.of(context).primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '로그인',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    SizedBox(height: 12),

                    OutlinedButton(
                      onPressed: () {
                        NavigationHelper.navigate(context, '/members/signup');
                      },  
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Theme.of(context).primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '회원가입',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              '소셜 계정으로 로그인',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                    ),

                    _buildSocialButton(
                      icon: FontAwesomeIcons.google,
                      text: 'Google 로그인',
                      color: Color(0xFFDD4B39),
                      onPressed: () => {},
                    ),
                    SizedBox(height: 12),

                    _buildSocialButton(
                      icon: FontAwesomeIcons.comment,
                      text: 'Kakao 로그인',
                      color: Color(0xFFFEE500),
                      onPressed: () => {},
                    ),
                    SizedBox(height: 12),

                    _buildSocialButton(
                      icon: FontAwesomeIcons.n,
                      text: 'Naver 로그인',
                      color: Color(0xFF2DB400),
                      onPressed: () => {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String text,
    required Color color,
    Color textColor = Colors.white,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: FaIcon(icon, color: textColor),
      label: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final response = await http.post(Uri.parse(
        'http://localhost/members/login'),
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 성공'),
            backgroundColor: Colors.green
          ),
        );
        
        NavigationHelper.navigate(context, '/main', replacement: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이메일 또는 비밀번호가 올바르지 않습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그인에 실패했습니다 ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
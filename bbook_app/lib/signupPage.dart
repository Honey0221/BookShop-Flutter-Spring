import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'navigation_helper.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPage();
}

class _SignUpPage extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _verificationCode;
  String? _verificationToken;
  bool _isEmailVerified = true;
  String? _passwordMatchMessage;

  final TextStyle _errorStyle = TextStyle(
    color: Colors.red,
    fontWeight: FontWeight.bold,
    fontSize: 12,
  );
  
  final TextStyle _successStyle = TextStyle(
    color: Colors.green,
    fontWeight: FontWeight.bold,
    fontSize: 12,
  );

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordMatch);
    _passwordConfirmController.addListener(_checkPasswordMatch);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_checkPasswordMatch);
    _passwordConfirmController.removeListener(_checkPasswordMatch);
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _emailController.dispose();
    _verificationCodeController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('회원가입'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: '이메일',
                  hintText: '이메일을 입력해주세요',
                  errorStyle: _errorStyle,
                  suffixIcon: TextButton(
                    onPressed: _isEmailVerified ? null : _sendVerificationEmail,
                    child: Text(_isEmailVerified ? '인증완료' : '인증하기'),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력해주세요';
                  }
                  return null;
                },
              ),
              
              if (_isEmailVerified)
                Padding(
                  padding: EdgeInsets.only(top: 8, left: 12),
                  child: Text('이메일 인증이 완료되었습니다', style: _successStyle),
                ),
              SizedBox(height: 16),

              if (_verificationCode != null && !_isEmailVerified)
                TextFormField(
                  controller: _verificationCodeController,
                  decoration: InputDecoration(
                    labelText: '인증번호',
                    hintText: '인증번호 6자리를 입력해주세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorStyle: _errorStyle,
                    suffixIcon: TextButton(
                      onPressed: _verifyEmail,
                      child: Text('확인'),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '인증번호를 입력해주세요';
                    }
                    if (value.length != 6) {
                      return '6자리 숫자를 입력해주세요';
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
                  errorStyle: _errorStyle,
                  helperText: '8자 이상',
                  helperStyle: TextStyle(
                    fontSize: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력해주세요';
                  }
                  if (value.length < 8) {
                    return '비밀번호를 8자 이상으로 입력해주세요';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _passwordConfirmController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호 확인',
                  hintText: '비밀번호를 다시 입력해주세요',
                  errorStyle: _errorStyle,
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return '비밀번호가 일치하지 않습니다';
                  }
                  return null;
                },
              ),
              
              if (_passwordMatchMessage != null)
                Padding(
                  padding: EdgeInsets.only(top: 8, left: 12),
                  child: Text(
                    _passwordMatchMessage!,
                    style: _passwordMatchMessage == "비밀번호가 일치합니다" 
                        ? _successStyle 
                        : _errorStyle,
                  ),
                ),
              SizedBox(height: 16),

              TextFormField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: '닉네임',
                  hintText: '닉네임을 입력해주세요',
                  errorStyle: _errorStyle,
                  helperText: '2자 이상 10자 이하',
                  helperStyle: TextStyle(
                    fontSize: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '닉네임을 입력해주세요';
                  }
                  if (value.length < 2 || value.length > 10) {
                    return '닉네임을 2자 이상 10자 이하로 입력해주세요';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              ElevatedButton(
                onPressed: _signUp,
                child: Text('가입 신청'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              SizedBox(height: 24),

              Text('소셜 계정으로 가입하기', 
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),

              _buildSocialLoginButton(
                icon: FontAwesomeIcons.google,
                text: 'Google로 가입',
                color: Color(0xFFDD4B39),
                onPressed: () => {},
              ),
              SizedBox(height: 8),

              _buildSocialLoginButton(
                icon: FontAwesomeIcons.comment,
                text: 'Kakao로 가입',
                color: Color(0xFFFEE500),
                textColor: Colors.black87,
                onPressed: () => {},
              ),
              SizedBox(height: 8),

              _buildSocialLoginButton(
                icon: FontAwesomeIcons.n,
                text: 'Naver로 가입',
                color: Color(0xFF2DB400),
                onPressed: () => {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton({
    required IconData icon,
    required String text,
    required Color color,
    Color textColor = Colors.white,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: FaIcon(icon, color: textColor),
      label: Text(text, style: TextStyle(color: textColor)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onPressed,
    );
  }

  Future<void> _sendVerificationEmail() async {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('올바른 이메일 형식이 아닙니다')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost/members/emailCheck'),
        body: jsonEncode({'email': _emailController.text}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        
        setState(() {
          _verificationToken = responseBody['token'];
          _verificationCode = 'sent';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('인증번호가 발송되었습니다. 이메일을 확인해주세요.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('인증번호 발송에 실패했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyEmail() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost/members/verifyEmail'),
        body: jsonEncode({
          'code': _verificationCodeController.text,
          'token': _verificationToken,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _isEmailVerified = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이메일 인증이 완료되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('인증번호가 일치하지 않거나 만료되었습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('인증번호 확인에 실패했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _checkPasswordMatch() {
    final password = _passwordController.text;
    final confirm = _passwordConfirmController.text;

    setState(() {
      if (password.isEmpty || confirm.isEmpty) {
        _passwordMatchMessage = null;
      } else if (password == confirm) {
        _passwordMatchMessage = '비밀번호가 일치합니다';
      } else {
        _passwordMatchMessage = '비밀번호가 일치하지 않습니다';
      }
    });
  }

  Future<void> _signUp() async {
    // if (!_isEmailVerified) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('이메일 인증을 완료해주세요'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    //   return;
    // }

    if (!_formKey.currentState!.validate()) return;

    try {
      final response = await http.post(
        Uri.parse('http://localhost/members/signup'),
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
          'nickname': _nicknameController.text,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원가입이 완료되었습니다'),
            backgroundColor: Colors.green,
          ),
        );

        await NavigationHelper.navigate(
          context,
          '/members/login',
          replacement: true,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('회원가입에 실패했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
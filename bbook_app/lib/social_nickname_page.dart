import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'navigation_helper.dart';

class SocialNicknamePage extends StatefulWidget {
  const SocialNicknamePage({super.key});

  @override
  State<SocialNicknamePage> createState() => _SocialNicknamePage();
}

class _SocialNicknamePage extends State<SocialNicknamePage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('닉네임 설정'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: '닉네임',
                  hintText: '사용하실 닉네임을 입력해주세요',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '닉네임을 입력해주세요';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _setNickname,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('닉네임 설정'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setNickname() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('인증 정보가 없습니다');
      }

      final response = await http.post(
        Uri.parse('http://localhost/members/social/nickname'),
        body: jsonEncode({'nickname': _nicknameController.text}),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('auth_token', data['token']);        
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('닉네임 설정이 완료되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
      
      NavigationHelper.navigate(context, '/main', replacement: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('닉네임 설정에 실패했습니다'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
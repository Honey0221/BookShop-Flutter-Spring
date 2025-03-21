import 'package:flutter/material.dart';
import 'dart:async';
import 'navigation_helper.dart';

class LoadingPage extends StatefulWidget {
  final String? nextRoute;
  final Duration loadingDuration;
  final bool canGoBack;
  final bool isInitialLoading;

  const LoadingPage({
    this.nextRoute,
    this.loadingDuration = const Duration(seconds: 2),
    this.canGoBack = true,
    this.isInitialLoading = false,
    Key? key,
  }) : super(key: key);

  @override
  _LoadingPage createState() => _LoadingPage();
}

class _LoadingPage extends State<LoadingPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.nextRoute != null) {
      _timer = Timer(widget.loadingDuration, () {
        Navigator.of(context).pushReplacementNamed(widget.nextRoute!);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!widget.canGoBack) return false;
        
        _timer?.cancel();
        await NavigationHelper.goBack(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: null,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.book,
                size: 100,
                color: Color(0xFF76C97F),
              ),
              SizedBox(height: 20),
              Text(
                'Builders Book',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '당신의 일상에 특별한 이야기를 더합니다',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF76C97F))
              ),
            ],
          ),
        ),
      ),
    );
  }
}

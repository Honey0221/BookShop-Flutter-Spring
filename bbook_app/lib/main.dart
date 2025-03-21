import 'package:bbook_app/book_list_page.dart';
import 'package:bbook_app/cart_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'loadingPage.dart';
import 'loginPage.dart';
import 'signupPage.dart';
import 'social_nickname_page.dart';
import 'mainPage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Builders Book',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.notoSansTextTheme(
          Theme.of(context).textTheme,
        ),
        iconTheme: const IconThemeData(
          color: Colors.black87,
          size: 24.0,
        ),
      ),
      home: LoadingPage(
        nextRoute: '/main',
        loadingDuration: Duration(seconds: 2),
        isInitialLoading: true,
      ),
      onGenerateRoute: (settings) {
        print('Navigating to: ${settings.name}');
        
        if (settings.name == '/loading') {
          return MaterialPageRoute(
            builder:
                (context) =>
                    LoadingPage(nextRoute: settings.arguments as String?),
          );
        }

        if (settings.name != null && settings.name!.startsWith('/book-list/')) {
          final path = settings.name!.replaceFirst('/book-list/', '');
          final queryParamIndex = path.indexOf('?');

          String listType;
          Map<String, String>? queryParams;

          if (queryParamIndex > -1) {
            listType = path.substring(0, queryParamIndex);
            final queryString = path.substring(queryParamIndex + 1);
            queryParams = Uri.splitQueryString(queryString);
          } else {
            listType = path;
            queryParams = null;
          }

          return MaterialPageRoute(
            builder:
                (context) =>
                    BookListPage(listType: listType, queryParams: queryParams),
          );
        }

        Widget page;
        switch (settings.name) {
          case '/members/login':
            page = LoginPage();
            break;
          case '/members/signup':
            page = SignUpPage();
            break;
          case '/members/social/nickname':
            page = SocialNicknamePage();
            break;
          case '/book-list':
            page = BookListPage(listType: 'all', queryParams: null);
            break;
          case '/cart-list':
            page = CartPage();
            break;
          default:
            page = MainPage();
        }
        
        return MaterialPageRoute(builder: (context) => page);
      },
    );
  }
}
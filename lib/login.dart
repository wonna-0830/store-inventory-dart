import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart'; // supabase 전역 객체 불러오기

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController pwController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('userId');
    if (savedId != null) {
      // 자동 로그인 성공 → 다음 화면으로 이동
      _goToHome();
    }
  }

  Future<void> _login() async {
    final id = idController.text.trim();
    final pw = pwController.text.trim();

    if (id.isEmpty || pw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("아이디와 비밀번호를 입력하세요")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await supabase
          .from('user') // 테이블 이름 확인 (user 또는 users)
          .select()
          .eq('id', id)
          .eq('password', pw)
          .maybeSingle();

      if (response != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', id); // 자동 로그인용 저장

        _goToHome();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("로그인 실패: 아이디 또는 비밀번호가 틀렸습니다")));
      }
    } catch (e) {
      print("로그인 오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("오류 발생")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _goToHome() {
    Navigator.pushReplacementNamed(context, '/home'); // 홈 화면 라우트 연결 예정
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("로그인")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: idController, decoration: InputDecoration(labelText: '아이디')),
            TextField(controller: pwController, obscureText: true, decoration: InputDecoration(labelText: '비밀번호')),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(onPressed: _login, child: Text("로그인")),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: Text("회원가입 하러가기"),
            ),
          ],
        ),
      ),
    );
  }
}

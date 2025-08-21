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
    if (savedId != null && savedId.isNotEmpty) {
      // 자동 로그인 성공 → 다음 화면으로 이동
      _goToHome();
    }
  }

  Future<void> _login() async {
    final id = idController.text.trim();
    final pw = pwController.text.trim();

    if (id.isEmpty || pw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("아이디와 비밀번호를 입력하세요")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 테이블 직접 select() 금지. RPC('verify_user')만 호출
      final res = await supabase.rpc('verify_user', params: {
        'p_id': id,
        'p_password': pw,
      });

      // RPC 결과 파싱 (Supabase Dart는 보통 List<dynamic>로 반환)
      Map<String, dynamic>? row;
      if (res is List && res.isNotEmpty) {
        row = Map<String, dynamic>.from(res.first as Map);
      } else if (res is Map<String, dynamic>) {
        row = res;
      }

      if (row != null) {
        final userId   = (row['id'] ?? '') as String;
        final userName = (row['name'] ?? '') as String?;   // user 테이블에 name 컬럼이 있다면 저장
        final userStore= (row['store'] ?? '') as String?;
        final uid      = row['uid']?.toString();           // uid 컬럼이 있으면 저장

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);
        if (userName != null)  await prefs.setString('userName',  userName);
        if (userStore != null) await prefs.setString('userStore', userStore);
        if (uid != null)       await prefs.setString('uid', uid);

        // 디버그 로그
        print('verify_user row: $row');

        _goToHome();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("로그인 실패: 아이디/비밀번호를 확인하세요")),
        );
      }
    } catch (e) {
      print('로그인 RPC 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("오류가 발생했습니다")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _goToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("로그인")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: idController,
              decoration: const InputDecoration(labelText: '아이디'),
            ),
            TextField(
              controller: pwController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '비밀번호'),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _login, child: const Text("로그인")),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: const Text("회원가입 하러가기"),
            ),
          ],
        ),
      ),
    );
  }
}

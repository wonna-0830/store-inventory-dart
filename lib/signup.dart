import 'package:flutter/material.dart';
import 'main.dart'; // supabase 전역 객체

class SignupPage extends StatelessWidget {
  SignupPage({super.key});

  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController storeController = TextEditingController();

  Future<void> _register(BuildContext context) async {
    final id = idController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();
    final store = storeController.text.trim();

    if (id.isEmpty || password.isEmpty || name.isEmpty || store.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("모든 항목을 입력해주세요")),
      );
      return;
    }

    try {
      // 테이블 직접 insert() 금지. RPC('register_user')만 호출
      final res = await supabase.rpc('register_user', params: {
        'p_id': id,
        'p_password': password,
        'p_name': name,
        'p_store': store,
      });

      // 결과 파싱 (대개 List 형태)
      final ok = (res is List && res.isNotEmpty) || (res is Map && res.isNotEmpty);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("회원가입 완료!")),
        );
        Navigator.pop(context); // 로그인 화면으로
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("회원가입 실패: 관리자에게 문의하세요")),
        );
      }
    } catch (e) {
      // print('회원가입 RPC 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("오류가 발생했습니다")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '이름'),
            ),
            TextField(
              controller: idController,
              decoration: const InputDecoration(labelText: '아이디'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '비밀번호'),
            ),
            TextField(
              controller: storeController,
              decoration: const InputDecoration(labelText: '점포명'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _register(context),
              child: const Text('회원가입'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('로그인으로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}

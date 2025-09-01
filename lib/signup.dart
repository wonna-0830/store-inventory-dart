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
      final res = await supabase.rpc('register_user', params: {
        'p_id': id,
        'p_password': password,
        'p_name': name,
        'p_store': store,
      });

      // 현재 register_user 함수는 void라서 res == null 이면 성공
      if (res == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("회원가입 완료!")),
        );
        // 성공 시 로그인 페이지로 돌아가기
        Navigator.pop(context);
      } else if (res == 'DUPLICATE') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("이미 존재하는 아이디입니다.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("회원가입 실패: $res")),
        );
      }
    } catch (e, st) {
      print("❌ 회원가입 RPC 오류: $e");
      print("STACKTRACE: $st");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("오류: $e")),
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

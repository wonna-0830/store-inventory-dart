import 'package:flutter/material.dart';
import 'signup.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('로그인')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: '이메일'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
          decoration: InputDecoration(labelText: '비밀번호'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 로그인 처리 (나중에 연결!)
              },
              child: Text('로그인'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => SignupPage())
                );
              },
              child: Text('회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}

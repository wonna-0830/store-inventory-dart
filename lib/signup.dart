import 'package:flutter/material.dart';
import 'main.dart';
import 'package:uuid/uuid.dart';

class SignupPage extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController storeController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('회원가입')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: '이름'),
            ),
            TextField(
              controller: idController,
              decoration: InputDecoration(labelText: '아이디'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: '비밀번호'),
            ),
            TextField(
              controller: storeController,
              decoration: InputDecoration(labelText: '점포명'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                //회원가입 로직
                final id = idController.text.trim();
                final password = passwordController.text.trim();
                final name = nameController.text.trim();
                final store = storeController.text.trim();

                if (id.isEmpty || password.isEmpty || name.isEmpty || store.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("모든 항목을 입력해주세요")),
                  );
                  return;
                }


                try {
                  final existing = await supabase
                      .from('user')
                      .select()
                      .eq('id', id)
                      .maybeSingle();

                  if (existing != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("이미 존재하는 아이디입니다")),
                    );
                    return;
                  }

                  final uid = Uuid().v4();
                  await supabase.from('user').insert({
                    'uid': uid,
                    'id': id,
                    'password': password,
                    'name': name,
                    'store': store,
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("회원가입 완료!")),
                  );

                  Navigator.pop(context); // 로그인 페이지로 이동
                } catch (e) {
                  print("회원가입 오류: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("오류가 발생했습니다")),
                  );
                }
              },
              child: Text('회원가입'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('로그인으로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}

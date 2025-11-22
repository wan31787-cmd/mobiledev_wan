import 'package:flutter/material.dart';
import 'services/firestore_api.dart';
import 'main_mobile.dart';

class LoginPage extends StatefulWidget {
  final Function(String username)? onLoginSuccess;

  const LoginPage({super.key, this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  bool showPassword = false;
  bool acceptPolicy = false;

  void _showSnackBar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: success ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFB2DFDB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 6,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/logo.png', height: 100),
                    const SizedBox(height: 10),
                    Text(
                      isLogin
                          ? 'ยินดีต้อนรับกลับมา 💚\nขอให้วันนี้เป็นวันที่ดีนะ!'
                          : 'พร้อมจะเริ่มต้นใหม่แล้วใช่ไหม? 🌿\nสมัครสมาชิกกันเลย!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isLogin ? 'เข้าสู่ระบบ' : 'สมัครสมาชิก',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00796B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: 'ชื่อผู้ใช้',
                        prefixIcon: const Icon(Icons.person, color: Color(0xFF00796B)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: !showPassword,
                      decoration: InputDecoration(
                        labelText: 'รหัสผ่าน',
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFF00796B)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showPassword ? Icons.visibility : Icons.visibility_off,
                            color: const Color(0xFF00796B),
                          ),
                          onPressed: () {
                            setState(() {
                              showPassword = !showPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!isLogin)
                      Row(
                        children: [
                          Checkbox(
                            value: acceptPolicy,
                            activeColor: const Color(0xFF00796B),
                            onChanged: (value) {
                              setState(() {
                                acceptPolicy = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  acceptPolicy = !acceptPolicy;
                                });
                              },
                              child: const Text(
                                'ข้าพเจ้ายอมรับนโยบายความเป็นส่วนตัว',
                                style: TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00796B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isLoading
                            ? null
                            : () async {
                                setState(() => isLoading = true);

                                final username = usernameController.text.trim();
                                final password = passwordController.text.trim();

                                if (username.isEmpty || password.isEmpty) {
                                  _showSnackBar('กรุณากรอกชื่อผู้ใช้และรหัสผ่าน');
                                  setState(() => isLoading = false);
                                  return;
                                }

                                if (isLogin) {
                                  // 🔹 เข้าสู่ระบบ
                                  final users = await FirestoreAPI.getUsers();
                                  final match = users.firstWhere(
                                    (u) =>
                                        u['username'] == username &&
                                        u['password'] == password,
                                    orElse: () => <String, String>{},
                                  );

                                  if (match.isNotEmpty) {
                                    if (widget.onLoginSuccess != null) {
                                      widget.onLoginSuccess!(username);
                                    }
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MainMobile(username: username),
                                      ),
                                    );
                                  } else {
                                    _showSnackBar('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง');
                                  }
                                } else {
                                  // 🔹 สมัครสมาชิก
                                  if (!acceptPolicy) {
                                    _showSnackBar('กรุณายอมรับนโยบายก่อนสมัครสมาชิก');
                                    setState(() => isLoading = false);
                                    return;
                                  }

                                  final success = await FirestoreAPI.registerUser(username, password);

                                  if (success) {
                                    _showSnackBar('สมัครสมาชิกสำเร็จแล้ว', success: true);

                                    if (widget.onLoginSuccess != null) {
                                      widget.onLoginSuccess!(username);
                                    }

                                    setState(() {
                                      isLogin = true;
                                      acceptPolicy = false;
                                    });
                                  } else {
                                    _showSnackBar('ไม่สามารถสมัครสมาชิกได้ ลองอีกครั้ง');
                                  }
                                }

                                setState(() => isLoading = false);
                              },
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                isLogin ? 'เข้าสู่ระบบ' : 'สมัครสมาชิก',
                                style: const TextStyle(fontSize: 18, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() => isLogin = !isLogin);
                      },
                      child: Text(
                        isLogin
                            ? "ยังไม่มีบัญชีใช่ไหม? สมัครสมาชิก"
                            : "มีบัญชีอยู่แล้ว? เข้าสู่ระบบ",
                        style: const TextStyle(
                          color: Color(0xFF00796B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'firestore_api.dart';
import 'main_mobile.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  bool showPassword = false; // ปุ่มดู/ซ่อนรหัสผ่าน

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFB2DFDB)], // ขาวเขียวอ่อน
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
                    Text(
                      isLogin ? 'Login' : 'Create Account',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00796B), // เขียวเข้ม
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Color(0xFF00796B),
                        ),
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
                        labelText: 'Password',
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Color(0xFF00796B),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Color(0xFF00796B),
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
                    const SizedBox(height: 24),
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
                        onPressed:
                            isLoading
                                ? null
                                : () async {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  final username = usernameController.text;
                                  final password = passwordController.text;

                                  if (isLogin) {
                                    final users = await FirestoreAPI.getUsers();
                                    final match = users.any(
                                      (u) =>
                                          u['username'] == username &&
                                          u['password'] == password,
                                    );
                                    if (match) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => MainMobile(
                                                username: username,
                                              ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Invalid username/password',
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    await FirestoreAPI.registerUser(
                                      username,
                                      password,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Registered successfully',
                                        ),
                                      ),
                                    );
                                    setState(() {
                                      isLogin = true;
                                    });
                                  }
                                  setState(() {
                                    isLoading = false;
                                  });
                                },
                        child:
                            isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : Text(
                                  isLogin ? 'Login' : 'Register',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isLogin = !isLogin;
                        });
                      },
                      child: Text(
                        isLogin
                            ? "Don't have an account? Register"
                            : "Already have an account? Login",
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

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stok_takip/Giri%C5%9FEkranlar%C4%B1/KayitEkrani.dart';
import '../main.dart';
import 'package:stok_takip/Giri%C5%9FEkranlar%C4%B1/%C5%9EifremiUnuttum.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({Key? key}) : super(key: key);

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _checkSavedCredentials();
  }

  Future<void> _checkSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    final savedPassword = prefs.getString('password');
    final rememberMe = prefs.getBool('rememberMe') ?? false;
    final isLoggedOut = prefs.getBool('isLoggedOut') ?? false;

    if (isLoggedOut) {
      return;
    }

    if (rememberMe && savedEmail != null && savedPassword != null) {
      emailController.text = savedEmail;
      passwordController.text = savedPassword;
      setState(() {
        _rememberMe = true;
      });
      _signIn(savedEmail, savedPassword);
    }
  }

  Future<void> _saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('email', email);
      await prefs.setString('password', password);
      await prefs.setBool('rememberMe', true);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('rememberMe', false);
    }
  }

  Future<void> _signIn(String email, String password) async {
    // E-posta boş kontrolü
    if (email.isEmpty) {
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.fail,
        label: 'E-posta adresi boş bırakılamaz',
        backgroundColor: Colors.red,
        iconColor: Colors.white,
      );
      return;
    }

    // E-posta format kontrolü
    bool emailValid = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+"
    ).hasMatch(email);
    
    if (!emailValid) {
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.fail,
        label: 'Geçerli bir e-posta adresi giriniz',
        backgroundColor: Colors.red,
        iconColor: Colors.white,
      );
      return;
    }

    // Şifre boş kontrolü
    if (password.isEmpty) {
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.fail,
        label: 'Şifre boş bırakılamaz',
        backgroundColor: Colors.red,
        iconColor: Colors.white,
      );
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await _saveCredentials(email, password);
      }
      await prefs.setBool('isLoggedOut', false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Bu e-posta adresine ait hesap bulunamadı';
          break;
        case 'wrong-password':
          errorMessage = 'Hatalı şifre girdiniz';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz e-posta formatı';
          break;
        case 'user-disabled':
          errorMessage = 'Bu hesap devre dışı bırakılmış';
          break;
        case 'too-many-requests':
          errorMessage = 'Çok fazla başarısız giriş denemesi. Lütfen daha sonra tekrar deneyin';
          break;
        case 'invalid-credential':
          errorMessage = 'E-posta adresi veya şifre hatalı';
          break;
        default:
          errorMessage = 'Giriş yapılamadı. Lütfen bilgilerinizi kontrol edin.';
      }

      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.fail,
        label: errorMessage,
        backgroundColor: Colors.red,
        iconColor: Colors.white,
      );
    } catch (e) {
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.fail,
        label: 'Beklenmeyen bir hata oluştu',
        backgroundColor: Colors.red,
        iconColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize:22 ,color: Colors.white),
        title: const Text('Giriş Yap'),
      ),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 20.0,
            bottom: 20.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo kısmı
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                child: Center(
                  child: Image.asset(
                    'assets/StokMatik Logo4.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Form elemanları
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    style: TextStyle(color: Colors.white),
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color.fromRGBO(0, 163, 204, 100)),
                      ),
                      fillColor: Colors.black54,
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    style: TextStyle(color: Colors.white),
                    controller: passwordController,
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color.fromRGBO(0, 163, 204, 100)),
                      ),
                      fillColor: Colors.black54,
                      filled: true,
                      focusColor: Colors.white,
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (bool? value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            checkColor: Colors.white,
                            activeColor: Color.fromRGBO(0, 163, 204, 100),
                            side: BorderSide(color: Colors.white),
                          ),
                          Text(
                            'Beni Hatırla',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Şifremi Unuttum',
                          style: TextStyle(
                            color: Color.fromRGBO(0, 163, 204, 100),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _signIn(emailController.text, passwordController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color.fromRGBO(2, 135, 168, 100),
                      minimumSize: Size(double.infinity, 45),
                    ),
                    child: const Text(
                      'Giriş Yap',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const KayitEkrani()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.grey[800],
                      minimumSize: Size(double.infinity, 45),
                    ),
                    child: const Text(
                      'Kayıt Ol',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}

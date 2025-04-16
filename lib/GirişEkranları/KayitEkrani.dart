import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:flutter/services.dart';
import 'EmailVerificationScreen.dart';

class KayitEkrani extends StatefulWidget {
  const KayitEkrani({Key? key}) : super(key: key);

  @override
  State<KayitEkrani> createState() => _KayitEkraniState();
}

class _KayitEkraniState extends State<KayitEkrani> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController tcController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController companyTypeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  String _passwordStrength = '';

  // Sınıfın başına eklenecek kontrol fonksiyonları
  bool isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    ).hasMatch(email);
  }

  bool isStrongPassword(String password) {
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    return password.length >= 8 && 
           hasUppercase && 
           hasLowercase && 
           hasDigits && 
           hasSpecialCharacters;
  }

  // Ad-soyad için sadece harf kontrolü
  bool containsOnlyLetters(String text) {
    return RegExp(r'^[a-zA-ZğĞüÜşŞıİöÖçÇ\s]+$').hasMatch(text);
  }

  // TC için sadece sayı kontrolü
  bool containsOnlyNumbers(String text) {
    return RegExp(r'^[0-9]+$').hasMatch(text);
  }

  // Minimum bir harf kontrolü
  bool containsMinimumOneLetter(String text) {
    return RegExp(r'[a-zA-ZğĞüÜşŞıİöÖçÇ]').hasMatch(text);
  }

  // Şifre gücü kontrolü
  void checkPasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() => _passwordStrength = '');
    } else if (password.length < 6) {
      setState(() => _passwordStrength = 'Zayıf');
    } else if (password.length < 8) {
      setState(() => _passwordStrength = 'Orta');
    } else if (isStrongPassword(password)) {
      setState(() => _passwordStrength = 'Güçlü');
    } else {
      setState(() => _passwordStrength = 'Orta');
    }
  }

  // Şifre TextField'ı için renk belirleme
  Color getPasswordStrengthColor() {
    switch (_passwordStrength) {
      case 'Zayıf':
        return Colors.red;
      case 'Orta':
        return Colors.orange;
      case 'Güçlü':
        return Colors.green;
      default:
        return Color.fromRGBO(0, 163, 204, 100);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white), // Geri tuşunun rengini beyaz yapar
        backgroundColor: Colors.black,
        titleTextStyle: TextStyle(fontSize: 22,color: Colors.white),
        title: const Text('Kayıt Ol'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              //AD
              TextField(
                style: TextStyle(color: Colors.white),
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Ad',
                  labelStyle: const TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                  filled: false,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              //SOYAD
              TextField(
                style: TextStyle(color: Colors.white),
                controller: surnameController,
                decoration: InputDecoration(
                  labelText: 'Soyad',
                  labelStyle: const TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                  filled: false,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              //TC
              TextField(
                style: TextStyle(color: Colors.white),
                controller: tcController,
                maxLength: 11,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: InputDecoration(
                  labelText: 'TC Kimlik No',
                  labelStyle: const TextStyle(
                    color: Colors.white54,
                    fontFamily: 'Poppins',
                  ),
                  counterText: '',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color.fromRGBO(0, 163, 204, 100),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color.fromRGBO(0, 163, 204, 100),
                      width: 2,
                    ),
                  ),
                  fillColor: Colors.black54,
                  filled: true,
                ),
              ),

              const SizedBox(height: 16),

              //FİRMA ADI
              TextField(
                style: TextStyle(color: Colors.white),
                controller: companyNameController,
                decoration: InputDecoration(
                  labelText: 'Firma Adı',
                  labelStyle: const TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                  filled: false,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              //FİRMA TÜRÜ
              TextField(
                style: TextStyle(color: Colors.white),
                controller: companyTypeController,
                decoration: InputDecoration(
                  labelText: 'Firma Türü',
                  labelStyle: const TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                  filled: false,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              //E-POSTA
              TextField(
                style: TextStyle(color: Colors.white),
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  labelStyle: const TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                  filled: false,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              //ŞİFRE
              TextField(
                style: TextStyle(color: Colors.white),
                controller: passwordController,
                obscureText: !_passwordVisible,
                onChanged: (value) => checkPasswordStrength(value),
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  labelStyle: const TextStyle(
                    color: Colors.white54,
                    fontFamily: 'Poppins',
                  ),
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
                  helperText: _passwordStrength.isNotEmpty ? 'Şifre Gücü: $_passwordStrength' : null,
                  helperStyle: TextStyle(
                    color: getPasswordStrengthColor(),
                    fontFamily: 'Poppins',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: getPasswordStrengthColor(),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: getPasswordStrengthColor(),
                      width: 2,
                    ),
                  ),
                  fillColor: Colors.black54,
                  filled: true,
                ),
              ),

              const SizedBox(height: 16),

              //Şifre Doğrulama TextField'ı
              TextField(
                style: TextStyle(color: Colors.white),
                controller: confirmPasswordController,
                obscureText: !_confirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Şifre Tekrar',
                  labelStyle: const TextStyle(
                    color: Colors.white54,
                    fontFamily: 'Poppins',
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _confirmPasswordVisible = !_confirmPasswordVisible;
                      });
                    },
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color.fromRGBO(0, 163, 204, 100),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color.fromRGBO(0, 163, 204, 100),
                      width: 2,
                    ),
                  ),
                  fillColor: Colors.black54,
                  filled: true,
                ),
              ),

              const SizedBox(height: 16),

              //KAYIT OL
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color.fromRGBO(2, 135, 168, 100)
                ),
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      surnameController.text.isEmpty ||
                      tcController.text.isEmpty ||
                      companyNameController.text.isEmpty ||
                      companyTypeController.text.isEmpty ||
                      emailController.text.isEmpty ||
                      passwordController.text.isEmpty) {
                    IconSnackBar.show(
                      context,
                      label: "Lütfen tüm alanları doldurun.",
                      snackBarType: SnackBarType.alert,
                      iconColor: Colors.white,
                      backgroundColor: Colors.grey
                    );
                    return;
                  }

                  if (tcController.text.length != 11) {
                    IconSnackBar.show(
                      context,
                      label: "TC Kimlik No 11 haneli olmalıdır.",
                      snackBarType: SnackBarType.alert,
                      iconColor: Colors.white,
                      backgroundColor: Colors.red
                    );
                    return;
                  }

                  // E-posta kontrolü
                  if (!isValidEmail(emailController.text)) {
                    IconSnackBar.show(
                      context,
                      snackBarType: SnackBarType.alert,
                      label: 'Geçerli bir e-posta adresi giriniz',
                      backgroundColor: Colors.orange,
                      iconColor: Colors.white,
                    );
                    return;
                  }

                  // Şifre güçlülük kontrolü
                  if (!isStrongPassword(passwordController.text)) {
                    IconSnackBar.show(
                      context,
                      snackBarType: SnackBarType.alert,
                      label: 'Şifre en az 8 karakter olmalı ve büyük harf, küçük harf, rakam ve özel karakter içermelidir',
                      backgroundColor: Colors.orange,
                      iconColor: Colors.white,
                    );
                    return;
                  }

                  // Ad kontrolü
                  if (!containsOnlyLetters(nameController.text)) {
                    IconSnackBar.show(
                      context,
                      snackBarType: SnackBarType.fail,
                      label: 'Ad sadece harflerden oluşmalıdır',
                      backgroundColor: Colors.red,
                      iconColor: Colors.white,
                    );
                    return;
                  }

                  // Soyad kontrolü
                  if (!containsOnlyLetters(surnameController.text)) {
                    IconSnackBar.show(
                      context,
                      snackBarType: SnackBarType.fail,
                      label: 'Soyad sadece harflerden oluşmalıdır',
                      backgroundColor: Colors.red,
                      iconColor: Colors.white,
                    );
                    return;
                  }

                  // TC kontrolü
                  if (!containsOnlyNumbers(tcController.text)) {
                    IconSnackBar.show(
                      context,
                      snackBarType: SnackBarType.fail,
                      label: 'TC kimlik numarası sadece rakamlardan oluşmalıdır',
                      backgroundColor: Colors.red,
                      iconColor: Colors.white,
                    );
                    return;
                  }

                  // Firma adı kontrolü
                  if (!containsMinimumOneLetter(companyNameController.text)) {
                    IconSnackBar.show(
                      context,
                      snackBarType: SnackBarType.fail,
                      label: 'Firma adı en az bir harf içermelidir',
                      backgroundColor: Colors.red,
                      iconColor: Colors.white,
                    );
                    return;
                  }

                  // Firma türü kontrolü
                  if (!containsMinimumOneLetter(companyTypeController.text)) {
                    IconSnackBar.show(
                      context,
                      snackBarType: SnackBarType.fail,
                      label: 'Firma türü en az bir harf içermelidir',
                      backgroundColor: Colors.red,
                      iconColor: Colors.white,
                    );
                    return;
                  }

                  // Şifre eşleşme kontrolü
                  if (passwordController.text != confirmPasswordController.text) {
                    IconSnackBar.show(
                      context,
                      snackBarType: SnackBarType.fail,
                      label: 'Şifreler eşleşmiyor',
                      backgroundColor: Colors.red,
                      iconColor: Colors.white,
                    );
                    return;
                  }

                  try {
                    // Sadece Authentication'da kullanıcı oluştur
                    final userCredential = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                      email: emailController.text,
                      password: passwordController.text,
                    );

                    // Kullanıcı bilgilerini geçici olarak EmailVerificationScreen'e gönder
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmailVerificationScreen(
                          userData: {
                            'name': nameController.text,
                            'surname': surnameController.text,
                            'tc': tcController.text,
                            'companyName': companyNameController.text,
                            'companyType': companyTypeController.text,
                            'email': emailController.text,
                          },
                        ),
                      ),
                    );
                  } catch (e) {
                    print('Kayıt hatası: $e');
                    IconSnackBar.show(
                      context,
                      snackBarType: SnackBarType.fail,
                      label: 'Kayıt başarısız, lütfen tekrar deneyin.',
                      backgroundColor: Colors.red,
                      iconColor: Colors.white,
                    );
                  }
                },
                child: const Text('Kayıt Ol'),
              ),
            ],
          ),
        ),
      ),backgroundColor: Colors.black,
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  Future<void> _resetPassword() async {
    try {
      // Boş kontrol
      if (_emailController.text.isEmpty) {
        IconSnackBar.show(
          context,
          snackBarType: SnackBarType.fail,
          label: 'E-posta adresi boş bırakılamaz',
          backgroundColor: Colors.red,
          iconColor: Colors.white,
        );
        return;
      }

      // E-posta formatı kontrolü
      bool emailValid = RegExp(
        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'
      ).hasMatch(_emailController.text);
      
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

      // Şifre sıfırlama maili gönder
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.success,
        label: 'Şifre yenileme bağlantısı e-posta adresinize gönderildi',
        backgroundColor: Colors.green,
        iconColor: Colors.white,
      );

      Navigator.pop(context);
      
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Geçerli bir e-posta formatı giriniz';
          break;
        case 'user-not-found':
          errorMessage = 'Bu e-posta adresi sistemde kayıtlı değil';
          break;
        case 'too-many-requests':
          errorMessage = 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin';
          break;
        default:
          errorMessage = 'Bir hata oluştu, lütfen tekrar deneyin';
          print('Firebase Auth Error Code: ${e.code}'); // Hata kodunu yazdır
      }
      
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.fail,
        label: errorMessage,
        backgroundColor: Colors.red,
        iconColor: Colors.white,
      );
    } catch (e) {
      print('Hata: $e');
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.fail,
        label: 'Bir hata oluştu, lütfen tekrar deneyin',
        backgroundColor: Colors.red,
        iconColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        title: Text(
          'Şifremi Unuttum',
          style: TextStyle(
            fontFamily: 'FunnelDisplay',
            color: Colors.white,
            fontSize: 24,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedTextKit(
                animatedTexts: [
                  TyperAnimatedText(
                    'Hesabının şifresini mi unuttun?',
                    textAlign: TextAlign.center,
                    speed: Duration(milliseconds: 50),
                    textStyle: TextStyle(
                      fontFamily: 'FunnelDisplay',
                      color: Colors.white,
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                isRepeatingAnimation: false,
              ),
              SizedBox(height: 50),
              Text(
                "Mailini gir ve şifreni yenile!",
                style: TextStyle(
                  fontFamily: 'FunnelDisplay',
                  color: Colors.white,
                  fontSize: 17,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Eğer sistemde kayıtlı değilseniz önce kayıt olun.",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.grey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                style: TextStyle(
                  fontFamily: 'FunnelDisplay',
                  color: Colors.white,
                ),
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  labelStyle: TextStyle(
                    fontFamily: 'FunnelDisplay',
                    color: Colors.white54,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                    BorderSide(color: Color.fromRGBO(0, 163, 204, 100)),
                  ),
                  fillColor: Colors.black54,
                  filled: true,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(0, 163, 204, 70),
                ),
                onPressed: _resetPassword,
                child: Text(
                  'Şifremi Sıfırla',
                  style: TextStyle(
                    fontFamily: 'FunnelDisplay',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}







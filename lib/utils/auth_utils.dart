import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import '../GirişEkranları/GirisEkrani.dart';

class AuthUtils {
  static Future<void> signOut(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Çıkış yapıldığını belirten flag'i set et
      await prefs.setBool('isLoggedOut', true);
      
      // Diğer verileri temizle
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('rememberMe', false);

      // Firebase'den çıkış yap
      await FirebaseAuth.instance.signOut();
      
      // Ana giriş ekranına yönlendir
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const GirisEkrani()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.fail,
        label: 'Çıkış yapılırken bir hata oluştu',
        backgroundColor: Colors.red,
        iconColor: Colors.white,
      );
    }
  }
} 
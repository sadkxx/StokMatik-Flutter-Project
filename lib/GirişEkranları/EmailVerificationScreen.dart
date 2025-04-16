import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'GirisEkrani.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

class EmailVerificationScreen extends StatefulWidget {
  final Map<String, dynamic> userData; // Kullanıcı bilgilerini al

  const EmailVerificationScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isEmailVerified = false;
  bool showVerificationSuccess = false;
  Timer? timer;
  Timer? countdownTimer;
  bool canResendEmail = false;
  int remainingSeconds = 60;

  @override
  void initState() {
    super.initState();
    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;

    if (!isEmailVerified) {
      sendVerificationEmail();

      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    countdownTimer?.cancel();
    super.dispose();
  }

  // Geri sayım başlatma fonksiyonu
  void startCountdown() {
    setState(() => remainingSeconds = 60);
    countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (remainingSeconds > 0) {
          setState(() => remainingSeconds--);
        } else {
          countdownTimer?.cancel();
        }
      },
    );
  }

  Future<void> checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser!.reload();
    final user = FirebaseAuth.instance.currentUser;

    setState(() {
      isEmailVerified = user?.emailVerified ?? false;
    });

    if (isEmailVerified) {
      timer?.cancel();
      
      try {
        // Önce animasyonu göster
        setState(() {
          showVerificationSuccess = true;
        });

        // E-posta doğrulandıktan sonra Firestore'a kaydet
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .set({
          ...widget.userData,
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': true,
        });

        // 3 saniye bekle ve ana sayfaya yönlendir
        await Future.delayed(const Duration(seconds: 3));
        
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } catch (e) {
        print('Veri kaydetme hatası: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı bilgileri kaydedilirken bir hata oluştu'),
          ),
        );
      }
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();

      setState(() => canResendEmail = false);
      startCountdown(); // Geri sayımı başlat
      await Future.delayed(const Duration(seconds: 60));
      setState(() => canResendEmail = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) => showVerificationSuccess
      ? Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lottie animasyonu
                Lottie.network(
                  'https://assets5.lottiefiles.com/packages/lf20_jbrw3hcz.json', // E-posta onay animasyonu
                  width: 300,
                  height: 300,
                  repeat: false,
                ),
                const SizedBox(height: 24),
                const Text(
                  'E-posta Doğrulandı!',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Giriş yapılıyor...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        )
      : Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'E-posta Doğrulama',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'FunnelDisplay',
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Doğrulama e-postası gönderildi!',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Lütfen e-posta adresinizi kontrol edin ve doğrulama bağlantısına tıklayın.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(2, 135, 168, 100),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      icon: Icon(Icons.email, size: 32, color: Colors.white),
                      label: const Text(
                        'Tekrar Gönder',
                        style: TextStyle(
                          fontSize: 24,
                          fontFamily: 'Poppins',
                          color: Colors.white,
                        ),
                      ),
                      onPressed: canResendEmail ? sendVerificationEmail : null,
                    ),
                    if (!canResendEmail)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$remainingSeconds s',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text(
                    'İptal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  onPressed: () async {
                    timer?.cancel();
                    final user = FirebaseAuth.instance.currentUser;
                    
                    try {
                      // Kullanıcıyı Authentication'dan sil
                      await user?.delete();
                    } catch (e) {
                      print('Kullanıcı silme hatası: $e');
                    }

                    if (!mounted) return;
                    
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const GirisEkrani()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
} 
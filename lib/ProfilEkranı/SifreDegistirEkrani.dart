import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SifreDegistirEkrani extends StatefulWidget {
  const SifreDegistirEkrani({Key? key}) : super(key: key);

  @override
  _SifreDegistirEkraniState createState() => _SifreDegistirEkraniState();
}

class _SifreDegistirEkraniState extends State<SifreDegistirEkrani> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        title: const Text(
          'Şifre Değiştir',
          style: TextStyle(color: Colors.white, fontFamily: 'FunnelDisplay', fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.grey[900]?.withOpacity(0.9),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                      decoration: InputDecoration(
                        labelText: 'Mevcut Şifre',
                        labelStyle: TextStyle(
                          color: Color.fromRGBO(0, 163, 204, 100),
                          fontFamily: 'Poppins',
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                        ),
                        fillColor: Colors.black54,
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                      decoration: InputDecoration(
                        labelText: 'Yeni Şifre',
                        labelStyle: TextStyle(
                          color: Color.fromRGBO(0, 163, 204, 100),
                          fontFamily: 'Poppins',
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                        ),
                        fillColor: Colors.black54,
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                      decoration: InputDecoration(
                        labelText: 'Yeni Şifre Tekrar',
                        labelStyle: TextStyle(
                          color: Color.fromRGBO(0, 163, 204, 100),
                          fontFamily: 'Poppins',
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                        ),
                        fillColor: Colors.black54,
                        filled: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_newPasswordController.text != _confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yeni şifreler eşleşmiyor')),
                  );
                  return;
                }

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  final credential = EmailAuthProvider.credential(
                    email: user?.email ?? '',
                    password: _currentPasswordController.text,
                  );

                  await user?.reauthenticateWithCredential(credential);
                  await user?.updatePassword(_newPasswordController.text);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Şifre başarıyla güncellendi')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Şifre güncellenirken bir hata oluştu')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(0, 163, 204, 100),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Şifreyi Güncelle',
                style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
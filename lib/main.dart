import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'GirişEkranları/GirisEkrani.dart';
import 'ProfilEkranı/ProfilEkrani.dart';
import 'SatışRaporuEkranı/SatisRaporuEkrani.dart';
import 'SatışEkranı/SatisEkrani.dart';
import 'ÜrünEkranları/UrunlerEkrani.dart';
import 'MüşterilerEkranı/MusterilerEkrani.dart';
import 'ÜrünEkranları/UrunEkleEkrani.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/auth_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stok Takip',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const GirisEkrani(),
    );
  }
}


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String companyName = '';

  @override
  void initState() {
    super.initState();
    _getCompanyName();
  }

  Future<void> _getCompanyName() async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        setState(() {
          companyName = userData['companyName'] ?? '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> options = [
      {
        'title': 'Satış Yap',
        'icon': Icons.shopping_cart,
        'page': const SatisEkrani()
      },
      {
        'title': 'Ürünler',
        'icon': Icons.list_alt,
        'page': const UrunlerEkrani()
      },
      {
        'title': 'Ürün Ekle',
        'icon': Icons.add,
        'page': const UrunEkleEkrani()
      },
      {
        'title': 'Müşteriler',
        'icon': Icons.people,
        'page': const MusterilerEkrani()
      },
      {
        'title': 'Satış Raporu',
        'icon': Icons.bar_chart,
        'page': const SatisRaporuEkrani()
      },
      {
        'title': 'Profilim',
        'icon': Icons.person,
        'page': const ProfilEkrani()
      },
    ];

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        titleTextStyle: const TextStyle(fontSize: 22, color: Colors.white),
        title: Text('StokMatik',style: TextStyle(fontFamily: 'Poppins'),),
        actions: [
          const Text(
            "Çıkış",
            style: TextStyle(fontFamily: 'Poppins',fontSize: 18, color: Colors.white60),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => AuthUtils.signOut(context),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color.fromRGBO(2, 135, 168, 100), Colors.black],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final userData = snapshot.data!.data() as Map<String, dynamic>;
                        final companyName = userData['companyName'] ?? '';
                        return Column(
                          children: [
                            AnimatedTextKit(
                              animatedTexts: [
                                TyperAnimatedText(
                                  companyName,
                                  textAlign: TextAlign.center,
                                  speed: Duration(milliseconds: 100),
                                  textStyle: const TextStyle(
                                    fontFamily: 'FunnelDisplay',
                                    color: Colors.white,
                                    fontSize: 35,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                              isRepeatingAnimation: false,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'StokMatik\'e Hoş Geldiniz',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                fontFamily: 'Poppins',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      }
                      return CircularProgressIndicator(color: Colors.white);
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                itemCount: options.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final option = options[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => option['page'],
                        ),
                      );
                    },
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const RadialGradient(
                            radius: 2,
                            colors: [Color.fromRGBO(2, 135, 168, 100), Colors.black],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              option['icon'],
                              size: 64,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              option['title'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontFamily: 'FunnelDisplay',
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
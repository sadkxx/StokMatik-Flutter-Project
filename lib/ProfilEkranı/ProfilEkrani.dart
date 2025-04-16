import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../GirişEkranları/GirisEkrani.dart';
import 'SifreDegistirEkrani.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/auth_utils.dart';

class ProfilEkrani extends StatefulWidget {
  const ProfilEkrani({Key? key}) : super(key: key);

  @override
  _ProfilEkraniState createState() => _ProfilEkraniState();
}

class _ProfilEkraniState extends State<ProfilEkrani> {
  bool isEditing = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController tcController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController companyTypeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        title: const Text(
          'Profilim',
          style: TextStyle(color: Colors.white, fontFamily: 'FunnelDisplay', fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: userId == null
            ? const Center(child: Text('Kullanıcı girişi yapılmamış', style: TextStyle(color: Colors.white)))
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Bir hata oluştu', style: TextStyle(color: Colors.white)));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text('Kullanıcı bilgileri bulunamadı', style: TextStyle(color: Colors.white)));
                  }

                  final userData = snapshot.data!.data() as Map<String, dynamic>;

                  // Controller'ları güncelle
                  if (!isEditing) {
                    nameController.text = userData['name'] ?? '';
                    surnameController.text = userData['surname'] ?? '';
                    tcController.text = userData['tc'] ?? '';
                    companyNameController.text = userData['companyName'] ?? '';
                    companyTypeController.text = userData['companyType'] ?? '';
                    emailController.text = userData['email'] ?? '';
                  }

                  return SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        children: [
                          Card(
                            color: Colors.grey[900]?.withOpacity(0.9),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  _buildTextField('Ad', nameController),
                                  const Divider(color: Colors.white24),
                                  _buildTextField('Soyad', surnameController),
                                  const Divider(color: Colors.white24),
                                  _buildTextField('T.C. Kimlik No', tcController),
                                  const Divider(color: Colors.white24),
                                  _buildTextField('Firma Adı', companyNameController),
                                  const Divider(color: Colors.white24),
                                  _buildTextField('Firma Türü', companyTypeController),
                                  const Divider(color: Colors.white24),
                                  _buildTextField('E-posta', emailController, enabled: false),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (!isEditing)
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  isEditing = true;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromRGBO(0, 163, 204, 100),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Profili Düzenle',
                                      style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins')),
                                  SizedBox(width: 8),
                                  Icon(Icons.edit, color: Colors.white),
                                ],
                              ),
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        isEditing = false;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      minimumSize: const Size(double.infinity, 50),
                                    ),
                                    child: const Text('İptal Et',
                                        style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        // TC kontrolü yapalım
                                        if (!await _checkTcExists(tcController.text)) {
                                          return;
                                        }
              
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(userId)
                                            .update({
                                          'name': nameController.text,
                                          'surname': surnameController.text,
                                          'tc': tcController.text,
                                          'companyName': companyNameController.text,
                                          'companyType': companyTypeController.text,
                                        });
                                        
                                        setState(() {
                                          isEditing = false;
                                        });
                                        
                                        IconSnackBar.show(
                                          context,
                                          snackBarType: SnackBarType.success,
                                          label: 'Profil başarıyla güncellendi.',
                                          backgroundColor: Colors.green,
                                          iconColor: Colors.white,
                                        );
                                      } catch (e) {
                                        IconSnackBar.show(
                                          context,
                                          snackBarType: SnackBarType.fail,
                                          label: 'Profil güncellenirken bir hata oluştu',
                                          backgroundColor: Colors.red,
                                          iconColor: Colors.white,
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      minimumSize: const Size(double.infinity, 50),
                                    ),
                                    child: const Text('Kaydet',
                                        style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SifreDegistirEkrani()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromRGBO(0, 163, 204, 100),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Şifremi Değiştir',
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins')),
                                SizedBox(width: 8),
                                Icon(Icons.lock_outline, color: Colors.white),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => AuthUtils.signOut(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Çıkış Yap',
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins')),
                                SizedBox(width: 8),
                                Icon(Icons.exit_to_app, color: Colors.white),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        readOnly: !isEditing || !enabled,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins'),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 14,
            color: Color.fromRGBO(0, 163, 204, 100),
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Future<bool> _checkTcExists(String tc) async {
    if (tc.length != 11) {
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.fail,
        label: 'TC Kimlik numarası 11 haneli olmalıdır',
        backgroundColor: Colors.red,
        iconColor: Colors.white,
      );
      return false;
    }

    // Mevcut kullanıcının TC'sini kontrol etmeyelim
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('tc', isEqualTo: tc)
        .get();

    // Eğer bulunan TC mevcut kullanıcıya ait değilse
    if (querySnapshot.docs.isNotEmpty) {
      for (var doc in querySnapshot.docs) {
        if (doc.id != currentUserId) {
          IconSnackBar.show(
            context,
            snackBarType: SnackBarType.fail,
            label: 'Bu TC Kimlik numarası başka bir kullanıcı tarafından kullanılıyor',
            backgroundColor: Colors.red,
            iconColor: Colors.white,
          );
          return false;
        }
      }
    }
    
    return true;
  }
}

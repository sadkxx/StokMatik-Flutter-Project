import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MusterilerEkrani extends StatefulWidget {
  const MusterilerEkrani({Key? key}) : super(key: key);

  @override
  _MusterilerEkraniState createState() => _MusterilerEkraniState();
}

class _MusterilerEkraniState extends State<MusterilerEkrani> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String searchText = "";

  bool containsLetter(String text) {
    return RegExp(r'[a-zA-ZğĞüÜşŞıİöÖçÇ]').hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController surnameController = TextEditingController();
    final TextEditingController iletisimController = TextEditingController();

    Future<void> _showAddCustomerDialog() async {
      String phoneNumber = '';
      bool isValidPhone = false;
      nameController.clear();
      surnameController.clear();

      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.black,
            shadowColor: Color.fromRGBO(0, 163, 204, 1),
            title: const Text(
                style: TextStyle(color: Colors.white,fontFamily: 'Poppins',fontWeight: FontWeight.bold),
                'Yeni Müşteri Ekle'
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Ad',
                      labelStyle: TextStyle(color: Colors.white54,fontFamily: 'Poppins',fontWeight: FontWeight.bold),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Color.fromRGBO(0, 163, 204, 100),
                            width: 2
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Color.fromRGBO(0, 163, 204, 100),
                              width: 2
                          )
                      ),
                      fillColor: Colors.black54,
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),
                    controller: surnameController,
                    decoration: InputDecoration(
                      labelText: 'Soyad',
                      labelStyle: TextStyle(color: Colors.white54,fontFamily: 'Poppins',fontWeight: FontWeight.bold),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Color.fromRGBO(0, 163, 204, 100),
                            width: 2
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Color.fromRGBO(0, 163, 204, 100),
                              width: 2
                          )
                      ),
                      fillColor: Colors.black54,
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StatefulBuilder(
                    builder: (BuildContext context, StateSetter setModalState) {
                      return IntlPhoneField(
                        style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                        controller: iletisimController,
                        decoration: InputDecoration(
                          labelText: 'İletişim',
                          labelStyle: TextStyle(
                            color: Colors.white54,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Color.fromRGBO(0, 163, 204, 100),
                              width: 2
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Color.fromRGBO(0, 163, 204, 100),
                              width: 2
                            )
                          ),
                          fillColor: Colors.black54,
                          filled: true,
                        ),
                        dropdownTextStyle: TextStyle(color: Colors.white),
                        dropdownIcon: Icon(Icons.arrow_drop_down, color: Colors.white),
                        initialCountryCode: 'TR',
                        keyboardType: TextInputType.number,
                        invalidNumberMessage: 'Geçersiz telefon numarası',
                        onChanged: (phone) {
                          setModalState(() {
                            phoneNumber = phone.completeNumber;
                            isValidPhone = phone.isValidNumber() && 
                                phone.number.length >= 10 && 
                                RegExp(r'^[0-9]+$').hasMatch(phone.number);
                          });
                        },
                        validator: (value) {
                          if (value == null || !isValidPhone) {
                            return 'Lütfen geçerli bir telefon numarası girin';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                    style: TextStyle(color: Colors.redAccent,fontFamily: 'Poppins',fontWeight: FontWeight.bold),
                    'İptal'
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (!containsLetter(nameController.text)) {
                    IconSnackBar.show(
                      context,
                      snackBarType: SnackBarType.fail,
                      label: 'İsim en az bir harf içermelidir',
                      backgroundColor: Colors.red,
                      iconColor: Colors.white,
                    );
                    return;
                  }

                  if (!containsLetter(surnameController.text)) {
                    IconSnackBar.show(
                      context,
                      snackBarType: SnackBarType.fail,
                      label: 'Soyisim en az bir harf içermelidir',
                      backgroundColor: Colors.red,
                      iconColor: Colors.white,
                    );
                    return;
                  }

                  if (nameController.text.isEmpty || surnameController.text.isEmpty || !isValidPhone) {
                    IconSnackBar.show(
                      context,
                      snackBarType: SnackBarType.fail,
                      label: 'Lütfen tüm alanları doldurun',
                      backgroundColor: Colors.red,
                      iconColor: Colors.white,
                    );
                    return;
                  }

                  try {
                    final String? userId = FirebaseAuth.instance.currentUser?.uid;
                    if (userId == null) return;

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('customers')
                        .add({
                      'name': nameController.text,
                      'surname': surnameController.text,
                      'iletisim': phoneNumber,
                    });
                    
                    Navigator.pop(context);
                    nameController.clear();
                    surnameController.clear();
                    
                    IconSnackBar.show(
                      context,
                      snackBarType: SnackBarType.success,
                      label: 'Müşteri başarıyla eklendi',
                      backgroundColor: Colors.green,
                      iconColor: Colors.white,
                    );
                  } catch (e) {
                    IconSnackBar.show(
                      context,
                      snackBarType: SnackBarType.fail,
                      label: 'Müşteri eklenirken bir hata oluştu',
                      backgroundColor: Colors.red,
                      iconColor: Colors.white,
                    );
                  }
                },
                child: const Text(
                  'Ekle',
                  style: TextStyle(
                    color: Colors.green,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    Future<void> _showEditCustomerDialog(DocumentSnapshot customer) async {
      final data = customer.data() as Map<String, dynamic>;
      
      String phoneNumber = data['iletisim'] ?? '';
      if (phoneNumber.startsWith('+90')) {
        phoneNumber = phoneNumber.substring(3);
      }
      
      nameController.text = data['name'] ?? '';
      surnameController.text = data['surname'] ?? '';
      iletisimController.text = phoneNumber;
      bool isValidPhone = true;

      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.black,
            shadowColor: Color.fromRGBO(0, 163, 204, 1),
            title: const Text(
              'Müşteri Düzenle',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    style: TextStyle(color: Colors.white),
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Ad',
                      labelStyle: TextStyle(color: Colors.white54,fontFamily: 'Poppins',fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Color.fromRGBO(0, 163, 204, 100), width: 2)
                      ),
                      fillColor: Colors.black54,
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),
                    controller: surnameController,
                    decoration: InputDecoration(
                      labelText: 'Soyad',
                      labelStyle: TextStyle(color: Colors.white54,fontFamily: 'Poppins',fontWeight: FontWeight.bold),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Color.fromRGBO(0, 163, 204, 100), width: 2)
                      ),
                      fillColor: Colors.black54,
                      filled: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  IntlPhoneField(
                    style: TextStyle(color: Colors.white),
                    controller: iletisimController,
                    initialValue: phoneNumber,
                    initialCountryCode: 'TR',
                    decoration: InputDecoration(
                      labelText: 'İletişim',
                      labelStyle: TextStyle(
                        color: Colors.white54,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color.fromRGBO(0, 163, 204, 100),
                          width: 2
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color.fromRGBO(0, 163, 204, 100),
                          width: 2
                        )
                      ),
                      fillColor: Colors.black54,
                      filled: true,
                    ),
                    onChanged: (phone) {
                      phoneNumber = phone.completeNumber;
                    },
                    onCountryChanged: (country) {
                      iletisimController.clear();
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Lütfen geçerli bir telefon numarası girin';
                      }
                      return null;
                    },
                    onSaved: (phone) {
                      if (phone != null) {
                        isValidPhone = true;
                        phoneNumber = phone.completeNumber;
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                    style: TextStyle(color: Colors.redAccent,fontFamily: 'Poppins',fontWeight: FontWeight.bold),
                    'İptal'
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (!containsLetter(nameController.text)) {
                    IconSnackBar.show(
                      context,
                      snackBarType: SnackBarType.fail,
                      label: 'İsim en az bir harf içermelidir',
                      backgroundColor: Colors.red,
                      iconColor: Colors.white,
                    );
                    return;
                  }

                  if (!containsLetter(surnameController.text)) {
                    IconSnackBar.show(
                      context,
                      snackBarType: SnackBarType.fail,
                      label: 'Soyisim en az bir harf içermelidir',
                      backgroundColor: Colors.red,
                      iconColor: Colors.white,
                    );
                    return;
                  }

                  if (nameController.text.isEmpty || surnameController.text.isEmpty || !isValidPhone) {
                    IconSnackBar.show(
                      context,
                      snackBarType: SnackBarType.fail,
                      label: 'Lütfen tüm alanları doldurun',
                      backgroundColor: Colors.red,
                      iconColor: Colors.white,
                    );
                    return;
                  }

                  try {
                    final String? userId = FirebaseAuth.instance.currentUser?.uid;
                    if (userId == null) return;

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('customers')
                        .doc(customer.id)
                        .update({
                      'name': nameController.text,
                      'surname': surnameController.text,
                      'iletisim': phoneNumber,
                    });
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Müşteri düzenlenirken bir hata oluştu')),
                    );
                  }
                },
                child: const Text(
                    style: TextStyle(color: Colors.green,fontFamily: 'Poppins',fontWeight: FontWeight.bold),
                    'Kaydet'
                ),
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        title: AnimatedCrossFade(
          duration: const Duration(microseconds: 1),
          firstChild: const Text(
            'Müşteriler',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'FunnelDisplay',
              fontWeight: FontWeight.bold
            ),
          ),
          secondChild: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            decoration: const InputDecoration(
              hintText: 'Müşteri ara...',
              hintStyle: TextStyle(color: Colors.white54, fontFamily: 'Poppins'),
              border: InputBorder.none,
            ),
            onChanged: (value) {
              setState(() {
                searchText = value;
              });
            },
          ),
          crossFadeState: _isSearching 
              ? CrossFadeState.showSecond 
              : CrossFadeState.showFirst,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  searchText = "";
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromRGBO(0, 163, 204 , 100),
        onPressed: _showAddCustomerDialog,
        child: const Icon(Icons.add,color: Colors.white,),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('customers')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Hiç müşteri bulunamadı.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          var customers = snapshot.data!.docs;

          // Arama filtresini uygula
          if (searchText.isNotEmpty) {
            customers = customers.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final musteriAdi = '${data['name']} ${data['surname']}'.toLowerCase();
              final telefon = data['iletisim'].toString().toLowerCase();
              final searchLower = searchText.toLowerCase();
              
              return musteriAdi.contains(searchLower) || 
                     telefon.contains(searchLower);
            }).toList();
          }

          return ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return Dismissible(
                key: Key(customer.id),
                direction: DismissDirection.endToStart, // Sadece sağdan sola kaydırma
                background: Container(
                  color: Colors.black,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 30),
                  child: const Icon(Icons.delete, color: Colors.red),
                  foregroundDecoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.red,
                          width: 5.0,
                    ),
                        borderRadius: BorderRadius.circular(10),
                  ),
                ),
                confirmDismiss: (direction) async {
                  // Kullanıcıdan onay almak için dialog göster
                  final bool? result = await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.black,
                        shadowColor: Colors.white,
                        title: const Text(
                          'Müşteriyi Sil',
                          style: TextStyle(color: Colors.white,fontFamily: 'Poppins',fontWeight: FontWeight.bold),
                        ),
                        content: const Text(
                          'Bu müşteriyi silmek istediğinize emin misiniz?',
                          style: TextStyle(color: Colors.white70,fontFamily: 'Poppins'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text(
                              'Hayır',
                              style: TextStyle(color: Colors.green,fontFamily: 'Poppins',fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              'Evet',
                              style: TextStyle(color: Colors.red,fontFamily: 'Poppins',fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                  return result ?? false; // Kullanıcı `Hayır` derse false döner
                },
                onDismissed: (direction) async {
                  try {
                    final String? userId = FirebaseAuth.instance.currentUser?.uid;
                    if (userId == null) return;

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('customers')
                        .doc(customer.id)
                        .delete();

                    IconSnackBar.show(
                      context,
                      snackBarType: SnackBarType.success,
                      label: 'Müşteri Silindi.',
                    );
                  } catch (e) {
                    IconSnackBar.show(
                      context,
                      snackBarType: SnackBarType.fail,
                      label: 'Silme işlemi sırasında bir hata oluştu',
                    );
                  }
                },
                child: Card(
                  color: Colors.black,
                  shadowColor: Colors.white,
                  child: ListTile(
                    title: Text(
                      '${customer['name']} ${customer['surname']}',
                      style: const TextStyle(color: Colors.white,fontFamily: 'Poppins'),
                    ),
                    subtitle: Text(
                      'İletişim: ${customer['iletisim']}',
                      style: const TextStyle(color: Color.fromRGBO(0, 163, 204, 70),fontFamily: 'Poppins'),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () {
                        _showEditCustomerDialog(customer);
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class UrunDuzenleEkrani extends StatefulWidget {
  const UrunDuzenleEkrani({Key? key}) : super(key: key);

  @override
  State<UrunDuzenleEkrani> createState() => _UrunDuzenleEkraniState();
}

class _UrunDuzenleEkraniState extends State<UrunDuzenleEkrani> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  String searchQuery = '';
  bool isSearchVisible = false;

  // Ürün adı kontrolü için fonksiyon ekleyelim
  bool containsLetter(String text) {
    return RegExp(r'[a-zA-ZğĞüÜşŞıİöÖçÇ]').hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        title: !isSearchVisible
            ? const Text(
                'Ürünleri Düzenle',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'FunnelDisplay',
                  fontWeight: FontWeight.bold,
                ),
              )
            : TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ürün Ara...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
              ),
        actions: [
          IconButton(
            icon: Icon(
              isSearchVisible ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                isSearchVisible = !isSearchVisible;
                if (!isSearchVisible) {
                  searchQuery = '';
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUserId)
                  .collection('urunler')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                var products = snapshot.data!.docs;
                
                // Arama filtresini uygula
                if (searchQuery.isNotEmpty) {
                  products = products.where((product) {
                    final data = product.data() as Map<String, dynamic>;
                    final urunAdi = data['urunadi']?.toString().toLowerCase() ?? '';
                    final tur = data['tur']?.toString().toLowerCase() ?? '';
                    final barkod = data['barkod']?.toString() ?? '';
                    
                    return urunAdi.contains(searchQuery) || 
                           tur.contains(searchQuery) ||
                           barkod.contains(searchQuery);
                  }).toList();
                }

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final data = product.data() as Map<String, dynamic>;
                    
                    final TextEditingController nameController =
                        TextEditingController(text: data['urunadi']);
                    final TextEditingController stockController =
                        TextEditingController(text: data['stok'].toString());
                    final TextEditingController priceController =
                        TextEditingController(text: data['fiyat'].toString());
                    String? selectedProduct = data['tur'];

                    return Card(
                      color: Colors.black,
                      shadowColor: Colors.white,
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          collapsedIconColor: Colors.white,
                          iconColor: Color.fromRGBO(0, 163, 204, 100),
                          title: Text(
                            data['urunadi'],
                            style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                          ),
                          subtitle: Text(
                            'Tür: ${data['tur']} | Stok: ${data['stok']} | Fiyat: ${data['fiyat']}₺',
                            style: TextStyle(color: Colors.white60, fontFamily: 'Poppins'),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Column(
                                children: [
                                  TextField(
                                    style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),
                                    controller: nameController,
                                    decoration: InputDecoration(
                                      labelText: 'Ürün Adı',
                                      labelStyle: TextStyle(color: Colors.white,fontFamily: 'Poppins',fontWeight: FontWeight.bold),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Color.fromRGBO(0, 163, 204, 100),width: 2),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Color.fromRGBO(0, 163, 204 , 100),width: 2),
                                      ),
                                      fillColor: Colors.black,
                                      filled: true,
                                      focusColor: Colors.white,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                    value: selectedProduct,
                                    items: <String>['Yiyecek', 'İçecek', 'Giyim', 'Kozmetik', 'Aksesuar', 'Kitap', 'Kırtasiye/Ofis', 'Oyuncak']
                                        .map((String value) => DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(style:
                                      TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.normal,
                                          fontFamily: 'Poppins')
                                      ,value),

                                    ))
                                        .toList(),
                                    onChanged: (value) {
                                      selectedProduct = value;
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Ürün Türü',
                                      labelStyle: TextStyle(
                                        color: Colors.white,
                                          fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold
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
                                    dropdownColor: Colors.grey,
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),
                                    controller: stockController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Stok Miktarı',
                                      labelStyle: TextStyle(color: Colors.white,fontFamily: 'Poppins',fontWeight: FontWeight.bold),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Color.fromRGBO(0, 163, 204, 100),width: 2),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Color.fromRGBO(0, 163, 204, 100),width: 2),
                                      ),
                                      fillColor: Colors.black,
                                      filled: true,
                                      focusColor: Colors.white,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),
                                    controller: priceController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Fiyat',
                                      labelStyle: TextStyle(color: Colors.white,fontFamily: 'Poppins',fontWeight: FontWeight.bold),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Color.fromRGBO(0, 163, 204, 100),width: 2),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Color.fromRGBO(0, 163, 204 , 100),width: 2),
                                      ),
                                      fillColor: Colors.black,
                                      filled: true,
                                      focusColor: Colors.white,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color.fromRGBO(0, 163, 204, 100),
                                    ),
                                    onPressed: () async {
                                      if (!containsLetter(nameController.text)) {
                                        IconSnackBar.show(
                                          context,
                                          snackBarType: SnackBarType.fail,
                                          label: 'Ürün adı en az bir harf içermelidir',
                                          backgroundColor: Colors.red,
                                          iconColor: Colors.white,
                                        );
                                        return;
                                      }

                                      if (int.parse(stockController.text) <= 0) {
                                        IconSnackBar.show(
                                          context,
                                          snackBarType: SnackBarType.fail,
                                          label: 'Stok miktarı 0\'dan büyük olmalıdır',
                                          backgroundColor: Colors.red,
                                          iconColor: Colors.white,
                                        );
                                        return;
                                      }

                                      if (nameController.text.isEmpty ||
                                          stockController.text.isEmpty ||
                                          priceController.text.isEmpty ||
                                          selectedProduct == null) {
                                        IconSnackBar.show(
                                          context,
                                          snackBarType: SnackBarType.alert,
                                          label: 'Lütfen tüm alanları doldurun',
                                          backgroundColor: Colors.grey,
                                          iconColor: Colors.white,
                                        );
                                        return;
                                      }

                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(currentUserId)
                                            .collection('urunler')
                                            .doc(product.id)
                                            .update({
                                          'urunadi': nameController.text.toLowerCase(),
                                          'tur': selectedProduct,
                                          'stok': int.parse(stockController.text),
                                          'fiyat': double.parse(priceController.text),
                                        });

                                        IconSnackBar.show(
                                          context,
                                          snackBarType: SnackBarType.success,
                                          label: 'Ürün başarıyla güncellendi',
                                          backgroundColor: Colors.green,
                                          iconColor: Colors.white,
                                        );
                                      } catch (e) {
                                        print('Hata: $e');
                                        IconSnackBar.show(
                                          context,
                                          snackBarType: SnackBarType.fail,
                                          label: 'Güncelleme sırasında hata oluştu',
                                          backgroundColor: Colors.red,
                                          iconColor: Colors.white,
                                        );
                                      }
                                    },
                                    child: const Text(
                                      'Kaydet',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

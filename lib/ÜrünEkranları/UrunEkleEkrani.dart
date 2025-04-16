import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';


class UrunEkleEkrani extends StatefulWidget {
  const UrunEkleEkrani({Key? key}) : super(key: key);

  @override
  _UrunEkleEkraniState createState() => _UrunEkleEkraniState();
}

class _UrunEkleEkraniState extends State<UrunEkleEkrani> {
  String? selectedProduct;
  final TextEditingController barkodController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  // Ürün adı kontrolü için fonksiyon
  bool containsLetter(String text) {
    return RegExp(r'[a-zA-ZğĞüÜşŞıİöÖçÇ]').hasMatch(text);
  }

  Future<String> handleSubmit() async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 'Oturum açık değil';

    if (barkodController.text.isEmpty ||
        nameController.text.isEmpty ||
        selectedProduct == null ||
        stockController.text.isEmpty ||
        priceController.text.isEmpty) {
      return 'Lütfen tüm alanları doldurunuz.';
    }

    if (barkodController.text.length != 13) {
      return 'Barkod 13 haneli olmalıdır.';
    }

    // Ürün adı kontrolü
    if (!containsLetter(nameController.text)) {
      return 'Ürün adı en az bir harf içermelidir';
    }

    // Stok kontrolü
    if (int.parse(stockController.text) <= 0) {
      return 'Stok miktarı 0\'dan büyük olmalıdır';
    }

    try {
      // Kullanıcının kendi ürünleri içinde arama yap
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('urunler')
          .where('urunadi', isEqualTo: nameController.text.toUpperCase())
          .get();

      if (query.docs.isNotEmpty) {
        return 'Bu ürün zaten mevcut.';
      }

      // Barkod kontrolü
      QuerySnapshot barkodQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('urunler')
          .where('barkod', isEqualTo: int.parse(barkodController.text))
          .get();

      if (barkodQuery.docs.isNotEmpty) {
        return 'Bu barkod zaten mevcut.';
      }

      // Ürünü kullanıcının koleksiyonuna ekle
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('urunler')
          .add({
        'urunadi': nameController.text.toUpperCase(),
        'tur': selectedProduct,
        'stok': int.parse(stockController.text),
        'fiyat': double.parse(priceController.text),
        'barkod': int.parse(barkodController.text),
      });

      // Alanları temizle
      setState(() {
        nameController.clear();
        stockController.clear();
        priceController.clear();
        barkodController.clear();
        selectedProduct = null;
      });

      return 'success';
    } catch (e) {
      return 'Ürün eklenirken bir hata oluştu.';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        title: const Text(
          'Ürün Ekle',
          style: TextStyle(color: Colors.white,fontFamily: 'FunnelDisplay',fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barkod alanı
            TextField(
              controller: barkodController,
              maxLength: 13,
              onChanged: (value) {
                if (value.length > 13) {
                  HapticFeedback.mediumImpact();
                  barkodController.text = value.substring(0, 13);
                  barkodController.selection = TextSelection.fromPosition(
                    TextPosition(offset: 13),
                  );
                }
              },
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Barkod',
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
              ),
              style: const TextStyle(color: Colors.white,fontFamily: 'Poppins'),
            ),

            // Ürün adı alanı
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Ürün Adı',
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
              ),
              style: const TextStyle(color: Colors.white,fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 16),

            // Stok miktarı alanı
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Stok Miktarı',
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
              ),
              style: const TextStyle(color: Colors.white,fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 16),

            // Fiyat alanı
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Fiyat',
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
              ),
              style: const TextStyle(color: Colors.white,fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 16),

            // Kategori seçimi
            DropdownButtonFormField<String>(
              value: selectedProduct,
              decoration: InputDecoration(
                labelText: 'Kategori',
                labelStyle: const TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
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
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: ['Yiyecek', 'İçecek', 'Giyim', 'Kozmetik', 'Aksesuar', 'Kitap', 'Kırtasiye/Ofis', 'Oyuncak']
                  .map(
                    (category) => DropdownMenuItem(
                  value: category,
                  child: Text(category,style: TextStyle(fontSize: 16,color: Colors.white),),
                ),
              )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedProduct = value;
                });
              },
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),

            // Animasyonlu buton
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(0, 163, 204, 100),
                textStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Colors.white
                ),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                String result = await handleSubmit();

                if (result == 'success') {
                  IconSnackBar.show(
                    context,
                    snackBarType: SnackBarType.success,
                    label: 'Ürün başarıyla eklendi.',
                    backgroundColor: Colors.green,
                    iconColor: Colors.white,
                  );
                } else if (result == 'Lütfen tüm alanları doldurunuz.') {
                  IconSnackBar.show(
                    context,
                    snackBarType: SnackBarType.alert,
                    label: result,
                    backgroundColor: Colors.grey,
                    iconColor: Colors.white,
                  );
                } else if (result == 'Barkod 13 haneli olmalıdır.') {
                  IconSnackBar.show(
                    context,
                    snackBarType: SnackBarType.alert,
                    label: result,
                    backgroundColor: Colors.orange,
                    iconColor: Colors.white,
                  );
                } else {
                  IconSnackBar.show(
                    context,
                    snackBarType: SnackBarType.fail,
                    label: result,
                    backgroundColor: Colors.red,
                    iconColor: Colors.white,
                  );
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ürünü Kaydet',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins')),
                  SizedBox(width: 8),
                  Icon(Icons.save, color: Colors.white),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}
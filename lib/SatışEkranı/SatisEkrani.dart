import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';


class SatisEkrani extends StatefulWidget {
  const SatisEkrani({Key? key}) : super(key: key);

  @override
  State<SatisEkrani> createState() => _SatisEkraniState();
}

class _SatisEkraniState extends State<SatisEkrani> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  String? selectedProduct;
  String? selectedCustomer;
  final TextEditingController miktarController = TextEditingController(text: "0");
  double toplamFiyat = 0.0;
  double birimFiyat = 0.0;
  List<Map<String, dynamic>> sepet = [];
  double toplamTutar = 0.0;



  @override
  void initState() {
    super.initState();

    // Miktar girişini kontrol ederek toplam fiyatı güncelle
    miktarController.addListener(() {
      if (miktarController.text.isEmpty) {
        setState(() {
          toplamFiyat = 0.0;
        });
      } else {
        final miktar = int.tryParse(miktarController.text) ?? 0;
        setState(() {
          toplamFiyat = birimFiyat * miktar;
        });
      }
    });

    // Miktar alanına tıklandığında 0 değerini temizlemek için listener
    miktarController.addListener(() {
      if (miktarController.text == "0") {
        miktarController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: miktarController.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    miktarController.dispose();
    super.dispose();
  }

  // Satış yapıldığında veriyi kaydetme işlemi için
  Future<void> satisKaydet(Map<String, dynamic> satisVerisi) async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('satisRaporu')
          .add(satisVerisi);
    }
  }

  // Sepete ürün ekleme fonksiyonu
  void sepeteEkle(String urunId, Map<String, dynamic> urunData, int miktar) {
    // Miktar kontrolü
    if (miktar <= 0) {
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.fail,
        label: 'Miktar 0\'dan büyük olmalıdır',
        backgroundColor: Colors.red,
        iconColor: Colors.white,
      );
      return;
    }

    // Stok kontrolü
    int mevcutStok = urunData['stok'] ?? 0;
    if (miktar > mevcutStok) {
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.fail,
        label: 'Yetersiz stok! Mevcut stok: $mevcutStok',
        backgroundColor: Colors.red,
        iconColor: Colors.white,
      );
      return;
    }

    setState(() {
      // Sepette aynı ürün var mı kontrol et
      int sepetIndex = sepet.indexWhere((item) => item['urunId'] == urunId);
      
      if (sepetIndex != -1) {
        // Ürün sepette varsa, miktarı güncelle
        int yeniMiktar = sepet[sepetIndex]['miktar'] + miktar;
        
        // Toplam miktar stok miktarını geçmemeli
        if (yeniMiktar > mevcutStok) {
          IconSnackBar.show(
            context,
            snackBarType: SnackBarType.fail,
            label: 'Yetersiz stok! Sepetteki toplam miktar stok miktarını geçemez',
            backgroundColor: Colors.red,
            iconColor: Colors.white,
          );
          return;
        }
        
        sepet[sepetIndex]['miktar'] = yeniMiktar;
        sepet[sepetIndex]['toplamFiyat'] = urunData['fiyat'] * yeniMiktar;
      } else {
        // Ürün sepette yoksa, yeni ekle
        sepet.add({
          'urunId': urunId,
          'urunAdi': urunData['urunadi'],
          'birimFiyat': urunData['fiyat'],
          'miktar': miktar,
          'toplamFiyat': urunData['fiyat'] * miktar,
          'tur': urunData['tur'],
        });
      }
      
      toplamTutar = sepet.fold(0, (sum, item) => sum + item['toplamFiyat']);
    });
  }

  // Sepetten ürün çıkarma fonksiyonu
  void sepettenCikar(int index) {
    setState(() {
      sepet.removeAt(index);
      toplamTutar = sepet.fold(0, (sum, item) => sum + item['toplamFiyat']);
    });
  }

  // Toplu satış yapma fonksiyonu
  Future<void> topluSatisYap() async {
    if (sepet.isEmpty) {
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.alert,
        label: 'Lütfen sepete ürün ekleyin',
        backgroundColor: Colors.grey,
        iconColor: Colors.white,
      );
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      final String satisId = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('satisRaporu')
          .doc()
          .id;

      Map<String, dynamic>? customerData;
      
      // Eğer müşteri seçilmişse ve müşterisiz satış değilse, müşteri bilgilerini al
      if (selectedCustomer != null && selectedCustomer != 'musteri_yok') {
        final customerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('customers')
            .doc(selectedCustomer)
            .get();

        if (customerDoc.exists) {
          customerData = customerDoc.data()!;
        }
      }

      // Her ürün için stok kontrolü ve güncelleme
      for (var item in sepet) {
        final urunDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('urunler')
            .doc(item['urunId'])
            .get();

        if (!urunDoc.exists) continue;

        final currentStock = urunDoc.data()!['stok'] as int;
        if (currentStock < item['miktar']) {
          IconSnackBar.show(
            context,
            snackBarType: SnackBarType.alert,
            label: '${item['urunAdi']} için yeterli stok yok',
            backgroundColor: Colors.orange,
            iconColor: Colors.white,
          );
          return;
        }

        // Stok güncelleme
        batch.update(urunDoc.reference, {
          'stok': currentStock - item['miktar'],
        });

        // Satış kaydı oluştur
        batch.set(
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .collection('satisRaporu')
              .doc(),
          {
            'satisId': satisId,
            'urunAdi': item['urunAdi'],
            'miktar': item['miktar'],
            'birimfiyat': item['birimFiyat'],
            'toplamfiyat': item['toplamFiyat'],
            'tarih': FieldValue.serverTimestamp(),
            'tur': item['tur'],
            'musteriAd': customerData?['name'] ?? 'Müşterisiz Satış',
            'musteriSoyad': customerData?['surname'] ?? '',
            'toplamSepetTutari': toplamTutar,
            'sepetUrunSayisi': sepet.length,
          },
        );
      }

      // Tüm işlemleri gerçekleştir
      await batch.commit();

      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.success,
        label: 'Satış başarıyla tamamlandı',
        backgroundColor: Colors.green,
        iconColor: Colors.white,
      );

      // Sepeti temizle
      setState(() {
        sepet.clear();
        toplamTutar = 0;
        selectedCustomer = null;
        selectedProduct = null;
      });

    } catch (e) {
      print('Hata: $e');
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.fail,
        label: 'Satış yapılırken hata oluştu',
        backgroundColor: Colors.red,
        iconColor: Colors.white,
      );
    }
  }

  Color _getStockColor(dynamic stock) {
    int stockValue = stock is int ? stock : 0;
    
    if (stockValue <= 10) {
      return Colors.red; // Kritik stok
    } else if (stockValue <= 20) {
      return Colors.yellow; // Düşük stok
    } else {
      return Colors.green; // Yeterli stok
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
          'Satış Yap',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'FunnelDisplay',
            color: Colors.white
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.barcode_reader),
            onPressed: () {
              IconSnackBar.show(
                context,
                snackBarType: SnackBarType.alert,
                label: 'Barkod tarama özelliği yakında aktif edilecektir.',
                backgroundColor: Color.fromRGBO(0, 163, 204, 1),
                iconColor: Colors.white,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Üst kısım (Ürün, Müşteri seçimi ve Miktar)
              Container(
                height: MediaQuery.of(context).size.height * 0.35, // Ekranın %35'i
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Ürün seçimi
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUserId)
                            .collection('urunler')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }

                          final products = snapshot.data!.docs;
                          return DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Ürün Seçin',
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
                                  color: Color.fromRGBO(0, 163, 204, 100),
                                  width: 2,
                                ),
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
                            ),
                            dropdownColor: Colors.grey[900],
                            value: selectedProduct,
                            items: products.map((product) {
                              final data = product.data() as Map<String, dynamic>;
                              return DropdownMenuItem<String>(
                                value: product.id,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Ürün adı - Sol
                                      SizedBox(
                                        width: 150,
                                        child: Text(
                                          '${data['urunadi']}',
                                          style: TextStyle(
                                            color: Colors.cyan,
                                            fontFamily: 'Poppins',
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Fiyat - Orta
                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          '${data['fiyat']} ₺',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Poppins',
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      // Stok - Sağ
                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          'Stok: ${data['stok']}',
                                          style: TextStyle(
                                            color: _getStockColor(data['stok']),
                                            fontFamily: 'Poppins',
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedProduct = value;
                                if (selectedProduct != null) {
                                  final selectedProductData = products.firstWhere(
                                    (product) => product.id == selectedProduct,
                                  );
                                  final data = selectedProductData.data() as Map<String, dynamic>;
                                  birimFiyat = data['fiyat'] ?? 0.0;
                                  final miktar = int.tryParse(miktarController.text) ?? 0;
                                  toplamFiyat = birimFiyat * miktar;
                                }
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Müşteri seçimi
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUserId)
                            .collection('customers')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }

                          final customers = snapshot.data!.docs;
                          return DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Müşteri Seçin',
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
                                  color: Color.fromRGBO(0, 163, 204, 100),
                                  width: 2,
                                ),
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
                            ),
                            dropdownColor: Colors.grey[900],
                            value: selectedCustomer,
                            items: [
                              // Müşterisiz satış seçeneği
                              DropdownMenuItem(
                                value: 'musteri_yok',
                                child: Text(
                                  'Müşterisiz Satış',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange, // Farklı renk ile belirginleştirme
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Mevcut müşteri listesi
                              ...customers.map((customer) {
                                final data = customer.data() as Map<String, dynamic>;
                                return DropdownMenuItem(
                                  value: customer.id,
                                  child: Text(
                                    '${data['name']} ${data['surname']}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedCustomer = value;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Mevcut miktar girişi ve sepete ekle butonu
                      TextField(
                        controller: miktarController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        onTap: () {
                          if (miktarController.text == "0") {
                            miktarController.clear();
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Miktar',
                          labelStyle: const TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
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
                        onChanged: (value) {
                          setState(() {
                            if (value.isEmpty) {
                              miktarController.text = "0";
                              miktarController.selection = TextSelection.fromPosition(
                                TextPosition(offset: miktarController.text.length),
                              );
                            }
                            final miktar = int.tryParse(value) ?? 0;
                            toplamFiyat = birimFiyat * miktar;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(0, 163, 204, 100),
                          minimumSize: Size(double.infinity, 50),
                        ),
                        onPressed: () async {
                          if (selectedProduct == null) {
                            IconSnackBar.show(
                              context,
                              snackBarType: SnackBarType.fail,
                              label: 'Lütfen bir ürün seçin',
                              backgroundColor: Colors.red,
                              iconColor: Colors.white,
                            );
                            return;
                          }

                          int miktar = int.tryParse(miktarController.text) ?? 0;
                          if (miktar <= 0) {
                            IconSnackBar.show(
                              context,
                              snackBarType: SnackBarType.fail,
                              label: 'Miktar 0\'dan büyük olmalıdır',
                              backgroundColor: Colors.red,
                              iconColor: Colors.white,
                            );
                            return;
                          }

                          final productDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(currentUserId)
                              .collection('urunler')
                              .doc(selectedProduct)
                              .get();

                          if (productDoc.exists) {
                            final productData = productDoc.data()!;
                            sepeteEkle(
                              selectedProduct!,
                              productData,
                              miktar,
                            );
                            miktarController.clear();
                            setState(() {
                              selectedProduct = null;
                            });
                          }
                        },
                        child: Text(
                          'Sepete Ekle',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Sepet kısmı
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color.fromRGBO(0, 163, 204, 100),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Sepet başlığı ve toplam
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sepet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              'Toplam: ₺${toplamTutar.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(color: Color.fromRGBO(0, 163, 204, 100)),
                      Expanded(
                        child: ListView.builder(
                          itemCount: sepet.length,
                          itemBuilder: (context, index) {
                            final item = sepet[index];
                            return ListTile(
                              title: Text(
                                item['urunAdi'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              subtitle: Text(
                                '${item['miktar']} adet x ₺${item['birimFiyat']} = ₺${item['toplamFiyat']}',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () => sepettenCikar(index),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Satış tamamla butonu
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  onPressed: sepet.isEmpty ? null : topluSatisYap,
                  child: Text(
                    'Satışı Tamamla',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 16,
                    ),
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



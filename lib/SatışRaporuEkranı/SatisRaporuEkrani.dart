import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum SiralamaKriteri {
  tarihYeni,
  tarihEski,
  fiyatArtanSirada,
  fiyatAzalanSirada,
  musteriAdi
}

class FiltreOptions {
  String? selectedTur;
  String? musteriAdi;
  DateTime? baslangicTarihi;
  DateTime? bitisTarihi;
  double? minFiyat;
  double? maxFiyat;
}

class SatisRaporuEkrani extends StatefulWidget {
  const SatisRaporuEkrani({Key? key}) : super(key: key);

  @override
  State<SatisRaporuEkrani> createState() => _SatisRaporuEkraniState();
}

class _SatisRaporuEkraniState extends State<SatisRaporuEkrani> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  SiralamaKriteri _aktifSiralama = SiralamaKriteri.tarihYeni;
  FiltreOptions _filtreOptions = FiltreOptions();
  final TextEditingController _minFiyatController = TextEditingController();
  final TextEditingController _maxFiyatController = TextEditingController();
  final TextEditingController _musteriAdiController = TextEditingController();

  String tarihFormatlama(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
    return formattedDate; // Örnek çıktı: 2024-12-23 14:04:06
  }

  Future<void> _showDetailDialog(
      BuildContext context, Map<String, dynamic> data, String tarih) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shadowColor: Color.fromRGBO(0, 163, 204, 1),
          title: const Text(style: TextStyle(color: Colors.white,fontFamily: 'Poppins',fontWeight: FontWeight.bold),'Sipariş Detayları'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 5),
                Text(style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),"Müşteri: ${data['musteriAd']} ${data['musteriSoyad']}"),
                SizedBox(height: 5),
                Divider(height:  5),
                SizedBox(height: 5),
                Text(style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),'Ürün Adı: ${data['urunAdi']}'),
                SizedBox(height: 5),
                Divider(height:  5),
                SizedBox(height: 5),
                Text(style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),'Tür: ${data['tur']}'),
                SizedBox(height: 5),
                Divider(height:  5),
                SizedBox(height: 5),
                Text(style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),'Miktar: ${data['miktar']}'),
                SizedBox(height: 5),
                Divider(height:  5),
                SizedBox(height: 5),
                Text(style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),'Birim Fiyat: ${data['birimfiyat']}₺'),
                SizedBox(height: 5),
                Divider(height:  5),
                SizedBox(height: 5),
                Text(style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),'Tarih: $tarih'),
                SizedBox(height: 5),
                Divider(height:  5),
                SizedBox(height: 5),
                Text(style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),'Toplam Fiyat: ${data['toplamfiyat']}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(style: TextStyle(color: Color.fromRGBO(0, 163, 204, 10)),'Kapat'),
            ),
          ],
        );
      },
    );
  }

  // Satışları gruplamak için yardımcı fonksiyon
  Map<String, List<DocumentSnapshot>> gruplanmisSatislar(List<DocumentSnapshot> satislar) {
    Map<String, List<DocumentSnapshot>> gruplar = {};
    
    for (var satis in satislar) {
      final data = satis.data() as Map<String, dynamic>;
      final satisId = data['satisId']?.toString() ?? '';
      
      if (satisId.isNotEmpty) {
        if (!gruplar.containsKey(satisId)) {
          gruplar[satisId] = [];
        }
        gruplar[satisId]!.add(satis);
      }
    }
    
    return gruplar;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        title: const Text(
          'Satış Raporu',
          style: TextStyle(color: Colors.white, fontFamily: 'FunnelDisplay', fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Filtre ve Sıralama Butonları
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.black,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Container(
                            color: Colors.black,
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: Icon(Icons.person, color: Colors.blue),
                                    title: TextField(
                                      controller: _musteriAdiController,
                                      style: TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: 'Müşteri Adı',
                                        hintStyle: TextStyle(color: Colors.white54),
                                      ),
                                    ),
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.calendar_today, color: Colors.green),
                                    title: Text('Tarih Aralığı Seç', style: TextStyle(color: Colors.white)),
                                    onTap: () async {
                                      DateTimeRange? dateRange = await showDateRangePicker(
                                        context: context,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime.now(),
                                        builder: (context, child) {
                                          return Theme(
                                            data: ThemeData.dark().copyWith(
                                              colorScheme: ColorScheme.dark(
                                                primary: Color.fromRGBO(0, 163, 204, 100),
                                                onPrimary: Colors.white,
                                                surface: Colors.black,
                                                onSurface: Colors.white,
                                                secondary: Color.fromRGBO(0, 163, 204, 100),
                                                onSecondary: Colors.white,
                                                background: Colors.black,
                                              ),
                                              dialogBackgroundColor: Colors.black,
                                              appBarTheme: AppBarTheme(
                                                backgroundColor: Colors.black,
                                                iconTheme: IconThemeData(color: Colors.white),
                                                titleTextStyle: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                              textButtonTheme: TextButtonThemeData(
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Color.fromRGBO(0, 163, 204, 100),
                                                  textStyle: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              datePickerTheme: DatePickerThemeData(
                                                backgroundColor: Colors.black,
                                                headerBackgroundColor: Colors.black,
                                                dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
                                                  if (states.contains(MaterialState.selected)) {
                                                    return Color.fromRGBO(0, 163, 204, 100);
                                                  }
                                                  return Colors.transparent;
                                                }),
                                                dayForegroundColor: MaterialStateProperty.resolveWith((states) {
                                                  if (states.contains(MaterialState.selected)) {
                                                    return Colors.white;
                                                  }
                                                  return Colors.white;
                                                }),
                                                yearBackgroundColor: MaterialStateProperty.resolveWith((states) {
                                                  if (states.contains(MaterialState.selected)) {
                                                    return Color.fromRGBO(0, 163, 204, 100);
                                                  }
                                                  return Colors.transparent;
                                                }),
                                                yearForegroundColor: MaterialStateProperty.resolveWith((states) {
                                                  if (states.contains(MaterialState.selected)) {
                                                    return Colors.white;
                                                  }
                                                  return Colors.white;
                                                }),
                                                todayBorder: BorderSide(color: Color.fromRGBO(0, 163, 204, 100), width: 2),
                                                dayOverlayColor: MaterialStateProperty.resolveWith((states) {
                                                  if (states.contains(MaterialState.selected)) {
                                                    return Color.fromRGBO(0, 163, 204, 50);
                                                  }
                                                  return Color.fromRGBO(0, 163, 204, 20);
                                                }),
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (dateRange != null) {
                                        setState(() {
                                          _filtreOptions.baslangicTarihi = dateRange.start;
                                          _filtreOptions.bitisTarihi = dateRange.end;
                                        });
                                      }
                                    },
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.attach_money, color: Colors.amber),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _minFiyatController,
                                            keyboardType: TextInputType.number,
                                            style: TextStyle(color: Colors.white),
                                            decoration: InputDecoration(
                                              hintText: 'Min Fiyat',
                                              hintStyle: TextStyle(color: Colors.white54),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: _maxFiyatController,
                                            keyboardType: TextInputType.number,
                                            style: TextStyle(color: Colors.white),
                                            decoration: InputDecoration(
                                              hintText: 'Max Fiyat',
                                              hintStyle: TextStyle(color: Colors.white54),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.category, color: Colors.purple),
                                    title: Text('Türe Göre', style: TextStyle(color: Colors.white)),
                                    onTap: () {
                                      // Tür seçim modalını göster
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (context) {
                                          return Container(
                                            color: Colors.black,
                                            child: StreamBuilder<QuerySnapshot>(
                                              stream: FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(currentUserId)
                                                  .collection('satisRaporu')
                                                  .snapshots(),
                                              builder: (context, snapshot) {
                                                if (!snapshot.hasData) {
                                                  return Center(child: CircularProgressIndicator());
                                                }
                                                Set<String> turler = snapshot.data!.docs
                                                    .map((doc) => doc['tur'] as String)
                                                    .toSet();
                                                return ListView(
                                                  shrinkWrap: true,
                                                  children: turler.map((tur) {
                                                    return ListTile(
                                                      title: Text(tur, style: TextStyle(color: Colors.white)),
                                                      onTap: () {
                                                        setState(() {
                                                          _filtreOptions.selectedTur = tur;
                                                        });
                                                        Navigator.pop(context);
                                                        Navigator.pop(context);
                                                      },
                                                    );
                                                  }).toList(),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  Divider(color: Colors.grey),
                                  ListTile(
                                    leading: Icon(Icons.check_circle, color: Colors.green),
                                    title: Text('Filtreyi Uygula', style: TextStyle(color: Colors.white)),
                                    onTap: () {
                                      setState(() {
                                        // Müşteri adı filtresini güncelle
                                        _filtreOptions.musteriAdi = _musteriAdiController.text;
                                        
                                        // Fiyat filtrelerini güncelle
                                        if (_minFiyatController.text.isNotEmpty) {
                                          _filtreOptions.minFiyat = double.tryParse(_minFiyatController.text);
                                        }
                                        if (_maxFiyatController.text.isNotEmpty) {
                                          _filtreOptions.maxFiyat = double.tryParse(_maxFiyatController.text);
                                        }
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.clear, color: Colors.red),
                                    title: Text('Filtreleri Temizle', style: TextStyle(color: Colors.white)),
                                    onTap: () {
                                      setState(() {
                                        _filtreOptions = FiltreOptions();
                                        _minFiyatController.clear();
                                        _maxFiyatController.clear();
                                        _musteriAdiController.clear();
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    icon: Icon(Icons.filter_list, color: Colors.white),
                    label: Text(
                      'Filtrele',
                      style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      side: BorderSide(color: Color.fromRGBO(0, 163, 204, 100)),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Container(
                            color: Colors.black,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: Icon(Icons.access_time, color: Colors.blue),
                                  title: Text('En Yeni', style: TextStyle(color: Colors.white)),
                                  onTap: () {
                                    setState(() {
                                      _aktifSiralama = SiralamaKriteri.tarihYeni;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.access_time_filled, color: Colors.grey),
                                  title: Text('En Eski', style: TextStyle(color: Colors.white)),
                                  onTap: () {
                                    setState(() {
                                      _aktifSiralama = SiralamaKriteri.tarihEski;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.arrow_upward, color: Colors.green),
                                  title: Text('Fiyat (Artan)', style: TextStyle(color: Colors.white)),
                                  onTap: () {
                                    setState(() {
                                      _aktifSiralama = SiralamaKriteri.fiyatArtanSirada;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.arrow_downward, color: Colors.red),
                                  title: Text('Fiyat (Azalan)', style: TextStyle(color: Colors.white)),
                                  onTap: () {
                                    setState(() {
                                      _aktifSiralama = SiralamaKriteri.fiyatAzalanSirada;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.person, color: Colors.orange),
                                  title: Text('Müşteri Adına Göre', style: TextStyle(color: Colors.white)),
                                  onTap: () {
                                    setState(() {
                                      _aktifSiralama = SiralamaKriteri.musteriAdi;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    icon: Icon(Icons.sort, color: Colors.white),
                    label: Text(
                      'Sırala',
                      style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      side: BorderSide(color: Color.fromRGBO(0, 163, 204, 100)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // StreamBuilder ve ListView kısmı
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUserId)
                  .collection('satisRaporu')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var satislar = snapshot.data!.docs;

                // Filtreleme işlemleri
                if (_filtreOptions.musteriAdi?.isNotEmpty ?? false) {
                  satislar = satislar.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final musteriAdiSoyadi = '${data['musteriAd']} ${data['musteriSoyad']}'.toLowerCase();
                    return musteriAdiSoyadi.contains(_filtreOptions.musteriAdi!.toLowerCase());
                  }).toList();
                }

                if (_filtreOptions.selectedTur != null) {
                  satislar = satislar.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['tur'] == _filtreOptions.selectedTur;
                  }).toList();
                }

                if (_filtreOptions.baslangicTarihi != null && _filtreOptions.bitisTarihi != null) {
                  satislar = satislar.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final satisTarihi = (data['tarih'] as Timestamp).toDate();
                    return satisTarihi.isAfter(_filtreOptions.baslangicTarihi!) && 
                           satisTarihi.isBefore(_filtreOptions.bitisTarihi!.add(Duration(days: 1)));
                  }).toList();
                }

                if (_filtreOptions.minFiyat != null) {
                  satislar = satislar.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['toplamfiyat'] as num) >= _filtreOptions.minFiyat!;
                  }).toList();
                }

                if (_filtreOptions.maxFiyat != null) {
                  satislar = satislar.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['toplamfiyat'] as num) <= _filtreOptions.maxFiyat!;
                  }).toList();
                }

                // Sıralama işlemleri
                switch (_aktifSiralama) {
                  case SiralamaKriteri.tarihYeni:
                    satislar.sort((a, b) {
                      final tarihA = (a.data() as Map<String, dynamic>)['tarih'] as Timestamp;
                      final tarihB = (b.data() as Map<String, dynamic>)['tarih'] as Timestamp;
                      return tarihB.compareTo(tarihA);
                    });
                    break;
                  case SiralamaKriteri.tarihEski:
                    satislar.sort((a, b) {
                      final tarihA = (a.data() as Map<String, dynamic>)['tarih'] as Timestamp;
                      final tarihB = (b.data() as Map<String, dynamic>)['tarih'] as Timestamp;
                      return tarihA.compareTo(tarihB);
                    });
                    break;
                  case SiralamaKriteri.fiyatArtanSirada:
                    satislar.sort((a, b) {
                      final fiyatA = double.tryParse((a.data() as Map<String, dynamic>)['toplamSepetTutari']?.toString() ?? '0') ?? 0.0;
                      final fiyatB = double.tryParse((b.data() as Map<String, dynamic>)['toplamSepetTutari']?.toString() ?? '0') ?? 0.0;
                      return fiyatA.compareTo(fiyatB);
                    });
                    break;
                  case SiralamaKriteri.fiyatAzalanSirada:
                    satislar.sort((a, b) {
                      final fiyatA = double.tryParse((a.data() as Map<String, dynamic>)['toplamSepetTutari']?.toString() ?? '0') ?? 0.0;
                      final fiyatB = double.tryParse((b.data() as Map<String, dynamic>)['toplamSepetTutari']?.toString() ?? '0') ?? 0.0;
                      return fiyatB.compareTo(fiyatA);
                    });
                    break;
                  case SiralamaKriteri.musteriAdi:
                    satislar.sort((a, b) {
                      final musteriA = '${(a.data() as Map<String, dynamic>)['musteriAd']} ${(a.data() as Map<String, dynamic>)['musteriSoyad']}';
                      final musteriB = '${(b.data() as Map<String, dynamic>)['musteriAd']} ${(b.data() as Map<String, dynamic>)['musteriSoyad']}';
                      return musteriA.compareTo(musteriB);
                    });
                    break;
                }

                // Gruplandırma ve görüntüleme
                final gruplar = gruplanmisSatislar(satislar);
                
                if (gruplar.isEmpty) {
                  return const Center(
                    child: Text(
                      'Satış grupları oluşturulamadı.',
                      style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: gruplar.length,
                  itemBuilder: (context, index) {
                    try {
                      final satisGrubu = gruplar.values.toList()[index];
                      if (satisGrubu.isEmpty) return const SizedBox.shrink();

                      final ilkSatis = satisGrubu.first.data() as Map<String, dynamic>;
                      //final toplamTutar = ilkSatis['toplamSepetTutari']?.toString() ?? '0';
                      
                      // Timestamp kontrolü ve dönüşümü
                      final tarih = ilkSatis['tarih'] is Timestamp 
                          ? (ilkSatis['tarih'] as Timestamp).toDate()
                          : DateTime.now();

                      return Card(
                        color: Colors.black87,
                        margin: const EdgeInsets.all(8),
                        child: ExpansionTile(
                          iconColor: Colors.white,
                          collapsedIconColor: Colors.white,
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${ilkSatis['musteriAd']} ${ilkSatis['musteriSoyad']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd/MM/yyyy HH:mm').format(tarih),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₺${ilkSatis['toplamSepetTutari'].toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                          children: satisGrubu.map((satis) {
                            final data = satis.data() as Map<String, dynamic>;
                            return ListTile(
                              title: Text(
                                data['urunAdi']?.toString() ?? '',
                                style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                              ),
                              subtitle: Text(
                                '${data['miktar'] ?? 0} adet x ₺${data['birimfiyat'] ?? 0} = ₺${data['toplamfiyat'] ?? 0}',
                                style: const TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                              ),
                              trailing: Text(
                                data['tur']?.toString() ?? '',
                                style: const TextStyle(color: Colors.blue, fontFamily: 'Poppins'),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    } catch (e) {
                      print('Satış gösterme hatası: $e');
                      return const SizedBox.shrink();
                    }
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'UrunDuzenleEkrani.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:animated_search_bar/animated_search_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum SiralamaKriteri {
  adaGore,
  fiyatArtanSirada,
  fiyatAzalanSirada,
  stokArtanSirada,
  stokAzalanSirada
}

enum StokDurumu {
  hepsi,
  kritik
}

class FiltreOptions {
  String? selectedTur;
  StokDurumu stokDurumu = StokDurumu.hepsi;
}

class UrunlerEkrani extends StatefulWidget {
  const UrunlerEkrani({Key? key}) : super(key: key);

  @override
  State<UrunlerEkrani> createState() => _UrunlerEkraniState();
}

class _UrunlerEkraniState extends State<UrunlerEkrani> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final TextEditingController _searchController = TextEditingController();
  String searchText = "";
  SiralamaKriteri _aktifSiralama = SiralamaKriteri.adaGore;
  FiltreOptions _filtreOptions = FiltreOptions();
  bool _isSearching = false;
  bool _isSelectionMode = false;
  Set<String> _selectedItems = {};
  
  final Map<String, Color> categoryColors = {
    'Yiyecek': Colors.green,
    'İçecek': Colors.blue,
    'Giyim': Colors.purple,
    'Kozmetik': Colors.pink,
    'Aksesuar': Colors.orange,
    'Kitap': Colors.brown,
    'Kırtasiye/Ofis': Colors.red,
    'Oyuncak': Colors.yellow,
  };

  final Map<String, IconData> categoryIcons = {
    'Yiyecek': Icons.fastfood,
    'İçecek': Icons.local_drink,
    'Giyim': Icons.checkroom,
    'Kozmetik': Icons.face,
    'Aksesuar': Icons.watch,
    'Kitap': Icons.book,
    'Kırtasiye/Ofis': Icons.business_center,
    'Oyuncak': Icons.toys,
  };

  Future<void> _deleteSelectedItems() async {
    bool? onay = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            'Silme Onayı',
            style: TextStyle(color: Colors.white, fontFamily: 'Poppins',fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Seçili ${_selectedItems.length} ürünü silmek istediğinizden emin misiniz?',
            style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'İptal',
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Sil',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        );
      },
    );

    if (onay != true) return;

    try {
      for (String id in _selectedItems) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('urunler')
            .doc(id)
            .delete();
      }
      
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.success,
        label: 'Seçili ürünler silindi',
        backgroundColor: Colors.green,
        iconColor: Colors.white,
      );
      
      setState(() {
        _isSelectionMode = false;
        _selectedItems.clear();
      });
    } catch (e) {
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.fail,
        label: 'Ürünler silinirken hata oluştu',
        backgroundColor: Colors.red,
        iconColor: Colors.white,
      );
    }
  }

  Stream<QuerySnapshot> _getFilteredStream() {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.empty();

    // Kullanıcının kendi ürünleri koleksiyonunu kullan
    CollectionReference urunler = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('urunler');

    if (_filtreOptions.stokDurumu == StokDurumu.kritik) {
      return urunler.where('stok', isLessThan: 10).snapshots();
    }

    if (_filtreOptions.selectedTur != null) {
      return urunler.where('tur', isEqualTo: _filtreOptions.selectedTur).snapshots();
    }

    return urunler.snapshots();
  }

  Stream<QuerySnapshot> _getSortedStream() {
    CollectionReference urunler = FirebaseFirestore.instance.collection('urunler');

    switch (_aktifSiralama) {
      case SiralamaKriteri.adaGore:
        return urunler.orderBy('urunadi').snapshots(); // Ada göre
      case SiralamaKriteri.fiyatArtanSirada:
        return urunler.orderBy('fiyat').snapshots(); // Fiyat artan
      case SiralamaKriteri.fiyatAzalanSirada:
        return urunler.orderBy('fiyat', descending: true).snapshots(); // Fiyat azalan
      case SiralamaKriteri.stokArtanSirada:
        return urunler.orderBy('stok').snapshots(); // Stok artan
      case SiralamaKriteri.stokAzalanSirada:
        return urunler.orderBy('stok', descending: true).snapshots(); // Stok azalan
      default:
        return urunler.snapshots();
    }
  }

  void _showTurSecimModal(BuildContext context) {
    if (currentUserId == null) return; // Kullanıcı girişi kontrolü

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: Colors.black,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Tür Seçin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Divider(color: Colors.grey),
              ListTile(
                leading: Icon(Icons.clear_all, color: Colors.blue),
                title: Text(
                  'Tümü',
                  style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                ),
                onTap: () {
                  setState(() {
                    _filtreOptions.selectedTur = null;
                  });
                  Navigator.pop(context);
                },
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUserId)
                      .collection('urunler')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'Ürün bulunamadı',
                          style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                        ),
                      );
                    }

                    // Benzersiz türleri al
                    Set<String> turler = snapshot.data!.docs
                        .map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['tur'] as String;
                        })
                        .toSet();

                    if (turler.isEmpty) {
                      return Center(
                        child: Text(
                          'Tür bulunamadı',
                          style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                        ),
                      );
                    }

                    return ListView(
                      shrinkWrap: true,
                      children: turler.map((tur) {
                        // Türe göre icon seç
                        IconData turIcon;
                        Color turRenk;
                        switch (tur.toLowerCase()) {
                          case 'yiyecek':
                            turIcon = Icons.fastfood;
                            turRenk = Colors.green;
                            break;
                          case 'içecek':
                            turIcon = Icons.local_drink;
                            turRenk = Colors.blue;
                            break;
                          case 'giyim':
                            turIcon = Icons.checkroom;
                            turRenk = Colors.purple;
                            break;
                          case 'kozmetik':
                            turIcon = Icons.face;
                            turRenk = Colors.pink;
                            break;
                          case 'aksesuar':
                            turIcon = Icons.watch;
                            turRenk = Colors.orange;
                            break;
                          case 'kitap':
                            turIcon = Icons.book;
                            turRenk = Colors.brown;
                            break;
                          case 'kırtasiye/ofis':
                            turIcon = Icons.edit;
                            turRenk = Colors.red;
                            break;
                          case 'oyuncak':
                            turIcon = Icons.toys;
                            turRenk = Colors.yellow;
                            break;
                          default:
                            turIcon = Icons.category;
                            turRenk = Colors.grey;
                        }

                        return ListTile(
                          leading: Icon(turIcon, color: turRenk),
                          title: Text(
                            tur,
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _filtreOptions.selectedTur = tur;
                            });
                            Navigator.pop(context);
                          },
                          selected: _filtreOptions.selectedTur == tur,
                          selectedTileColor: Color.fromRGBO(0, 163, 204, 20),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(String urunId, String urunAdi) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            'Ürün Silme Onayı',
            style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
          ),
          content: Text(
            '$urunAdi ürününü silmek istediğinizden emin misiniz?',
            style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'İptal',
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUserId)
                      .collection('urunler')
                      .doc(urunId)
                      .delete();
                  
                  Navigator.pop(context);
                  IconSnackBar.show(
                    context,
                    snackBarType: SnackBarType.success,
                    label: 'Ürün başarıyla silindi',
                    backgroundColor: Colors.green,
                    iconColor: Colors.white,
                  );
                } catch (e) {
                  IconSnackBar.show(
                    context,
                    snackBarType: SnackBarType.fail,
                    label: 'Ürün silinirken bir hata oluştu',
                    backgroundColor: Colors.red,
                    iconColor: Colors.white,
                  );
                }
              },
              child: Text(
                'Sil',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        title: AnimatedCrossFade(
          duration: const Duration(microseconds: 1),
          firstChild: const Text(
            "Ürünler",
            style: TextStyle(
              fontFamily: 'FunnelDisplay',
              color: Colors.white,
              fontWeight: FontWeight.bold
            ),
          ),
          secondChild: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            decoration: const InputDecoration(
              hintText: 'Ürün ara...',
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
          if (_isSelectionMode) ...[
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: _selectedItems.isEmpty ? null : _deleteSelectedItems,
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedItems.clear();
                });
              },
            ),
          ] else ...[
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
        ],
      ),
      body: Column(
        children: [
          // Filtre ve Sıralama Bölümü
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
                                    leading: Icon(Icons.category, color: Colors.blue),
                                    title: Text('Tüm Ürünler', style: TextStyle(color: Colors.white)),
                                    onTap: () {
                                      setState(() {
                                        _filtreOptions.selectedTur = null;
                                        _filtreOptions.stokDurumu = StokDurumu.hepsi;
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.warning, color: Colors.orange),
                                    title: Text('Kritik Stok', style: TextStyle(color: Colors.white)),
                                    onTap: () {
                                      setState(() {
                                        _filtreOptions.stokDurumu = StokDurumu.kritik;
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.category, color: Colors.purple),
                                    title: Text('Türe Göre', style: TextStyle(color: Colors.white)),
                                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                                    onTap: () {
                                      _showTurSecimModal(context);
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
                                  leading: Icon(Icons.sort_by_alpha, color: Colors.blue),
                                  title: Text('Ada Göre', style: TextStyle(color: Colors.white)),
                                  onTap: () {
                                    setState(() {
                                      _aktifSiralama = SiralamaKriteri.adaGore;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.attach_money, color: Colors.green),
                                  title: Text('Fiyata Göre Artan', style: TextStyle(color: Colors.white)),
                                  onTap: () {
                                    setState(() {
                                      _aktifSiralama = SiralamaKriteri.fiyatArtanSirada;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.attach_money, color: Colors.red),
                                  title: Text('Fiyata Göre Azalan', style: TextStyle(color: Colors.white)),
                                  onTap: () {
                                    setState(() {
                                      _aktifSiralama = SiralamaKriteri.fiyatAzalanSirada;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.inventory, color: Colors.purple),
                                  title: Text('Stoğa Göre Artan', style: TextStyle(color: Colors.white)),
                                  onTap: () {
                                    setState(() {
                                      _aktifSiralama = SiralamaKriteri.stokArtanSirada;
                                    });
                                    Navigator.pop(context);
                                  },

                                ),
                                ListTile(
                                  leading: Icon(Icons.inventory, color: Colors.teal),
                                  title: Text('Stoğa Göre Azalan', style: TextStyle(color: Colors.white)),
                                  onTap: () {
                                    setState(() {
                                      _aktifSiralama = SiralamaKriteri.stokAzalanSirada;
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
          // Tablo Başlıkları
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Container(width: 50),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Ürün Adı',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'FunnelDisplay',
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Stok',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'FunnelDisplay',
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Fiyat',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'FunnelDisplay',
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Tür',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'FunnelDisplay',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white,),
          // Ürün Listesi
          Expanded(
            child: StreamBuilder(
              stream: _getFilteredStream(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var urunler = snapshot.data!.docs;

                // Arama filtresini uygula
                if (searchText.isNotEmpty) {
                  urunler = urunler.where((urun) {
                    String urunAdi = (urun['urunadi'] ?? '').toString().toLowerCase();
                    String barkod = (urun['barkod']?.toString() ?? '').toLowerCase();
                    return urunAdi.contains(searchText.toLowerCase()) ||
                        barkod.contains(searchText.toLowerCase());
                  }).toList();
                }

                // Sıralamayı uygula
                switch (_aktifSiralama) {
                  case SiralamaKriteri.adaGore:
                    urunler.sort((a, b) => (a['urunadi'] ?? '').compareTo(b['urunadi'] ?? ''));
                    break;
                  case SiralamaKriteri.fiyatArtanSirada:
                    urunler.sort((a, b) => (a['fiyat'] ?? 0).compareTo(b['fiyat'] ?? 0));
                    break;
                  case SiralamaKriteri.fiyatAzalanSirada:
                    urunler.sort((a, b) => (b['fiyat'] ?? 0).compareTo(a['fiyat'] ?? 0));
                    break;
                  case SiralamaKriteri.stokArtanSirada:
                    urunler.sort((a, b) => (a['stok'] ?? 0).compareTo(b['stok'] ?? 0));
                    break;
                  case SiralamaKriteri.stokAzalanSirada:
                    urunler.sort((a, b) => (b['stok'] ?? 0).compareTo(a['stok'] ?? 0));
                    break;
                }

                return ListView.builder(
                  itemCount: urunler.length,
                  itemBuilder: (context, index) {
                    final urun = urunler[index];
                    final data = urun.data() as Map<String, dynamic>;
                    final kategori = data['tur'] as String;
                    final kategoriRengi = categoryColors[kategori] ?? Colors.grey;

                    return Card(
                      color: Colors.black,
                      child: InkWell(
                        onLongPress: () {
                          setState(() {
                            _isSelectionMode = true;
                            _selectedItems.add(urun.id);
                          });
                        },
                        onTap: () {
                          if (_isSelectionMode) {
                            setState(() {
                              if (_selectedItems.contains(urun.id)) {
                                _selectedItems.remove(urun.id);
                              } else {
                                _selectedItems.add(urun.id);
                              }
                            });
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              if (_isSelectionMode)
                                Checkbox(
                                  value: _selectedItems.contains(urun.id),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedItems.add(urun.id);
                                      } else {
                                        _selectedItems.remove(urun.id);
                                      }
                                    });
                                  },
                                  checkColor: Colors.white,
                                  fillColor: MaterialStateProperty.resolveWith((states) {
                                    return Color.fromRGBO(0, 163, 204, 1);
                                  }),
                                ),
                              Container(
                                width: _isSelectionMode ? 30 : 50,
                                child: Icon(
                                  categoryIcons[data['tur']] ?? Icons.category,
                                  color: categoryColors[data['tur']] ?? Colors.grey,
                                  size: 24,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  data['urunadi'] ?? '',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '${data['stok']}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '₺${data['fiyat']}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (categoryColors[data['tur']] ?? Colors.grey).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    data['tur'] ?? '',
                                    style: TextStyle(
                                      color: categoryColors[data['tur']] ?? Colors.grey,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UrunDuzenleEkrani(),
            ),
          );
        },
        backgroundColor: Color.fromRGBO(0, 163, 204, 100),
        child: const Icon(Icons.edit, color: Colors.white),
        tooltip: 'Ürünleri Düzenle',
      ),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';



class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(settings);
  }

  static Future<void> showCriticalAlert(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'critical_channel',
      'Critical Alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(0, title, body, details);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Uygulama başlarken bildirim servisini hazırla
  await NotificationService.init();

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F1F1F),
        elevation: 0,
        centerTitle: true,
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFBB86FC),
        secondary: Color(0xFF03DAC6),
        error: Color(0xFFCF6679),
      ),
    ),
    home: const AkilliBileklikApp(),
  ));
}

class AkilliBileklikApp extends StatefulWidget {
  const AkilliBileklikApp({super.key});

  @override
  State<AkilliBileklikApp> createState() => _AkilliBileklikAppState();
}

class _AkilliBileklikAppState extends State<AkilliBileklikApp> {
  int _seciliSayfaIndex = 0;
  BluetoothDevice? _takipEdilenCihaz;
  int _anlikRssi = -100;
  String _baglantiDurumu = "Bağlı Değil";
  StreamSubscription? _scanSubscription;
  Timer? _rssiTimer;

 
  double _alarmSiniri = -80.0; 
  bool _bildirimGonderildi = false; 

  final TextEditingController _isimController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  List<Map<String, dynamic>> cocuklar = [];

  @override
  void initState() {
    super.initState();
    izinleriKontrolEt();
    _ayarlariYukle(); 
  }

 
  Future<void> _ayarlariYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _alarmSiniri = prefs.getDouble('alarm_siniri') ?? -80.0;
    });
  }

 
  Future<void> _ayariKaydet(double deger) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('alarm_siniri', deger);
    setState(() {
      _alarmSiniri = deger;
    });
  }

  Future<void> izinleriKontrolEt() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.notification,
    ].request();
  }

  void bileklikSil(int index) {
    String silinenIsim = cocuklar[index]["isim"];
    if (cocuklar[index]["device"] != null) {
      (cocuklar[index]["device"] as BluetoothDevice).disconnect();
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("Cihazı Sil?", style: TextStyle(color: Colors.white)),
        content: Text("$silinenIsim kalıcı olarak silinecek.",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            child: const Text("İPTAL", style: TextStyle(color: Colors.white54)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child:
                const Text("SİL", style: TextStyle(color: Color(0xFFCF6679))),
            onPressed: () {
              setState(() {
                cocuklar.removeAt(index);
                if (_takipEdilenCihaz != null) {
                  _takipEdilenCihaz = null;
                  _seciliSayfaIndex = 0;
                  _rssiTimer?.cancel();
                }
              });
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _ayarlarPenceresiniAc() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2C),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(20),
           
              height: 400, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Güvenlik Ayarları",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  const Text("Uzaklaşma Alarm Sınırı (Hassasiyet)",
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text("${_alarmSiniri.toInt()} dBm",
                          style: const TextStyle(
                              color: Color(0xFFBB86FC),
                              fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Slider(
                          value: _alarmSiniri,
                          min: -100,
                          max: -50,
                          divisions: 10,
                          activeColor: const Color(0xFFBB86FC),
                          label: "${_alarmSiniri.toInt()}",
                          onChanged: (val) {
                            setSheetState(() {
                              _alarmSiniri = val;
                            });
                            _ayariKaydet(val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Bilgi: Değer -100'e yaklaştıkça alarm daha uzak mesafede çalar. -50'ye yaklaştıkça hemen öter.",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  
          
                  const Spacer(), 
                  Center(
                    child: SizedBox(
                      width: double.infinity, 
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent, 
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.notifications_active),
                        label: const Text("SİSTEMİ VE BİLDİRİMİ TEST ET", 
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {

                          NotificationService.showCriticalAlert(
                            "TEST BAŞARILI",
                            "Güvenlik sistemi ve bildirimler sorunsuz çalışıyor."
                          );
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void yeniBileklikEkle() {
    List<ScanResult> bulunanSonuclar = [];
    bool taraniyor = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2C2C2C),
              title: const Text("Cihaz Tara ve Ekle",
                  style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _isimController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Çocuğun İsmi",
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF383838),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _idController,
                      readOnly: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Seçilen Cihaz ID",
                        hintText: "Listeden seçiniz...",
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF383838),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF383838)),
                      icon: taraniyor
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.search, color: Color(0xFFBB86FC)),
                      label: Text(taraniyor ? "Aranıyor..." : "Bileklikleri Tara",
                          style: const TextStyle(color: Colors.white)),
                      onPressed: taraniyor
                          ? null
                          : () async {
                              setStateDialog(() {
                                taraniyor = true;
                                bulunanSonuclar.clear();
                              });
                              if (FlutterBluePlus.isScanningNow)
                                await FlutterBluePlus.stopScan();
                              await FlutterBluePlus.startScan(
                                  timeout: const Duration(seconds: 4));
                              _scanSubscription =
                                  FlutterBluePlus.scanResults.listen((results) {
                                if (mounted) {
                                  setStateDialog(() {
                                    bulunanSonuclar = results
                                        .where((r) =>
                                            r.device.platformName.isNotEmpty)
                                        .toList();
                                  });
                                }
                              });
                              await Future.delayed(const Duration(seconds: 4));
                              if (mounted)
                                setStateDialog(() {
                                  taraniyor = false;
                                });
                            },
                    ),
                    if (bulunanSonuclar.isNotEmpty) ...[
                      const Divider(color: Colors.white24),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: bulunanSonuclar.length,
                          itemBuilder: (context, index) {
                            final result = bulunanSonuclar[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.bluetooth,
                                  color: Color(0xFF03DAC6)),
                              title: Text(result.device.platformName,
                                  style: const TextStyle(color: Colors.white)),
                              onTap: () => _idController.text =
                                  result.device.remoteId.toString(),
                            );
                          },
                        ),
                      )
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                    child: const Text("İPTAL"),
                    onPressed: () {
                      Navigator.pop(context);
                      FlutterBluePlus.stopScan();
                    }),
                ElevatedButton(
                  child: const Text("KAYDET"),
                  onPressed: () {
                    if (_isimController.text.isNotEmpty &&
                        _idController.text.isNotEmpty) {
                      var secilenResult = bulunanSonuclar.firstWhere((r) =>
                          r.device.remoteId.toString() == _idController.text);
                      setState(() {
                        cocuklar.add({
                          "isim": _isimController.text,
                          "id": _idController.text,
                          "sinyal": -100,
                          "durum": "Bağlantı Bekleniyor",
                          "renk": Colors.grey,
                          "device": secilenResult.device
                        });
                      });
                      _isimController.clear();
                      _idController.clear();
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void takibeBasla(int index) async {
    BluetoothDevice device = cocuklar[index]["device"];
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()));

    try {
      await device.connect(autoConnect: false);
      Navigator.pop(context);
      setState(() {
        _takipEdilenCihaz = device;
        _seciliSayfaIndex = 1;
        _baglantiDurumu = "Bağlandı";
        _bildirimGonderildi = false; 
      });

      _rssiTimer?.cancel();
      _rssiTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (_takipEdilenCihaz == null || !_takipEdilenCihaz!.isConnected) {
          NotificationService.showCriticalAlert(
              "BAĞLANTI KOPTU!", "Çocuğun bilekliği ile bağlantı kesildi!");
          timer.cancel();
          if (mounted) {
            setState(() {
              _baglantiDurumu = "Koptu";
              cocuklar[index]["durum"] = "BAĞLANTI YOK";
              cocuklar[index]["renk"] = Colors.grey;
            });
          }
          return;
        }
        try {
          int rssi = await _takipEdilenCihaz!.readRssi();
          if (mounted) {
           setState(() {
            _anlikRssi = rssi;
            cocuklar[index]["sinyal"] = rssi;

            String yeniDurum = MesafeMantik.durumBelirle(rssi, _alarmSiniri);

            if (yeniDurum == "GÜVENLİ") {
              cocuklar[index]["durum"] = "GÜVENLİ";
              cocuklar[index]["renk"] = const Color(0xFF4CAF50);
              _bildirimGonderildi = false;
            } 
            else if (yeniDurum == "UZAKLAŞIYOR") {
              cocuklar[index]["durum"] = "UZAKLAŞIYOR";
              cocuklar[index]["renk"] = const Color(0xFFFF9800);
            } 
            else { 
              cocuklar[index]["durum"] = "TEHLİKE!";
              cocuklar[index]["renk"] = const Color(0xFFEF5350);

              if (!_bildirimGonderildi) {
                NotificationService.showCriticalAlert("UZAKLAŞMA UYARISI",
                    "Çocuk belirlenen güvenli mesafeden çıktı!");
                _bildirimGonderildi = true;
              }
            }
          });
          }
        } catch (e) {
          print("RSSI okuma hatası: $e");
        }
      });
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Bağlantı Hatası: $e")));
    }
  }

  void _onItemTapped(int index) {
    if (index == 1 && _takipEdilenCihaz == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Lütfen önce bir cihaz sürükleyin veya seçin.")));
      return;
    }
    setState(() => _seciliSayfaIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Çocuk Takip Sistemi",
            style: TextStyle(fontWeight: FontWeight.bold)),
        // SPRINT 3: Ayarlar Butonu
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _ayarlarPenceresiniAc,
          )
        ],
      ),
      floatingActionButton: _seciliSayfaIndex == 0
          ? FloatingActionButton(
              onPressed: yeniBileklikEkle,
              backgroundColor: const Color(0xFFBB86FC),
              child: const Icon(Icons.add, color: Colors.black))
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: _seciliSayfaIndex == 0 ? _buildListeSayfasi() : _buildDetaySayfasi(),
      bottomNavigationBar: DragTarget<int>(
        onWillAcceptWithDetails: (data) => true,
        onAcceptWithDetails: (index) => takibeBasla(index as int),
        builder: (context, candidateData, rejectedData) {
          return BottomNavigationBar(
            backgroundColor: candidateData.isNotEmpty
                ? Colors.deepPurple.shade900
                : const Color(0xFF1F1F1F),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.list_alt), label: 'Cihazlar'),
              BottomNavigationBarItem(icon: Icon(Icons.radar), label: 'Takip'),
            ],
            currentIndex: _seciliSayfaIndex,
            onTap: _onItemTapped,
          );
        },
      ),
    );
  }

  Widget _buildListeSayfasi() {
    if (cocuklar.isEmpty) {
      return const Center(
          child: Text("Henüz kayıtlı bileklik yok.\n(+) tuşuna basarak ekleyin.",
              textAlign: TextAlign.center));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: cocuklar.length,
      itemBuilder: (context, index) {
        var cocuk = cocuklar[index];

        return Draggable<int>(
          data: index,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFFBB86FC).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: const Icon(Icons.child_care, color: Colors.black),
                title: Text(cocuk["isim"],
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          childWhenDragging: Opacity(
              opacity: 0.3,
              child: Card(child: ListTile(title: Text(cocuk["isim"])))),
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.endToStart,
            confirmDismiss: (d) async {
              bileklikSil(index);
              return false;
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                  color: const Color(0xFFCF6679).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.delete, color: Color(0xFFCF6679)),
            ),
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: (cocuk["renk"] as Color).withOpacity(0.2),
                  child: Icon(Icons.child_care, color: cocuk["renk"]),
                ),
                title: Text(cocuk["isim"]),
                subtitle:
                    Text(cocuk["id"], style: const TextStyle(fontSize: 10)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => takibeBasla(index),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetaySayfasi() {
    if (_takipEdilenCihaz == null)
      return const Center(child: Text("Cihaz Seçilmedi"));
    Color anlikRenk = _anlikRssi > -60
        ? Colors.green
        : (_anlikRssi > _alarmSiniri ? Colors.orange : Colors.red);
    String anlikDurum = _anlikRssi > -60
        ? "GÜVENLİ"
        : (_anlikRssi > _alarmSiniri ? "UZAKLAŞIYOR" : "TEHLİKE!");

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
              radius: 60,
              backgroundColor: anlikRenk.withOpacity(0.2),
              child: Icon(Icons.person, size: 60, color: anlikRenk)),
          const SizedBox(height: 20),
          Text(_takipEdilenCihaz!.platformName,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 50),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                      value: (_anlikRssi + 100) / 100,
                      strokeWidth: 10,
                      color: anlikRenk)),
              Column(children: [
                Text("$_anlikRssi",
                    style: TextStyle(
                        color: anlikRenk,
                        fontSize: 50,
                        fontWeight: FontWeight.bold)),
                const Text("dBm")
              ])
            ],
          ),
          const SizedBox(height: 50),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            decoration: BoxDecoration(
                color: anlikRenk.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: anlikRenk)),
            child: Text(anlikDurum,
                style: TextStyle(
                    color: anlikRenk,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 30),
          TextButton.icon(
              onPressed: () {
                _takipEdilenCihaz?.disconnect();
                setState(() {
                  _takipEdilenCihaz = null;
                  _seciliSayfaIndex = 0;
                  _rssiTimer?.cancel();
                });
              },
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text("Takibi Durdur"))
        ],
      ),
    );
  }
}



class MesafeMantik {
  static String durumBelirle(int rssi, double sinir) {
    if (rssi > -60) {
      return "GÜVENLİ";
    } else if (rssi > sinir) {
      return "UZAKLAŞIYOR";
    } else {
      return "TEHLİKE!";
    }
  }
}
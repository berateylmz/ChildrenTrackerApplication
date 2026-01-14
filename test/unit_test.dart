import 'package:flutter_test/flutter_test.dart';
import 'package:cocuk_takip_bilekligi/main.dart';

void main() {
  group('Mesafe ve Güvenlik Mantığı Testleri', () {
    double testSiniri = -80.0;

    test('Sinyal çok güçlüyse (-50) GÜVENLİ dönmeli', () {
      // 1. İşlem: Fonksiyonu çalıştır
      String sonuc = MesafeMantik.durumBelirle(-50, testSiniri);
      // 2. Kontrol: Beklenen sonuç mu?
      expect(sonuc, "GÜVENLİ");
    });

    test('Sinyal orta seviyedeyse (-70) UZAKLAŞIYOR dönmeli', () {
      String sonuc = MesafeMantik.durumBelirle(-70, testSiniri);
      expect(sonuc, "UZAKLAŞIYOR");
    });

    test('Sinyal sınırdan düşükse (-90) TEHLİKE! dönmeli', () {
      String sonuc = MesafeMantik.durumBelirle(-90, testSiniri);
      expect(sonuc, "TEHLİKE!");
    });
    
    test('Sinyal tam sınırdayken (-81) TEHLİKE! dönmeli', () {
       String sonuc = MesafeMantik.durumBelirle(-81, testSiniri);
       expect(sonuc, "TEHLİKE!");
    });
  });
}
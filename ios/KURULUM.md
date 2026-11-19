# Ödeme uygulamasını iPhone'a kurma (Mac + kablo)

1. Mac'te App Store'dan **Xcode**'u kur (ilk açılışta ek bileşenleri yüklemesine izin ver).
2. Bu depoyu indir: GitHub'da **Code → Download ZIP**, sonra zip'i aç.
3. Claude'un gönderdiği **odeme-yedek.json** dosyasını `ios/OdemePlani/web/` klasörüne kopyala (verilerin uygulamaya böyle girer; bu dosya GitHub'a gitmez).
4. `ios/OdemePlani.xcodeproj` dosyasına çift tıkla.
5. Xcode → **Settings → Accounts → +** ile Apple ID'nle giriş yap.
6. Soldaki mavi **OdemePlani** projesine tıkla → **Signing & Capabilities** → **Team**: kendi adın (Personal Team).
   Kırmızı "bundle identifier" hatası çıkarsa **Bundle Identifier**'ın sonuna bir şey ekle (ör. `com.ataeren.odemeplani2`).
7. iPhone'u kabloyla bağla, iPhone'da **Güven**'e bas.
   iPhone'da **Ayarlar → Gizlilik ve Güvenlik → Geliştirici Modu**'nu aç (telefon yeniden başlar).
8. Xcode'un üstündeki cihaz listesinden **iPhone'unu** seç ve **▶ (Run)** düğmesine bas.
9. İlk seferde iPhone'da **Ayarlar → Genel → VPN ve Cihaz Yönetimi** → kendi Apple ID'ne **Güven**.
10. Uygulamayı aç, bildirim izni sorulunca **İzin Ver** de.

**7 günde bir:** ücretsiz Apple hesabıyla uygulama 7 gün sonra açılmaz. iPhone'u bağlayıp 8. adımı tekrarla; verilerin silinmez.

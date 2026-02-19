# Analog Discovery 2 Olcum Sistemi Isterleri

Bu dokuman, Digilent Analog Discovery 2 cihazi ile AD9767 DAC cikisinin olculmesi, goruntulenmesi ve analiz edilmesi icin gerekli tum yazilim ve donanim isterlerini tanimlar.


## Genel Tanim

Sistem, Analog Discovery 2 cihazinin osiloskop fonksiyonunu kullanarak FPGA'dan gelen DAC cikis sinyalini yakalar. Yakalanan sinyal bilgisayar tarafinda Python ile islenir, canli olarak goruntulenir, frekans ve genlik analizi yapilir, FFT spektrumu cikarilir ve sonuclar grafik ile CSV dosyasi olarak kaydedilir. Tum iletisim Digilent WaveForms SDK (DWF) kutuphanesi uzerinden gerceklesir.


## Donanim Isterleri

Olcum cihazi olarak Digilent Analog Discovery 2 kullanilacaktir. Cihaz USB uzerinden bilgisayara baglanacaktir. Bilgisayarda Digilent WaveForms yazilimi ve SDK (DWF kutuphanesi) kurulu olmalidir. DWF kutuphanesinin surumu 3.x veya uzerinde olmalidir.

Fiziksel baglanti olarak DAC'in DA2 analog cikisi Analog Discovery 2'nin CH2 (2+) girisiyle baglanacaktir. Istege bagli olarak DA1 analog cikisi da CH1 (1+) girisiyle baglanabilir. GND baglantilari mutlaka yapilmalidir.


## Osiloskop Yapilandirma Isterleri

Ornekleme hizi 10 MHz (10.000.000 ornek/saniye) olarak ayarlanacaktir. Bu hiz, 63.5 kHz sinus dalgasi icin periyot basina yaklasik 158 ornek saglar ve sinyal detaylarini yeterli cozunurlukte yakalar.

Tampon boyutu 8192 ornek olacaktir. Bu deger, tek seferde yaklanan veri miktarini belirler ve yaklasik 819.2 mikrosaniye uzunlugunda bir zaman penceresi saglar.

Voltaj araligi +/- 2.5V (toplam 5V) olarak ayarlanacaktir. Bu aralik, DAC'in beklenen 1V Vpp cikisini rahatlilka olcmeye yeterlidir.

Her iki kanal (CH1 ve CH2) es zamanli olarak etkinlestirilecektir. Filtre modu Decimate olarak ayarlanacaktir.


## Tetikleme Isterleri

Tetikleme kaynagi olarak analog giris dedektoru (trigsrcDetectorAnalogIn) kullanilacaktir. Tetikleme kanali CH1 (kanal 0) olacaktir. Tetikleme tipi kenar tetikleme (edge trigger) olacaktir. Tetikleme kosulu yukselme kenari (rising edge) olacaktir. Tetikleme seviyesi 0.0V (sinyalin orta noktasi) olacaktir.

Otomatik tetikleme zamanlayicisi 1 saniye olarak ayarlanacaktir. Bu sayede sinyal gelmese bile sistem 1 saniye icerisinde otomatik olarak tetiklenir ve donmaz.


## Canli Osiloskop Isterleri (view_waveform.py)

Canli osiloskop uygulamasi matplotlib kullanarak gercek zamanli dalga formu goruntusu saglar. Guncelleme araligi 100 milisaniye olacaktir. Grafik penceresi koyu arka planli (dark_background) olacaktir.

Ekranda iki alt grafik dikey olarak yerlestirilecektir. Ust grafik CH1 sinyalini yesil renkte (#00FF00) gosterecek ve "Channel 1 (DA1 Output)" basligini tasiyacaktir. Alt grafik CH2 sinyalini mavi renkte (#00AAFF) gosterecek ve "Channel 2 (DA2 Output)" basligini tasiyacaktir.

Her iki grafikte yatay eksen mikrosaniye cinsinden zamani, dikey eksen volt cinsinden voltaji gosterecektir. Dikey eksen araligi +/- 2.5V olacaktir. Grafik uzerinde izgaralar (grid) gorunur olacaktir.

Frekans olcumu sifir gecisi yontemiyle yapilacaktir. Bu yontemde sinyal ortalamasindan DC ofset cikarilir, negatiften pozitife gecis noktaları bulunur ve ardisik gecisler arasindaki ortalama periyottan frekans hesaplanir. Frekans 1000 Hz uzerindeyse kHz, altindaysa Hz cinsinden gosterilecektir.

Tepe-tepe voltaj (Vpp) her kanal icin ayri hesaplanip grafik uzerinde gosterilecektir. Frekans bilgisi sari renkte, Vpp bilgileri kanal renklerinde gosterilecektir.

Yakalama dongusu her iterasyonda yeni bir edinim baslatacak, tamamlanmasini bekleyecek (maksimum 500 milisaniye bekleme zamanlayicisi ile) ve veriyi okuyacaktir. Pencere kapatildiginda cihaz baglantisi temiz bir sekilde sonlandirilacaktir.


## Tek Sefer Yakalama ve Analiz Isterleri (capture_analyze.py)

Bu uygulama tek bir yakalama yapar, kapsamli analiz uygular ve sonuclari kaydeder. Grafik ciktisi icin matplotlib Agg arka ucu kullanilacaktir (pencere acmadan dosyaya kaydeder).

Yakalama tamamlandiktan sonra her kanal icin su olcumler hesaplanacaktir: DC ofset (ortalama deger), minimum voltaj, maksimum voltaj, tepe-tepe voltaj (Vpp), AC etkin deger (Vrms), frekans ve periyot.

Frekans tahmini sifir gecisi yontemiyle yapilacaktir. Sinyalden DC ofset cikarilir, negatiften pozitife gecis noktalari lineer interpolasyon ile daha hassas belirlenir ve ardisik gecis araliklari ortalanarak periyot ve frekans bulunur.

FFT analizi uygulanacaktir. Sinyalden DC bileseni cikarildiktan sonra tek tarafli FFT (rfft) alinacaktir. Temel frekans, FFT buyukluk spektrumundaki en buyuk tepe olarak belirlenir. Ikinci, ucuncu, dorduncu ve besinci harmonikler temel frekansin katlari olarak aranir ve her birinin buyuklugu dB cinsinden (temel frekansa gore) hesaplanir.

Toplam harmonik bozulma (THD) hesabi, ikinci ile besinci harmoniklerin guc toplamlari karekoku alinip temel frekans buyuklugune bolunmesiyle yuzde olarak yapilir. Sinyal-gurultu orani (SNR) temel frekans buyuklugu ile geri kalan tum bilesenlerin toplam gucunun orani olarak dB cinsinden hesaplanir.

Sinyal kalitesi degerlendirmesi yapilacaktir. CH1 sinyalinin standart sapmasi 0.001'den kucukse "sinyal yok" uyarisi verilir. Aksi halde ideal sinus dalgasiyla korelasyon hesaplanarak sinus benzerligi yuzde olarak gosterilir. THD yuzde 1'den kucukse "mukemmel", yuzde 5'ten kucukse "iyi", yuzde 10'dan kucukse "orta", uzerindeyse "dusuk" olarak degerlendirilir.

Grafik ciktisi 2x2 duzeninde olacaktir. Sol ust grafik CH1 zaman domaini (yesil), sag ust grafik CH2 zaman domaini (mavi), sol alt grafik CH1 FFT spektrumu, sag alt grafik CH2 FFT spektrumu olarak duzenlenecektir. Zaman domaini grafiklerinde ilk 2000 ornek gosterilecek ve DC ofset kesikli sari cizgiyle isaretlenecektir. FFT grafikleri dB olceginde (20*log10) gosterilecek ve frekans ekseni kHz cinsinden olacaktir. Grafik 150 DPI cozunurlukle PNG dosyasi olarak kaydedilecektir.

Ham yakalama verisi NumPy npz formatiyla kaydedilecektir. Dosyada CH1 verisi, CH2 verisi, zaman ekseni ve ornekleme hizi bulunacaktir.


## Canli Monitor ve Kayit Isterleri (live_monitor.py)

Bu uygulama suresiz olarak calisan bir terminal tabanli olcum araci olup Ctrl+C ile durdurulur. Olcum araligi 0.5 saniye olacaktir.

Her olcum dongusunde her iki kanal icin Vpp, Vrms, DC ofset, frekans ve THD degerleri hesaplanacaktir. Hesaplama yontemi capture_analyze.py ile ayni olacaktir.

Terminal ciktisi tablo formatinda olacaktir. Her satir olcum numarasi, zaman damgasi, CH1 degerleri (Vpp, Vrms, DC, frekans, THD) ve CH2 degerleri (Vpp, Vrms, DC, frekans, THD) icerecektir. Voltaj degerleri milivolt, frekans degerleri kilohertz, THD degerleri yuzde cinsinden gosterilecektir. Her 20 satirda bir baslik satiri tekrar yazilarak okunurluk korunacaktir.

Tum olcumler otomatik olarak CSV dosyasina kaydedilecektir. Dosya adi log_YYYYMMDD_HHMMSS.csv formatinda olacak ve her olcum aninda dosyaya yazilip aninda disk'e aktarilacaktir (flush). CSV dosyasi zaman damgasi, gecen sure (saniye), ve her iki kanal icin Vpp, Vrms, DC, frekans ve THD sutunlarini icerecektir.

Program sonlandiginda toplam olcum sayisi ve log dosyasi yolu gosterilecek, cihaz baglantisi temiz bir sekilde kapatilacaktir.


## Cihaz Yonetimi Isterleri

Tum Python uygulamalarinda cihaz acilis sureci ayni olacaktir. Once DWF kutuphanesi yuklenir (Windows'ta cdll.dwf, Linux'ta libdwf.so). Ardindan FDwfDeviceOpen ile cihaz acilir. Acilis basarisiz olursa hata mesaji gosterilir ve program sonlanir. Basarili acilista cihaz otomatik yapilandirmasi kapatilir (FDwfDeviceAutoConfigureSet).

Osiloskop yapilandirmasindan sonra 2 saniyelik ofset stabilizasyon suresi beklenir. Bu sure, giriş devrelerinin kararlı hale gelmesini saglar.

Program sonlandiginda (normal kapanis veya Ctrl+C) FDwfDeviceCloseAll cagrisiyla tum cihaz baglantilari kapatilacaktir. Bu islem try/finally blogu icerisinde yapilarak her durumda cihazin serbest birakilmasi garanti edilecektir.


## Yazilim Bagimliliklari

Python 3.x gereklidir. Gerekli kutuphaneler numpy (sayisal hesaplamalar ve FFT), matplotlib (grafik olusturma ve canli gosterim) ve ctypes (DWF kutuphanesi ile iletisim, Python standart kutuphanesi) olarak listelenir. Ek olarak Digilent WaveForms SDK (DWF) kurulu olmalidir.


## Beklenen Olcum Sonuclari

Sistemin dogru calistiginda Analog Discovery 2 uzerinden su degerlerin olculmesi beklenir: CH2 kanalinda 63.47 kHz frekans, 1003.5 mV Vpp, 353.4 mV Vrms, 4.9 mV DC ofset, yuzde 0.48 THD ve 33.1 dB SNR. CH1 kanalinda eger fiziksel baglanti yapilmamissa sadece gurultu gorulecek olup Vpp degeri 12 mV civarinda olacaktir.

Frekans spektrumunda temel frekansta (63.5 kHz) baskin bir tepe ve harmoniklerde -48 dB'nin altinda zayif tepeler beklenir. Gurultu tabani -100 dB civarinda olmalidir.

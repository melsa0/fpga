# FPGA Proje Onerileri

ALINX AX7010 (Zynq-7000) karti ve mevcut modullerle yapilabilecek proje fikirleri.

## Mevcut Donanim

| Bilesen | Aciklama |
|---------|----------|
| FPGA Karti | ALINX AX7010 (XC7Z010CLG400-1) |
| DAC Modulu | AN9767 (AD9767, 14-bit) |
| ADC Modulu | AN9238 (AD9238, 12-bit, cift kanal, 65 MSPS) |
| Clock Ureteci | Si5351 (I2C, Arduino ile kontrol) |
| Olcum Cihazi | Digilent Analog Discovery 2 |
| Ekran | HDMI destekli monitor |
| Mikrodenetleyici | Arduino |

## Tamamlanan Projeler

1. **AD9767 DAC Sinus Cikisi + Analog Discovery 2 Olcum** - ROM tabanli sinus uretimi, DAC cikis, Python ile analiz
2. **AD9238 + AD9767 Loopback** - DAC-ADC dongu testi, HDMI osiloskop goruntusu
3. **Si5351 + AD9238 HDMI Osiloskop** - Harici clock kaynagi ile ADC okuma ve HDMI gosterim

---

## Onerilen Projeler

### Proje 1: DDS Fonksiyon Jeneratoru

**Seviye:** Orta

**Aciklama:**
Sinus, kare, ucgen ve testere dalga formlarini secilen frekanslarda ureten bir DDS (Direct Digital Synthesis) sistemi. Frekans ve dalga tipi kontrolu UART veya butonlar ile yapilir.

**Blok Diyagram:**
```
Buton/UART --> Kontrol Birimi --> Faz Akumulator --> Dalga LUT --> AN9767 DAC --> Analog Cikis
                                       |
                                  Frekans Ayar
                                  Registeri
```

**Ogrenilecekler:**
- DDS (Direct Digital Synthesis) mimarisi
- Faz akumulator tasarimi
- Dalga formu LUT (sinus, kare, ucgen, testere)
- UART haberlesme modulu (RX/TX)
- Frekans hassasiyeti ve cozunurluk hesaplari

**Kullanilacak Donanim:**
- FPGA (DDS cekirdegi) --> AN9767 DAC --> Analog Discovery 2 ile dogrulama

**Onerilen Adimlar:**
1. Faz akumulator modulu yaz (32-bit akumulator, frekans tuning word)
2. Sinus LUT'u mevcut sin1024.mem dosyasindan kullan
3. Kare, ucgen, testere dalga ureteclerini ekle
4. UART RX modulu ile PC'den frekans/dalga tipi komutlari al
5. DAC cikisini Analog Discovery 2 ile dogrula
6. HDMI ekranda uretilen dalga formunu goster

---

### Proje 2: Gercek Zamanli FIR Dijital Filtre

**Seviye:** Orta

**Aciklama:**
ADC'den gelen sinyale FPGA icinde gercek zamanli FIR (Finite Impulse Response) dijital filtre uygulanir. Filtrelenmis sinyal DAC'tan cikarilir. HDMI ekranda filtre oncesi ve sonrasi sinyaller yan yana karsilastirilir.

**Blok Diyagram:**
```
AN9238 ADC --> FPGA [Shift Register --> MAC Pipeline --> Akumulator] --> AN9767 DAC
                                    |                                        |
                              Katsayi ROM                              HDMI Gosterim
                                                                    (oncesi/sonrasi)
```

**Ogrenilecekler:**
- FIR filtre teorisi ve katsayi hesaplama
- Sabit noktali (fixed-point) aritmetik
- MAC (Multiply-Accumulate) pipeline tasarimi
- DSP48 slice kullanimi (Zynq)
- Filtre katsayilarinin MATLAB/Python ile hesaplanmasi

**Kullanilacak Donanim:**
- AN9238 ADC --> FPGA (FIR) --> AN9767 DAC + HDMI karsilastirma

**Onerilen Adimlar:**
1. Python scipy.signal ile alcak geciren filtre katsayilarini hesapla (ornegin 16 tap)
2. Katsayilari sabit noktali formata donustur ve ROM olarak FPGA'ya yukle
3. Shift register ve MAC pipeline modulu yaz
4. Loopback projesini temel alarak ADC giris --> filtre --> DAC cikis zinciri kur
5. HDMI ekranda iki kanal goster: ham sinyal ve filtrelenmis sinyal
6. Farkli filtre tipleri dene (alcak geciren, yuksek geciren, bant geciren)

---

### Proje 3: FFT Spektrum Analizoru

**Seviye:** Orta-Ileri

**Aciklama:**
ADC'den okunan sinyalin gercek zamanli FFT (Fast Fourier Transform) hesaplanir ve HDMI ekranda frekans spektrumu olarak gosterilir. Bar grafik veya waterfall gorunum secenekleri sunulur.

**Blok Diyagram:**
```
AN9238 ADC --> Windowing --> FFT Engine (Radix-2) --> Buyukluk Hesaplama --> HDMI Spektrum
                               |                          |
                         Twiddle Factor ROM          |X| = sqrt(Re^2 + Im^2)
                         (sin/cos tablolari)         veya log yaklasimi
```

**Ogrenilecekler:**
- Radix-2 DIT FFT butterfly mimarisi
- Twiddle factor ROM tasarimi
- Pipeline ve ping-pong buffer stratejileri
- Windowing fonksiyonlari (Hanning, Hamming, Blackman)
- Logaritmik olcek (dB) donusumu
- BRAM yonetimi ve veri akis kontrolu

**Kullanilacak Donanim:**
- AN9238 ADC --> FPGA (FFT + video) --> HDMI ekran

**Onerilen Adimlar:**
1. 256 veya 512 noktali Radix-2 FFT modulu yaz (butterfly + twiddle ROM)
2. Hanning window uygulama modulu ekle
3. Buyukluk hesaplama: basit |Re|+|Im| yaklasimi ile basla
4. HDMI gosterim modulunu bar grafik formatinda tasarla
5. Waterfall (zaman-frekans) gorunum ekle
6. Analog Discovery 2 ile bilinen frekansli sinyaller uygulayarak dogrula

---

### Proje 4: Dijital Iletisim Sistemi (BPSK/QPSK)

**Seviye:** Ileri

**Aciklama:**
FPGA icinde dijital modulator (BPSK veya QPSK) tasarlanir. Moduleli sinyal DAC'tan cikarilir, kablo ile ADC'ye baglanarak geri okunur ve demodulatorde cozulur. BER (Bit Error Rate) hesaplanir. Constellation diagram HDMI'da gosterilir.

**Blok Diyagram:**
```
PRBS Ureteci --> Modulator (BPSK/QPSK) --> AN9767 DAC
                                               |
                                          Analog Kablo
                                               |
HDMI (Constellation) <-- Demodulator <-- AN9238 ADC
        |
   BER Hesaplama
```

**Ogrenilecekler:**
- BPSK/QPSK modulasyon ve demodulasyon
- Tasiyici (carrier) uretimi ve kurtarma
- Sembol zamanlama senkronizasyonu
- Constellation diagram olusturma
- PRBS (Pseudo-Random Binary Sequence) ureteci
- BER hesaplama ve performans analizi

**Kullanilacak Donanim:**
- FPGA (modulator) --> AN9767 --> kablo --> AN9238 --> FPGA (demodulator) --> HDMI

**Onerilen Adimlar:**
1. PRBS ureteci yaz (LFSR tabanli)
2. BPSK modulator: bit --> {+1, -1} --> sinus carpimi --> DAC
3. DAC-ADC loopback bagla
4. Demodulatorde tasiyici carpimi ve alcak geciren filtre uygula
5. Sembol karar mekanizmasi ve bit cikartma
6. BER sayaci ve HDMI constellation diagram gosterimi
7. QPSK'ya genislet (I/Q kanallari)

---

### Proje 5: PID Kontrol Dongusu

**Seviye:** Orta

**Aciklama:**
DAC cikisi basit bir RC filtre devresinden gecirilip ADC ile okunur. FPGA icindeki PID kontrolcu hedef degere yakinsamayi saglar. Step response, overshoot, settling time gibi parametreler HDMI'da gosterilir.

**Blok Diyagram:**
```
Hedef Deger --> [+] --> PID Kontrolcu --> AN9767 DAC --> RC Filtre --> AN9238 ADC
                ^                                                         |
                |_______________________  Geri Besleme  __________________|

                              HDMI: Step Response Grafigi
```

**Ogrenilecekler:**
- PID kontrol teorisi (P, I, D terimleri)
- Sabit noktali aritmetik ile PID hesaplama
- Anti-windup teknikleri
- Step response analizi (overshoot, rise time, settling time)
- Gercek zamanli kontrol dongusu zamanlama gereksinimleri

**Kullanilacak Donanim:**
- FPGA (PID) --> AN9767 DAC --> RC filtre (breadboard) --> AN9238 ADC --> geri besleme
- HDMI gosterim

**Onerilen Adimlar:**
1. Breadboard uzerinde basit RC alcak geciren filtre kur (ornegin R=1k, C=100nF)
2. PID kontrolcu modulu yaz (P, I, D terimleri ayri ayri)
3. DAC cikis --> RC filtre --> ADC giris bagla
4. Hedef degeri butonlar veya UART ile ayarla
5. HDMI'da step response grafigi ciz (hedef cizgisi + gercek deger)
6. Kp, Ki, Kd parametrelerini degistirerek sistem davranisini gozlemle

---

### Proje 6: Logic Analyzer

**Seviye:** Orta

**Aciklama:**
FPGA'nin bos GPIO pinlerinden dijital sinyaller yuksek hizda orneklenir, BRAM'de circular buffer olarak saklanir ve trigger kosulu saglandiginda yakalanan veri HDMI'da veya UART uzerinden gosterilir.

**Blok Diyagram:**
```
Harici Dijital    --> Giris Ornekleyici --> Trigger --> Circular Buffer (BRAM)
Sinyaller (GPIO)      (65 MHz)            Modulu          |
                                            |         Yakalama Tamamlandi
                                       Trigger            |
                                       Kosulu       HDMI Gosterim / UART Cikis
                                    (edge/pattern)
```

**Ogrenilecekler:**
- Circular buffer ve BRAM yonetimi
- Trigger mekanizmalari (edge trigger, pattern trigger, level trigger)
- Yuksek hizli giris ornekleme
- Protokol decode temelleri (UART, SPI, I2C frame yapilari)
- Pre-trigger ve post-trigger veri yakalama

**Kullanilacak Donanim:**
- FPGA GPIO pinleri --> harici devre sinyalleri (Arduino SPI/I2C/UART)
- HDMI gosterim veya UART ile PC'ye aktarim

**Onerilen Adimlar:**
1. 8 kanalli giris ornekleyici modulu yaz
2. BRAM circular buffer (ornegin 4096 ornek derinlik) tasarla
3. Rising/falling edge trigger modulu ekle
4. Trigger sonrasi pre/post verilerini HDMI'da dijital dalga formu olarak goster
5. UART protokol decode modulu yaz (Arduino'dan UART sinyali yakala ve coz)
6. SPI ve I2C decode ekle

---

### Proje 7: Ses Isleme (Zynq PS-PL Entegrasyonu)

**Seviye:** Ileri

**Aciklama:**
Zynq'in ARM cekirdegini (PS) kullanarak bare-metal veya Linux yazilim calistirilir. ADC'den alinan ses sinyali FPGA'da (PL) gercek zamanli efekt islemeden gecirilir (echo, reverb, pitch shift) ve DAC'tan cikarilir. PS-PL arasindaki veri aktarimi AXI arayuzu ile yapilir.

**Blok Diyagram:**
```
Mikrofon --> Preamplifier --> AN9238 ADC --> FPGA PL [Efekt Isleme] --> AN9767 DAC --> Hoparlor
                                                |          ^
                                                v          |
                                            AXI Bus <--> ARM PS
                                                         (Kontrol,
                                                          Parametre
                                                          Ayarlari)
```

**Ogrenilecekler:**
- Zynq PS-PL entegrasyonu ve AXI arayuzu
- Vivado Block Design ve IP Integrator kullanimi
- Bare-metal veya embedded Linux gelistirme
- Ses efekt algoritmalari (delay line, feedback, mixing)
- HW/SW co-design prensipleri
- DMA (Direct Memory Access) ile yuksek hizli veri aktarimi

**Kullanilacak Donanim:**
- Mikrofon + preamplifier --> AN9238 ADC --> FPGA PL --> AN9767 DAC --> hoparlor/kulaklik
- ARM PS: parametre kontrolu (UART terminal veya Python GUI)

**Onerilen Adimlar:**
1. Vivado Block Design'da basit PS-PL sistemi olustur (AXI GPIO veya AXI Lite)
2. PL tarafinda basit echo efekti yaz (delay line + feedback)
3. PS tarafinda bare-metal uygulama ile efekt parametrelerini kontrol et
4. ADC --> efekt --> DAC zincirini kur ve test et
5. Reverb ve pitch shift efektleri ekle
6. UART terminal uzerinden parametre degisikliklerini canli yap

---

### Proje 8: UART Osiloskop Arayuzu (PC GUI)

**Seviye:** Baslangic-Orta

**Aciklama:**
ADC'den okunan veriler FPGA icinde UART TX modulu ile seri port uzerinden PC'ye gonderilir. Python ile yazilan GUI uygulamasi gercek zamanli osiloskop gorunumu saglar. Trigger, zoom, olcum ve kayit ozellikleri eklenir.

**Blok Diyagram:**
```
AN9238 ADC --> FPGA [Trigger + Buffer + UART TX] --> USB-UART --> PC
                                                                   |
                                                             Python GUI
                                                          (PyQt / Tkinter)
                                                               |
                                                    Gercek zamanli grafik
                                                    Trigger kontrol
                                                    Olcum araclari
                                                    CSV kayit
```

**Ogrenilecekler:**
- UART TX/RX modulu tasarimi (baud rate, start/stop bit, parity)
- Seri haberlesme protokolu tasarimi (paket yapisi, senkronizasyon)
- Python GUI gelistirme (PyQt5/6 veya Tkinter)
- Gercek zamanli grafik cizimi (pyqtgraph veya matplotlib animation)
- Trigger mekanizmasi (yazilim + donanim)

**Kullanilacak Donanim:**
- AN9238 ADC --> FPGA --> UART --> USB-Serial donusturucu --> PC

**Onerilen Adimlar:**
1. UART TX modulu yaz (115200 veya 921600 baud)
2. Basit paket protokolu tasarla (header + veri + checksum)
3. ADC verisini UART ile PC'ye gonder
4. Python'da seri port okuma ve gercek zamanli grafik cizimi yap
5. Trigger kontrolu ekle (FPGA tarafinda edge detect, PC'den komut)
6. Olcum araclari ekle (Vpp, frekans, RMS)
7. CSV kayit ve screenshot ozelligi ekle

---

## Onerilen Ogrenme Sirasi

Asagidaki sira, her projenin bir oncekinden ogrenilen kavramlar uzerine insa edilmesini saglar:

```
1. DDS Fonksiyon Jeneratoru          (DDS, LUT, UART temelleri)
      |
2. UART Osiloskop Arayuzu           (UART pekistirme, Python GUI)
      |
3. FIR Dijital Filtre               (DSP pipeline, sabit noktali aritmetik)
      |
4. FFT Spektrum Analizoru           (ileri DSP, butterfly, BRAM yonetimi)
      |
5. PID Kontrol Dongusu              (kontrol sistemleri, geri besleme)
      |
6. Logic Analyzer                   (trigger, protokol decode, BRAM)
      |
7. Dijital Iletisim (BPSK/QPSK)    (haberlesme, modem tasarimi)
      |
8. Ses Isleme (Zynq PS-PL)          (HW/SW co-design, AXI, embedded)
```

## Kaynaklar

- [ALINX AX7010 Wiki](http://www.alinx.com)
- [Xilinx Zynq-7000 TRM (UG585)](https://docs.amd.com/r/en-US/ug585-zynq-7000-TRM)
- [Vivado Design Suite User Guide](https://docs.amd.com/r/en-US/ug910-vivado-getting-started)
- [DSP ile FPGA Uygulamalari - nandland.com](https://nandland.com)
- [FPGA4Fun](https://www.fpga4fun.com)

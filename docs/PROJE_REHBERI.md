# Proje Rehberi: Si5351 + AD9238 HDMI Osiloskop

Bu belge, projenin basindan sonuna nasil gelistirildigini, karsilasilan sorunlari ve cozumlerini adim adim anlatir. Amac, bu projeyi tekrar denemek isteyen kisilerin ayni hatalara dusmemesidir.

---

## Icindekiler

1. [Projenin Amaci ve Buyuk Resim](#1-projenin-amaci-ve-buyuk-resim)
2. [Donanim Baglantilari](#2-donanim-baglantilari)
3. [FPGA Tasarim Sureci](#3-fpga-tasarim-sureci)
4. [Vivado Build Sureci ve Karsilasilan Hatalar](#4-vivado-build-sureci-ve-karsilasilan-hatalar)
5. [Dalga Formu Gorunmuyor Sorunu](#5-dalga-formu-gorunmuyor-sorunu)
6. [Arduino Si5351 Kodu](#6-arduino-si5351-kodu)
7. [Onemli Tasarim Kararlari](#7-onemli-tasarim-kararlari)
8. [Sik Yapilan Hatalar ve Ipuclari](#8-sik-yapilan-hatalar-ve-ipuclari)
9. [Prompt Gecmisi (AI Destekli Gelistirme)](#9-prompt-gecmisi-ai-destekli-gelistirme)

---

## 1. Projenin Amaci ve Buyuk Resim

**Hedef:** Arduino ile kontrol edilen Si5351 saat ureticisinden kare dalga sinyal uretmek, bu sinyali AN9238 modulu uzerindeki AD9238 ADC'ye gondermek ve FPGA icerisinde islenen veriyi HDMI uzerinden gercek zamanli osiloskop goruntusu olarak izlemek.

```
Sinyal Akisi:

Arduino --I2C--> Si5351 --CLK0/CLK1--> AN9238 SMA Giris
                                            |
                                     AD9238 (12-bit ADC, 65 MSPS)
                                            |
                                      FPGA (AX7010)
                                       /        \
                               adc_sampler    video_timing
                                    |              |
                              waveform_display + grid_overlay
                                            |
                                     rgb2dvi (TMDS)
                                            |
                                      HDMI Monitor
```

**Neden bu yaklasim?**
- Si5351, I2C ile kolayca kontrol edilebilen ucuz bir saat ureticisi
- 3.3V CMOS kare dalga cikisi, AD9238'in -5V..+5V araliginin ~%33'unu kaplar - gorunecek kadar buyuk
- 65 MSPS ornekleme hizi, MHz seviyesindeki sinyalleri goruntulemek icin yeterli
- HDMI cikis, herhangi bir monitorde gercek zamanli goruntuleme saglar

---

## 2. Donanim Baglantilari

### 2.1 Arduino -> Si5351

| Arduino Pin | Si5351 Pin | Not |
|-------------|-----------|-----|
| SDA (A4)    | SDA       | I2C veri hatti |
| SCL (A5)    | SCL       | I2C saat hatti |
| 3.3V        | VIN       | **5V DEGIL!** Si5351 modulu 3.3V ile calisir |
| GND         | GND       | Ortak toprak |

> **UYARI:** Bazi Si5351 breakout kartlarinda VIN pini 5V regulator icerden 3.3V'a dusurur. Ama bazi kartlarda dogrudan 3.3V gider. Kartinizin semasini kontrol edin.

### 2.2 Si5351 -> AN9238

| Si5351 Pin | AN9238 Pin | Not |
|-----------|-----------|-----|
| CLK0      | CH0 SMA   | Kanal 0 giris (SMA kablo ile) |
| CLK1      | CH1 SMA   | Kanal 1 giris (SMA kablo ile) |

> **UYARI:** SMA kablolar kullanmaniz gerekiyor. Jumper kablo ile baglantirsaniz yuksek frekanslarda sinyal bozulur.

### 2.3 AN9238 -> FPGA (AX7010)

AN9238 modulu AX7010 kartinin **J11** expansion soketine **dogrudan** takilir. Ek kablolama gerekmez.

J11 soketindeki pin eslestirmesi:

**Kanal 0:**
- CLK: H17
- DATA[0]: J20, DATA[1]: H20, DATA[2]: L16, DATA[3]: L17
- DATA[4]: M17, DATA[5]: M18, DATA[6]: D19, DATA[7]: D20
- DATA[8]: E18, DATA[9]: E19, DATA[10]: G17, DATA[11]: G18

**Kanal 1:**
- CLK: F17
- DATA[0]: F16, DATA[1]: F20, DATA[2]: F19, DATA[3]: G20
- DATA[4]: G19, DATA[5]: H18, DATA[6]: J18, DATA[7]: L20
- DATA[8]: L19, DATA[9]: M20, DATA[10]: M19, DATA[11]: K18

> **KRITIK:** Bu pin atamalari Alinx AX7010 kartina ozeldur. Baska bir FPGA karti kullaniyorsaniz, o kartin expansion header pin eslestirmesini kontrol edip `pins.xdc` dosyasini buna gore guncelleyin.

### 2.4 FPGA -> HDMI

AX7010 kartinin yerlesik HDMI konektoru kullanilir. Ek donanim gerekmez.

- TMDS Clock: N18 (pozitif)
- TMDS Data[0]: V20 (pozitif)
- TMDS Data[1]: T20 (pozitif)
- TMDS Data[2]: N20 (pozitif)
- HDMI Output Enable: V16

---

## 3. FPGA Tasarim Sureci

### 3.1 Referans Tasarimdan Yola Cikma

Proje, Alinx'in `18_ad9238_hdmi` referans tasarimindan esinlenerek yazildi. Referans tasarimda su moduller vardi:

| Referans Modul | Bu Projede | Degisiklik |
|----------------|-----------|------------|
| `video_pll` + `adc_pll` | `clk_wiz_0` | 2 ayri PLL yerine tek clk_wiz IP kullanildi |
| `color_bar` | `video_timing_720p` | Color bar yerine siyah arka plan |
| `grid_display` | `grid_overlay` | Ayni mantik, modul icinde timing_gen_xy birlesti |
| `ad9238_sample` | `adc_sampler` | Ayni state machine: IDLE -> SAMPLE -> WAIT |
| `wav_display` + `dpram2048x8` | `waveform_display` | Ayri IP yerine inferred BRAM kullanildi |
| `timing_gen_xy` | Her module gomuldu | Pixel konum izleme her module eklendi |
| `rgb2dvi_0` | `rgb2dvi_0` | Ayni IP, degisiklik yok |

### 3.2 Neden Tek clk_wiz_0?

XC7Z010 cipsinde sadece **2 adet MMCM** (Mixed-Mode Clock Manager) vardir. Referans tasarimda 2 ayri PLL kullaniliyor (video_pll + adc_pll). Biz tek clk_wiz_0 ile 3 clock urettik:

| Cikis | Frekans | Kullanim |
|-------|---------|----------|
| clk_out1 | ~74.25 MHz | Piksel saati (1280x720 @ 60Hz) |
| clk_out2 | ~371.25 MHz | TMDS seri saati (piksel x 5) |
| clk_out3 | ~65 MHz | ADC ornekleme saati |

Bu yaklasim 1 MMCM tasarruf eder ve ileride baska IP icin MMCM kullanma imkani birakir.

### 3.3 Neden Inferred BRAM?

Referans tasarimda `dpram2048x8` isimli ozel bir IP core kullaniliyordu. Bu IP'yi Vivado'da yeniden olusturmak yerine, Verilog kodunda dogrudan RAM tanimlayarak sentezleyicinin otomatik olarak Block RAM cikarmasini (inference) sagladik:

```verilog
(* ram_style = "block" *) reg [7:0] sample_ram [0:2047];

// Yazma portu (ADC clock domain)
always @(posedge adc_clk) begin
    if (adc_buf_wr)
        sample_ram[adc_buf_addr] <= adc_buf_data;
end

// Okuma portu (Piksel clock domain)
always @(posedge pclk) begin
    q <= sample_ram[rdaddress];
end
```

**Avantajlari:**
- Ayri IP olusturmaya gerek yok
- Kod tasinabilir (baska FPGA ailelerine kolayca uyarlanir)
- `(* ram_style = "block" *)` attribute'u ile sentezleyici Block RAM kullanmaya zorlanir
- Cift portlu (dual-port): bir port ADC clock ile yazar, diger port piksel clock ile okur

### 3.4 Video Pipeline Yapisi

Video sinyali su sirayla islenir (pipeline):

```
video_timing_720p  -->  grid_overlay  -->  waveform_display (CH0, Kirmizi)
                                                  |
                                           waveform_display (CH1, Mavi)
                                                  |
                                              rgb2dvi_0  -->  HDMI
```

Her modul giren video sinyaline (hs, vs, de, data) mudahale eder ve cikisini bir sonraki module iletir. Bu "daisy-chain" yaklasimi sayesinde her modul bagimsiz calisir.

### 3.5 Dalga Formu Cizim Mantigi

ADC'den okunan 12-bit veri once 8-bit'e dusurulur (ust 8 bit alinir):

```verilog
adc_data_narrow <= adc_data[11:4];
```

Ekranda dalga formu su sekilde cizilir:

```verilog
// q: RAM'den okunan ornek degeri (0-255)
wire [11:0] wave_y_pos = {4'd0, q};          // 0-255 arasi Y pozisyonu
wire [11:0] screen_y   = 12'd287 - pos_y;    // Ekran Y'si ters cevirildi (asagi = 0)
wire signed [12:0] y_diff = screen_y - wave_y_pos;
wire wave_hit = (y_diff == 0) || (y_diff == 1) || (y_diff == -1);  // 3 piksel kalinlik
```

**Onemli:** `y_diff` kontrolunde `== 0, 1, -1` kullanarak 3 piksel kalinliginda cizim yapilir. Baslangicta sadece `== 0` vardi ve dalga formu 1 piksel ince oldugu icin gorunmuyordu.

---

## 4. Vivado Build Sureci ve Karsilasilan Hatalar

### 4.1 HATA: Dosya Yolunda Bosluk ve Parantez

**Sorun:** Proje dosyalari `fpga_asist_dev-master (1)` klasorundeydi. Vivado, yoldaki bosluk ve parantezi handle edemedi.

```
ERROR: [ProjectBase 2-104] Project name ... is illegal. Invalid character ( found.
ERROR: [Vivado 12-172] File or Directory 'C:/Users/melsa/OneDrive/Desktop/fpga_asist_dev-master' does not exist
```

**Cozum:** Tum kaynak dosyalari bosluk/parantez icermeyen temiz bir dizine kopyaladik:
```
C:/vivado_builds/src/           -> Verilog dosyalari
C:/vivado_builds/constraints/   -> XDC dosyasi
C:/vivado_builds/ip_repo/       -> rgb2dvi IP
C:/vivado_builds/project/       -> Vivado proje dizini
```

> **DERS:** Vivado ile calisirken dosya yollarinda **bosluk, Turkce karakter, parantez** bulundurmamaya ozen gosterin. En guvenli yol `C:/vivado_builds/` gibi kisa, ASCII-only bir dizin kullanmaktir.

### 4.2 HATA: sample_buffer Erisim Hatasi

**Sorun:** Ilk tasarimda top modulu icinde dogrudan RAM dizisine erismek hata verdi.

```
ERROR: [Synth 8-9210] cannot access memory 'sample_buffer' directly
```

**Cozum:** RAM erisimini ayri bir modul (`waveform_display`) icerisine tasidik. Vivado, modul ici RAM inference'i daha iyi handle ediyor.

### 4.3 HATA: IP Repo Bulunamadi

**Sorun:** `rgb2dvi` IP core'u Digilent'e ait ozel bir IP. Vivado bunu standart IP katalogundan bulamaz.

**Cozum:**
1. Alinx referans projesindeki `my_ip` klasorunu bulduk (icinde `rgb2dvi_v1_3` var)
2. Bu klasoru `C:/vivado_builds/ip_repo/` altina kopyaladik
3. `build_project.tcl` icinde `ip_repo_path` olarak bu dizini gosterdik:
   ```tcl
   set_property ip_repo_paths $ip_repo_path [current_project]
   update_ip_catalog
   ```

> **NOT:** rgb2dvi IP'sini Digilent'in GitHub sayfasindan da indirebilirsiniz:
> `https://github.com/Digilent/vivado-library` -> `ip/rgb2dvi`

### 4.4 HATA: Vivado GUI Acilamadi

**Sorun:** Vivado GUI'yi komut satirindan acmaya calisirken yol parcalamasi oldu.

```
ERROR: [Common 17-1257] Failed to create directory 'C'.
```

**Cozum:** Bir `.bat` dosyasi olusturup icinden Vivado'yu cagirmak:
```bat
@echo off
cd /d C:\vivado_builds\project_v2
"C:\Xilinx\2025.1\Vivado\bin\vivado.bat" -mode gui oscilloscope_v2.xpr
```

### 4.5 HATA: Rebuild Sirasinda "Permission Denied"

**Sorun:** Vivado GUI acikken ayni proje dizinine yeniden build yapilmaya calisildi.

```
error deleting "vivado.pb": permission denied
```

**Cozum:** Ya Vivado GUI'yi kapatin, ya da yeni bir proje dizini kullanin (ornegin `project_v2`).

### 4.6 Basarili Build Akisi

Sonuc olarak basarili build su adimlarla gerceklesti:

```
1. Kaynak dosyalari C:/vivado_builds/src/ altina kopyala
2. Constraints'i C:/vivado_builds/constraints/ altina kopyala
3. IP repo'yu C:/vivado_builds/ip_repo/ altina kopyala
4. build_project.tcl'deki yollari guncelle
5. Vivado'yu batch modda calistir:
   vivado -mode batch -source build_project.tcl
6. Sentez (~2-3 dk) -> Implementation (~2-3 dk) -> Bitstream (~1 dk)
7. Bitstream: project/oscilloscope.runs/impl_1/si5351_ad9238_hdmi_top_test.bit
```

---

## 5. Dalga Formu Gorunmuyor Sorunu

### Belirtiler
- HDMI monitorde siyah arka plan ve koyu sari izgara gorunuyordu
- Ancak kirmizi/mavi dalga formu gorunmuyordu

### Neden?
Iki ana sebep vardi:

**1. Dalga formu cok inceydi (1 piksel):**
720 piksel yuksekliginde bir ekranda 1 piksel kalinliginda bir cizgi neredeyse gorunmez. Ozellikle ADC verisi gurultulu oldugunda, her satirin farkli bir Y pikselinde olmasi cizgiyi dagitiyordu.

**Cozum:** 3 piksel kalinliginda cizim:
```verilog
// Onceki (gorunmez):
wire wave_hit = (y_diff == 0);

// Sonraki (gorunur):
wire wave_hit = (y_diff == 0) || (y_diff == 1) || (y_diff == -1);
```

**2. Arduino kodu yazilmamisti:**
Si5351'i kontrol eden Arduino kodu olmadan, ADC girisine sinyal gelmiyordu. Sinyal yoksa dalga formu da gorulmez.

**Cozum:** Arduino kodu yazildi (detay Bolum 6'da).

---

## 6. Arduino Si5351 Kodu

### 6.1 Kutuphane

`Adafruit SI5351` kutuphanesi kullanildi. Arduino IDE -> Library Manager -> "Adafruit SI5351" aratip yukleyin.

### 6.2 Frekans Hesaplama Mantigi

Si5351 iki asamali frekans bolme kullanir:

```
Kristal (25 MHz) --> PLL (x Multiplier) --> Multisynth (/ Divider) --> Cikis
```

Ornek: 1 MHz cikis icin:
```
PLL_A = 25 MHz * 24 = 600 MHz
CLK0  = 600 MHz / 600 = 1 MHz
```

```c
clockgen.setupPLL(SI5351_PLL_A, 24, 0, 1);        // 600 MHz
clockgen.setupMultisynth(0, SI5351_PLL_A, 600, 0, 1);  // 1 MHz
```

### 6.3 Gorunurluk Icin Dogru Frekans Secimi

ADC ornekleme hizi ~65 MSPS oldugunda:

| Sinyal Frekansi | Ornek/Periyot | Gorunurluk |
|----------------|---------------|------------|
| 100 kHz        | 650           | Cok fazla ornek, ekrana sigmiyor |
| 500 kHz        | 130           | Iyi |
| 1 MHz          | 65            | **Ideal** - net kare dalga |
| 2 MHz          | 32            | Gorunur ama kenarlar kayip |
| 5 MHz          | 13            | Zor gorunur |
| 10 MHz+        | <7            | Neredeyse gorunmez |

> **ONERI:** Ilk testte 1 MHz kullanin. Ekranda net bir kare dalga gorunmeli.

### 6.4 Serial Monitor ile Frekans Degistirme

Arduino kodunda Serial Monitor'den karakter gondererek frekans degistirilebilir:
- `1` -> ~667 kHz
- `2` -> 1 MHz
- `3` -> 2 MHz
- `4` -> 5 MHz

---

## 7. Onemli Tasarim Kararlari

### 7.1 ADC Verisi: 12-bit -> 8-bit Donusum

AD9238, 12-bit veri uretir (0-4095). Ekranda 300 piksel yuksekliginde bir bolge var. 12-bit veriyi dogrudan kullanmak gereksiz hassasiyet saglar. Bu yuzden ust 8 bit (0-255) alinir:

```verilog
adc_data_narrow <= adc_data[11:4];
```

Bu, 300 piksel yukseklige rahatca sigar ve BRAM kullanimini azaltir (8-bit vs 12-bit).

### 7.2 Ornekleme Stratejisi: 1280 Ornek + Bekleme

`adc_sampler` modulu bir "capture" mimarisi kullanir:

1. **SAMPLE:** 1280 ornegi hizla topla (ekranin yatay cozunurlugune esit)
2. **WAIT:** 25 milyon saat cevriminde bekle (~0.38 saniye @ 65 MHz)
3. Tekrarla

Bu yaklasim sayesinde:
- Her seferinde ekran genisligine tam uyan veri toplanir
- Bekleme suresi goz icin yeterli yenileme hizi saglar (~2.5 FPS)
- BRAM'a surekli yazma yerine kontrollü yazma yapilir

### 7.3 Cift Kanal Pipeline

Video pipeline'da iki `waveform_display` modulu seri baglidir:

```
grid_overlay -> waveform_display(CH0, Kirmizi) -> waveform_display(CH1, Mavi) -> HDMI
```

Bu sayede her kanal bagimsiz olarak kendi renginde cizilir. CH0 kirmizi, CH1 mavi.

### 7.4 Grid Cizimi

Osiloskop izgarasi su konumlarda cizilir:
- **y=287:** Alt cizgi (referans cizgisi)
- **y=32:** Ust cizgi
- **y=159:** Orta cizgi
- **Dikey noktalar:** Her 10 pikselde bir, sadece tek y'lerde (noktali cizgi efekti)

Renk: Koyu sari (RGB = 139, 129, 29) - siyah arka planda gorunur ama dalga formunu gizlemeyecek kadar soluk.

---

## 8. Sik Yapilan Hatalar ve Ipuclari

### Hatalar

| # | Hata | Cozum |
|---|------|-------|
| 1 | Vivado yolunda bosluk/parantez | Projeyi `C:/vivado_builds/` gibi temiz bir dizine tasi |
| 2 | rgb2dvi IP bulunamadi | Digilent IP repo'sunu indirip `ip_repo_paths` ayarla |
| 3 | Dalga gorunmuyor | 3 piksel kalinlik kullan, Arduino kodu yukle, dogu frekans sec |
| 4 | Build sirasinda "permission denied" | Vivado GUI'yi kapat veya yeni proje dizini kullan |
| 5 | AN9238 takiliyken FPGA programlanmiyor | Once FPGA'yi programla, sonra AN9238'i tak |
| 6 | Ekranda sadece gurultu gorunuyor | SMA kablolari kontrol et, Si5351'in dogru frekansta urettiginden emin ol |
| 7 | HDMI'da goruntu yok | hdmi_oen pininin (V16) dogru atandigindan emin ol, TMDS_33 IO standardini kontrol et |
| 8 | Sentez hatasi: "cannot access memory" | RAM erisimini ayri module tasi, inferred BRAM kullan |

### Ipuclari

1. **Ilk testte dahili test sinyali kullanin:** `test_square_wave_gen.v` dosyasi, harici donanim olmadan dalga formu goruntulemek icin kullanilabilir. Top module'de `adc_sampler` yerine `test_square_wave_gen`'i baglayin.

2. **Vivado'da timing hatalari aliyorsaniz:** `clk_wiz_0`'in urettigi frekanslar tam istenen degerler olmayabilir (ornegin 74.25 yerine 74.17 MHz). Bu kucuk sapmalar 720p video icin kabul edilebilir.

3. **XC7Z010'da kaynak limiti:** Bu cip kucuktur (17,600 LUT, 2 MMCM). Eger tasariminizi genisletmek istiyorsaniz MMCM sayisina dikkat edin.

4. **Clock domain crossing:** ADC clock (~65 MHz) ile piksel clock (~74.25 MHz) farkli domainlerde. Inferred dual-port BRAM bu gecisi otomatik handle eder cunku her port kendi clock'unu kullanir.

5. **build_project.tcl'yi calistirmadan once:** `base_dir`, `src_dir`, `constr_dir` ve `ip_repo_path` degiskenlerini kendi sisteminize gore guncelleyin.

---

## 9. Prompt Gecmisi (AI Destekli Gelistirme)

Bu proje, Claude Code (AI asistan) ile birlikte gelistirildi. Asagida kullanilan promptlar ve her birinde AI'in dusunce sureci yer almaktadir.

### Prompt 1: "Projeyi bul ve Vivado'da sentezle"

> *"ssi5351_ad9238_hdmi_project dosyasini bul icinde vivado kodu olmali o kodu vivado guide ac sentele implementation yao ve bitstream yap"*

**AI Dusunce Sureci:**
- Oncelikle dosya sisteminde projeyi aradim
- Kaynak Verilog dosyalarinin **0 byte** (bos) oldugunu kesfettim
- Vivado'nun konumunu aradim: `C:\Xilinx\2025.1\Vivado\bin\vivado.bat`
- Bos dosyalarla sentez yapilamayacagi icin once kod yazmam gerektigini anladim

### Prompt 2: "Kodlari yaz ve sentezle"

> *"sen constraine erisebilir musun olay su ben 7010dan hdmila ardunioda urettigim sinyali gormek istiyorum bunu yaparken LAB_DENEYLERI.docx bu dosyadan yararlanmak ve 2. projeyi yapiyoruz buna uygun kodu yaz vivado guide ac sentezle"*

**AI Dusunce Sureci:**
- LAB_DENEYLERI.docx dosyasini okumam gerekti (.docx binary oldugu icin Python ile extract ettim)
- Proje 2'nin gereksinimlerini cikarttim: Si5351 + AD9238 + HDMI
- Referans tasarimi (`18_ad9238_hdmi`) inceledim: `top.v`, `ad9238_sample.v`, `wav_display.v`, `grid_display.v`, `color_bar.v`, `timing_gen_xy.v`
- Referans tasarimdaki modulleri anladim ve basitlestirdim:
  - 2 PLL yerine 1 clk_wiz_0
  - dpram2048x8 IP yerine inferred BRAM
  - timing_gen_xy'yi her module gomdum
- XDC pin atamalarini referanstan aldim
- `build_project.tcl` yazarak batch modda Vivado'yu calistirdim

### Prompt 3: "Vivado yol hatalarini duzelt"

> *"errorleri duzelt [Common 17-1257] Failed to create directory 'C'."*

**AI Dusunce Sureci:**
- Hata mesajindan yolun parcalandigini anladim
- Windows'ta bosluklu yollar Vivado TCL interpreter'ini bozuyor
- Cozum: Tum dosyalari `C:/vivado_builds/` altina kopyaladim
- TCL scriptindeki yollari guncelledim
- Build tekrar calisti ve basarili oldu

### Prompt 4: "Dalga formu gorunmuyor"

> *"goruntu cikti ancak goruntude kare dalga goremiyorum bunu nasil duzeltiriz acaba arduino icindeki kod degisse nasil olur"*

**AI Dusunce Sureci:**
- Grid gorunuyor demek video pipeline calisiyor
- Dalga gorunmuyor: ya ADC'den veri gelmiyor ya da cizim cok ince
- Iki sorunu birden cozdum:
  1. `waveform_display.v`'de 1-piksel cizimi 3-piksele cikardim
  2. Arduino Si5351 kodu yazdim (dogru frekans secimi onemli)
- ADC ornekleme hizi 65 MSPS -> 1 MHz sinyal icin periyot basina 65 ornek = gorunur
- Rebuild yaptim

### Prompt 5: "Arduino IDE'yi ac"

> *"arduino ide guide ac kodu"*

**AI Dusunce Sureci:**
- Arduino IDE'nin yolunu buldum: `C:\Users\melsa\AppData\Local\Programs\Arduino IDE\Arduino IDE.exe`
- PowerShell `Start-Process` ile actim
- Kullaniciya Adafruit SI5351 kutuphanesini yuklemesini soyledim

### Prompt 6: "Projeyi organize et ve README ekle"

> *"tamam calisti simdi bunlari fpga dev assist klasorunu besle bu yaptigim projeyle her dosyayi ekle ve readme olarak proje amacini ekle"*

**AI Dusunce Sureci:**
- Proje dizin yapisini olustururdum
- Tum kaynak dosyalari, constraint, bitstream, Arduino kodunu kopyaladim
- Kapsamli bir README.md yazdim (donanim, baglanti, dosya yapisi, kullanim)

### Prompt 7: "GitHub repo olustur"

> *"repo olustur bu dosyalardan olusan o repoya da bunu pushla repoda 2 branch bulunsun branchlerden biri alinx biri nexys olsun bu alinx oldugu icin alinx altina pushla"*

**AI Dusunce Sureci:**
- GitHub CLI (gh) kurdum
- Tarayici uzerinden GitHub authentication yaptim
- Temiz bir dizine sadece gerekli dosyalari kopyaladim (Vivado gecici dosyalari haric)
- `git init` -> `commit` -> `gh repo create` -> `push`
- `alinx` (default) ve `nexys` branch'lerini olusturdum

---

## Ek: Hizli Baslangic Kontrol Listesi

Projeyi sifirdan tekrarlamak isteyenler icin:

- [ ] AX7010 karti + AN9238 modulu + Si5351 breakout + Arduino hazir mi?
- [ ] SMA kablosu var mi? (Si5351 -> AN9238 baglantisi icin)
- [ ] Vivado 2025.1 (veya uyumlu surum) yuklu mu?
- [ ] Digilent rgb2dvi IP'si `ip_repo` dizinine kopyalandi mi?
- [ ] `build_project.tcl`'deki yollar sisteminize gore guncellendi mi?
- [ ] Yolda bosluk/parantez/Turkce karakter yok, degil mi?
- [ ] Arduino IDE'de "Adafruit SI5351" kutuphanesi yuklu mu?
- [ ] HDMI kablosu ve monitor hazir mi?

Hepsine "evet" dediyseniz:

```bash
# 1. FPGA bitstream olustur
vivado -mode batch -source build_project.tcl

# 2. Vivado GUI ile bitstream'i yukle
#    Hardware Manager -> Open Target -> Program Device

# 3. Arduino kodunu yukle
#    Arduino IDE -> si5351_ad9238_test.ino -> Upload

# 4. HDMI monitorde kirmizi ve mavi kare dalga gorunmeli!
```

---

*Bu belge, projenin AI destekli gelistirme surecini belgelemek ve gelecek kullanicilara rehberlik etmek amaciyla olusturulmustur.*

# Nexys Video FPGA Projeleri

Bu repo, **Digilent Nexys Video** (Xilinx Artix-7 XC7A200T) FPGA gelistirme karti uzerinde gerceklestirilen 4 ornek projeyi icermektedir.

## Projeler

| # | Proje | Aciklama | Klasor |
|---|-------|----------|--------|
| 1 | **Switch-LED** | 8 switch'in durumunu dogrudan 8 LED'e aktaran kombinasyonel devre | [`switch_led_example/`](switch_led_example/) |
| 2 | **Button-LED** | 5 buton ile 3 farkli modda (Position, Volume, All) LED kontrolu. Debounce ve edge detection icermektedir | [`btn_led_example/`](btn_led_example/) |
| 3 | **Switch-OLED** | 8-bit switch degerini (0-255) ondalik sayi olarak OLED ekranda gosteren tasarim. SPI haberlesme, karakter kutuphane ROM ve piksel buffer icermektedir | [`switch_oled_example/`](switch_oled_example/) |
| 4 | **Pong Oyunu** | OLED ekranda oynanan klasik Pong oyunu. Top fizigi, skor takibi, paddle kontrolu ve Game Over ekrani icermektedir | [`pong_example/`](pong_example/) |

## Hedef Kart

- **Kart:** Digilent Nexys Video
- **FPGA:** Xilinx Artix-7 XC7A200T (xc7a200tsbg484-1)
- **Araclar:** Xilinx Vivado

## Proje Yapisi

Her proje klasoru asagidaki dosyalari icerir:

```
proje_klasoru/
  *.v                    # Verilog kaynak dosyalari
  *.xdc                  # Pin atamasi (constraints) dosyasi
  build_and_program.tcl  # Vivado otomasyon scripti
  RAPOR_*.pdf            # Proje raporu (Turkce)
```

## Derleme ve Programlama

Her proje icin Vivado TCL konsolu uzerinden tek komutla derleme ve programlama yapilabilir:

```tcl
source build_and_program.tcl
```

Bu script sirasyla sentez, implementasyon, bitstream uretimi ve JTAG uzerinden programlama adimlarini otomatik olarak gerceklestirir.

## Proje Detaylari

### 1. Switch-LED (`switch_led_example/`)
En temel kombinasyonel lojik ornegi. 8 adet slide switch dogrudan 8 LED'e baglanmistir (`assign LED = SW`).

**Dosyalar:**
- `switch_to_led.v` - Ana modul
- `nexys_video_switch_led.xdc` - Pin atamalari
- `build_and_program.tcl` - Derleme scripti
- `RAPOR_Switch_LED.pdf` - Proje raporu

### 2. Button-LED (`btn_led_example/`)
5 buton (Up, Down, Left, Right, Center) ile LED'leri kontrol eden tasarim. 3 farkli calisma modu:
- **Position modu:** Tek LED saga-sola hareket eder
- **Volume modu:** LED'ler bar grafik seklinde artar/azalir
- **All modu:** Tum LED'ler yanar

**Dosyalar:**
- `btn_led_top.v` - Ana modul (debouncer + edge detector + state machine)
- `nexys_video_btn_led.xdc` - Pin atamalari
- `build_and_program.tcl` - Derleme scripti
- `RAPOR_Button_LED.pdf` - Proje raporu

### 3. Switch-OLED (`switch_oled_example/`)
Switch degerini OLED ekranda "SW: XXX" formatinda gosteren tasarim. Binary-to-BCD donusumu ve SSD1306 OLED surucu icermektedir.

**Dosyalar:**
- `switch_oled_top.v` - Ust modul (BCD donusumu + kontrol)
- `OLEDCtrl.v` - OLED kontrolcu (init, write, update, display on/off)
- `SpiCtrl.v` - SPI master haberlesme
- `charLib.v` - Karakter font ROM (5x8 bitmap)
- `delay_ms.v` - Milisaniye gecikme modulu
- `init_sequence_rom.v` - OLED baslangic komut dizisi
- `pixel_buffer.v` - Cift portlu RAM (goruntu arabellek)
- `nexys_video_sw_oled.xdc` - Pin atamalari
- `build_and_program.tcl` - Derleme scripti
- `RAPOR_Switch_OLED.pdf` - Proje raporu

### 4. Pong Oyunu (`pong_example/`)
OLED ekranda calistirilabilen klasik Pong oyunu. Sol ve sag butonlarla paddle kontrol edilir.

**Ozellikler:**
- Top fizigi ve carpisma algilama
- Skor takibi (onlar ve birler)
- ~3 saniye Game Over ekrani
- ~30 Hz oyun dongusu

**Dosyalar:**
- `pong_top.v` - Ust modul (buton debounce + oyun clock)
- `pong_game.v` - Oyun mantigi (fizik + rendering + skor)
- `oled_driver.v` - OLED surucu (init + refresh)
- `SpiCtrl.v` - SPI master haberlesme
- `delay_ms.v` - Milisaniye gecikme modulu
- `nexys_video_pong.xdc` - Pin atamalari
- `build_and_program.tcl` - Derleme scripti
- `RAPOR_Pong_Oyunu.pdf` - Pong oyunu raporu
- `RAPOR_Brick_Breaker.pdf` - Brick Breaker varyanti raporu

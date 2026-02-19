# FPGA ve AN9767 DAC Isterleri

Bu dokuman, ALINX AX7010 FPGA karti uzerinde AN9767 (AD9767) DAC modulu ile sinus dalgasi uretimi icin gerekli tum yazilim ve donanim isterlerini tanimlar.


## Genel Tanim

Sistem, FPGA uzerinde saklanan bir sinus dalga tablosunu (ROM) belirli bir saat frekansinda okuyarak AD9767 DAC'a 14-bit paralel veri gonderir. DAC bu dijital veriyi analog voltaja cevirir ve cikis pinlerinden sinus dalgasi olarak verir. Sistemde iki bagimsiz DAC kanali (DA1 ve DA2) bulunur ve her ikisi de ayni sinus verisini alir.


## Donanim Isterleri

FPGA karti olarak ALINX AX7010 kullanilacaktir. Bu kart Xilinx Zynq-7000 ailesinden XC7Z010CLG400-1 yongasini icerir. Kart uzerinde 50 MHz kristal osilator bulunmaktadir ve bu osilator U18 pinine baglidir.

DAC modulu olarak ALINX AN9767 kullanilacaktir. Bu modul Analog Devices AD9767 yongasini icerir. AD9767 cift kanalli 14-bit dijital-analog donusturucu olup, her kanal icin ayri saat (CLK), yazma (WRT) ve 14-bit veri hatti gerektirir. Modul, AX7010 kartinin J10 genisleme basligina takilacaktir.

Reset icin kart uzerindeki buton kullanilacak olup bu buton N15 pinine baglidir ve aktif-dusuk (active-low) calisir. Yani butona basildiginda sinyal 0'a duser ve sistem sifirlanir.


## Saat Uretimi Isterleri

Sistem saati olarak 50 MHz giris saati kullanilacaktir. Bu saat, FPGA icindeki tek bir MMCM (Mixed-Mode Clock Manager) blogu ile 65 MHz DAC saatine donusturulecektir. MMCM konfigurasyonu icin Xilinx clk_wiz_0 IP cekirdegi kullanilacaktir. MMCM'nin reset girisi aktif-yuksek (active-high) olacak ve dis reset butonunun tersi (rst_n'in degili) baglanacaktir. MMCM cikisinda locked sinyali bulunacak ve PLL kilitleninceye kadar sistem reset durumunda kalacaktir.

Sistemin dahili reset sinyali, dis reset butonunun aktif olmasi VEYA PLL'in henuz kilitlenmemis olmasi durumlarinda aktif olacaktir. Bu mantik sys_rst = ~rst_n | ~pll_locked seklinde tanimlanir.


## Sinus Dalga Ureteci Isterleri

Sinus dalgasi uretimi ROM tabanli olacaktir. ROM'da 1024 adet ornek bulunacak ve her ornek 14-bit genisliginde olacaktir. Veriler sin1024.mem dosyasindan hexadecimal formatta yuklenecektir.

ROM veri formati unsigned offset binary olacaktir. Minimum deger 0x0001, maksimum deger 0x3FFF ve orta nokta (sifir gecisi) 0x2000 olacaktir. Bu format, AD9767 DAC'in bekledibi giris formatina uygundur.

Adres sayaci 10-bit genisliginde olacak ve her saat darbesinde 1 artirilacaktir. Sayac 0'dan 1023'e kadar sayacak ve otomatik olarak basa donecektir (10-bit tasma ile). ROM'dan okunan 14-bit deger dogrudan DAC veri cikisina atanacaktir.

Reset durumunda adres sayaci 0'a, DAC verisi ise orta nokta degeri olan 0x2000'e ayarlanacaktir.

Cikis frekansi hesabi su sekildedir: f_out = f_clk / (ROM_boyutu / adres_adimi). Mevcut ayarlarla f_out = 65 MHz / (1024 / 1) = 63.5 kHz olarak hesaplanir. Frekans degistirmek icin adres adimi parametresi degistirilir. Adres adimi 1 iken 63.5 kHz, 2 iken 127 kHz, 4 iken 254 kHz, 8 iken 508 kHz ve 16 iken 1.016 MHz cikis frekansi elde edilir.


## DAC Arayuz Isterleri

Her iki DAC kanali (DA1 ve DA2) icin ayri saat, yazma ve veri sinyalleri bulunacaktir. DA1 kanali icin da1_clk, da1_wrt ve da1_data[13:0] sinyalleri, DA2 kanali icin da2_clk, da2_wrt ve da2_data[13:0] sinyalleri tanimlanacaktir.

Her iki kanalin saat ve yazma sinyalleri dogrudan DAC saatine (dac_clk, 65 MHz) baglanacaktir. Her iki kanalin veri sinyalleri ayni sinus verisine (sine_data) baglanacaktir. Bu sayede her iki kanaldan es zamanli ve ayni fazda sinus dalgasi cikar.

DAC veri cikisi, ROM adresinin her saat darbesinde guncellenmesiyle senkron olarak degisecektir. Veri gecerliligi, CLK ve WRT sinyallerinin ayni saat kaynagindan suruluyor olmasi ile garanti edilir.


## Pin Atamasi Isterleri

Tum pinler LVCMOS33 IO standardini kullanacaktir. Sistem saati U18 pinine, reset butonu N15 pinine atanacaktir.

DA1 kanali icin saat pini W19, yazma pini W18 olacaktir. DA1 veri pinleri en yuksek bitten (bit 13) en dusuk bite (bit 0) dogru sirasiyla R14, P14, Y17, Y16, W15, V15, Y14, W14, P18, N17, U15, U14, P16 ve P15 olacaktir.

DA2 kanali icin saat pini U17, yazma pini T16 olacaktir. DA2 veri pinleri en yuksek bitten en dusuk bite dogru sirasiyla V18, V17, T15, T14, V13, U13, W13, V12, U12, T12, T10, T11, A20 ve B19 olacaktir.

Sistem saati icin 20 ns periyotlu (50 MHz) saat kisitlamasi tanimlanacaktir.


## Vivado Derleme Isterleri

Proje Xilinx Vivado ortaminda olusturulacaktir. Hedef FPGA parcasi xc7z010clg400-1 olacaktir. Proje dili Verilog olarak ayarlanacaktir.

Derleme sureci iki farkli TCL scripti ile baslatilabilecektir. Birincisi create_project.tcl scripti olup sifirdan proje olusturur, clk_wiz_0 IP'sini yapilandirir ve sentez, implementation ve bitstream adimlarini sirasiyla calistirir. Ikincisi rebuild.tcl scripti olup mevcut projeyi acar, sentez ve implementation adimlarini sifirlar ve yeniden calistirir.

Sentez ve implementation adimlarinda 4 paralel is parcacigi (jobs) kullanilacaktir. Sentez tamamlandiktan sonra sentez durumu kontrol edilecek ve "synth_design Complete!" mesaji alinacaktir. Implementation tamamlandiktan sonra "route_design Complete!" mesaji dogrulanacaktir.

Bitstream dosyasi olusturulduktan sonra output/ klasorune kopyalanacaktir. Derleme raporlari (utilization, timing, power) ayri dosyalar olarak kaydedilecektir.


## Beklenen Cikis Degerleri

Sistemin dogru calistiginda beklenen olcum degerleri su sekildedir: Cikis frekansi 63.47 kHz olmalidir. Tepe-tepe voltaj (Vpp) yaklasik 1000 mV (1V) olmalidir. DC ofset 5 mV'nin altinda olmalidir. Toplam harmonik bozulma (THD) yuzde 1'in altinda olmalidir. Sinyal-gurultu orani (SNR) 30 dB'nin uzerinde olmalidir.

Bu degerler, AD9767 DAC'in 14-bit cozunurlugunun tam verimle kullanildigini ve sinus dalgasinin yuksek kalitede uretildigini gosterir.

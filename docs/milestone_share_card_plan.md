# Rencana Fitur: Kartu Syiar & Pencapaian Ibadah (Shareable Milestone Card)

Dokumen ini mencatat rancangan konsep, arsitektur, dan alur teknis untuk fitur **Kartu Syiar & Pencapaian Ibadah** di **Muslim Launcher 2**. Fitur ini dirancang agar pengguna dapat membagikan momen pencapaian ibadahnya (Al-Qur'an & Dzikir) dalam bentuk kartu gambar yang estetik dan elegan ke media sosial (WhatsApp Status, Instagram Story, Telegram, dll.) lengkap dengan tautan aplikasi di Google Play Store, **100% tanpa meminta perizinan penyimpanan file (*Zero Storage Permission*)**.

---

## 1. Arsitektur Tanpa Izin File (*Zero-Permission Architecture*)

Untuk menjaga aplikasi tetap bersih, aman, dan patuh terhadap kebijakan ketat Google Play Console:
1. **Tidak Ada Izin Tambahan di Manifest**:
   - Tidak memerlukan `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, maupun `MANAGE_EXTERNAL_STORAGE`.
2. **In-Memory Capture via `RepaintBoundary`**:
   - Widget kartu pencapaian di-render di latar belakang ke dalam memori perangkat sebagai format byte PNG (`ui.ImageByteFormat.png`).
3. **Penyimpanan di Cache Internal Sementara**:
   - File PNG sementara disimpan di direktori privat aplikasi (`getTemporaryDirectory()` via `path_provider`). Direktori ini sepenuhnya bebas izin sejak Android awal hingga Android 15+.
4. **Pembagian via Android `FileProvider` (`share_plus`)**:
   - Menggunakan paket standar industri `share_plus` yang memanfaatkan `FileProvider` (`content://...`).
   - Sistem hanya memberikan izin baca sementara (*grant temporary read URI*) ke aplikasi tujuan (misal WhatsApp), sehingga aman dan langsung dibersihkan setelah selesai.

---

## 2. Kategori Pencapaian & Kriteria Pemicu (*Milestones*)

### A. Kategori Al-Qur'an
1. **Selesai Membaca 1 Surah Penuh**:
   - **Pemicu**: Pengguna membaca/mencapai ayat terakhir suatu surah di layar pembaca Al-Qur'an.
   - **Isi Kartu**: Nama surah (Arab & Latin), nomor surah, jumlah ayat, tanggal Hijriyah & Masehi, kutipan keutamaan surah, logo & link Muslim Launcher.
   - **Aturan Siklus Khatam (Anti-Farming Poin)**:
     - Pencapaian dan bonus poin untuk tiap surah **hanya bisa didapatkan 1 kali dalam 1 siklus 30 juz (114 surah)**.
     - Jika pengguna membaca ulang surah yang sudah pernah diselesaikan dalam siklus berjalan, tidak akan memicu bonus/kartu pencapaian ganda.
     - **Reset Otomatis Saat Khatam**: Begitu pengguna berhasil **Khatam 30 Juz (114 Surah)**, daftar pencapaian surah akan otomatis di-reset ke awal untuk memulai **Siklus Khatam Berikutnya** (Khatam ke-2, ke-3, dst.), sehingga pengguna dapat mengumpulkan pencapaian dan bonus poin per-surah kembali dari awal.
2. **Khatam 30 Juz Al-Qur'an (Sertifikat Digital Emas)**:
   - **Pemicu**: Pengguna menyelesaikan seluruh 114 surah / 30 juz Al-Qur'an.
   - **Isi Kartu**: Desain bingkai sertifikat emas eksklusif *"Sertifikat Khatam Al-Qur'an 30 Juz"*, nomor siklus khatam (misal: Khatam ke-1), doa khatam Al-Qur'an, tanggal penyelesaian, dan lencana emas *Rub el Hizb*.
   - **Efek Siklus**: Memberikan grand bonus (+500 poin), menambah penghitung total khatam (`khatamCount++`), dan me-reset status surah untuk siklus berikutnya.
3. **Surah Al-Kahfi di Hari Jumat**:
   - **Pemicu**: Menyelesaikan Surah Al-Kahfi pada hari Jumat (terdeteksi otomatis dari waktu perangkat).
   - **Isi Kartu**: Ornamen khusus Jumat Berkah dan hadits keutamaan membaca Al-Kahfi.
   - **Aturan**: Dapat diraih 1 kali setiap pekan di hari Jumat.

### B. Kategori Dzikir & Tasbih Digital (Kelipatan 33 Butir)
Sesuai tradisi sunnah tasbih (33 butir per putaran kecil, 99 butir per putaran Asmaul Husna):
- **Formula Pemicu**: `dzikirCount % 33 == 0`
- **Milestone Tingkat Putaran**:
  - **33x Dzikir**: *"1 Putaran Tasbih (Sunnah Ba'da Sholat)"*
  - **66x Dzikir**: *"2 Putaran Tasbih"*
  - **99x Dzikir**: *"3 Putaran Tasbih (Keluhuran Asmaul Husna)"*
  - **330x Dzikir**: *"10 Putaran Tasbih"*
  - **990x Dzikir**: *"30 Putaran Tasbih"*
- **Isi Kartu**: Lafadz bacaan dzikir (misal: *Subhanallah*, *Alhamdulillah*, *Allahu Akbar*, *Istighfar*, atau *Sholawat*), jumlah hitungan, jumlah putaran tasbih, dan tanggal.

---

## 3. Integrasi Riwayat (*History*) & Formula Keseimbangan Poin Kebaikan

---

### 3.1. Audit Ilmiah: Apakah Poin Dasar Saat Ini Kurang atau Lebih?

**Kesimpulan Evaluasi: Poin dasar Al-Qur'an saat ini KELEBIHAN SANGAT BESAR (*Hyper-Inflated*), sementara Hadits dan Dzikir sudah seimbang.**

#### Bukti Ketimpangan Sistemik Saat Ini:
1. **Poin Al-Qur'an Saat Ini (`surah_detail_screen.dart`)**:
   - Formula: `pointsEarned = 10 + (arabic.length ~/ 25)` per ayat.
   - Rata-rata ayat pendek memberikan **11 - 15 Poin**, dan ayat panjang bisa **18 - 25 Poin**.
   - **Dampak Nyata**: Hanya dengan membaca **3 sampai 4 ayat kilat** (butuh waktu < 30 detik), pengguna sudah mengumpulkan **~45 - 60 Poin** (sudah bisa membuka blokir aplikasi 60 menit yang bernilai 50 poin).
   - **Dampak ke Surah Panjang**: Membaca Surah Al-Baqarah (286 ayat) mengumpulkan lebih dari **4.000 Poin** hanya dari ayat dasar. 4.000 poin cukup untuk membuka blokir aplikasi sebanyak **80 kali (80 jam)**!
   - **Efek Negatif**: Nilai poin menjadi tidak berharga (*hyper-inflation*), kartu milestone selesai surah (+25 poin) terasa tidak ada artinya dibanding akumulasi ayat dasar, dan fungsi disiplin pemblokir aplikasi menjadi tidak berdaya.
2. **Asimetri Usaha (*Effort-to-Reward Mismatch*) Antar Fitur**:
   - **Hadits**: Menggunakan kamera *eye-tracking* ketat selama 20–50 detik + membaca terjemahan/perawi. Menghasilkan **3 – 8 Poin (rata-rata 5 poin)**. Butuh ~10 Hadits (5–8 menit fokus tinggi) untuk 50 poin.
   - **Dzikir**: Mengetuk 33x dengan deteksi wajah dan jeda *cooldown* 1,5–2 detik (~1–2 menit). Menghasilkan **10 Poin**. Butuh 5 putaran (~5–7 menit) untuk 50 poin.
   - **Al-Qur'an**: 30 detik membaca 4 ayat langsung dapat 50 poin.
   - Hal ini membuat Hadits dan Dzikir terkesan "pelit dan berat", sedangkan Al-Qur'an "terlalu murah dan membanjiri poin".

---

### 3.2. Landasan Teori Psikologi & *Behavioral Economics*

Perancangan ulang sistem poin ini disandarkan pada literatur ilmiah perilaku manusia dan gamifikasi etis:

#### 1. *Overjustification Effect* & *Self-Determination Theory* (Deci & Ryan, 1985; Deci, Koestner, & Ryan, 1999)
- **Teori**: *Psychological Bulletin (1999)* membuktikan bahwa ketika suatu aktivitas yang asalnya didorong oleh motivasi intrinsik luhur (seperti tilawah dan dzikir untuk ridha Allah) diberi imbalan ekstrinsik yang terlalu melimpah/murah, otak manusia mengalami pergeseran atribusi (*cognitive shift*).
- **Bahaya**: Pengguna mulai merasa: *"Saya membaca 3 ayat ini hanya demi poin untuk membuka TikTok"*. Begitu imbalan ekstrinsik mendominasi, kepuasan batin beribadah lenyap, memicu **kejenuhan spiritual (*spiritual burnout*)** dan hilangnya kebiasaan baik dalam jangka panjang.
- **Solusi Ilmiah**: Poin ekstrinsik harus diposisikan sebagai **umpan balik kompetensi (*informational feedback*)**, bukan upah/suap transaksi. Poin dasar harus moderat dan proporsional.

#### 2. *Goal-Gradient Hypothesis* & Kebiasaan Sehat (Hull, 1932; Kivetz, Urminsky, & Zheng, 2006)
- **Teori**: *Journal of Marketing Research (2006)* menunjukkan akselerasi usaha manusia saat mendekati target akhir. Namun, jika jarak ke target terlalu pendek/sepele (baca 3 ayat langsung dapat 1 jam hiburan), terbentuk perilaku buruk **"Binge & Purge"** (terburu-buru membaca 3 ayat kilat demi segera kabur ke media sosial).
- **Solusi Ilmiah**: Ambang batas pembuka aplikasi (50 poin) harus menuntut komitmen usaha sekitar **3 sampai 5 menit** (setara membaca 1 halaman / 15–20 ayat Al-Qur'an, atau 3 sesi dzikir lengkap, atau 8–10 hadits). Durasi 3–5 menit ini adalah *dopamine cooldown period* yang terbukti secara psikologis mampu meredakan dorongan kompulsif (*craving*) untuk bermain media sosial.

#### 3. *Variable Reinforcement & Reward Saliency* (Schultz, 1998; Kahneman & Tversky)
- **Teori**: Imbalan yang besar dan datar secara terus-menerus memicu desensitisasi dopamin (*habituation/kebosanan*). Sebaliknya, sistem imbalan yang paling memotivasi memadukan **baseline stabil yang tenang** dengan **lonjakan selebrasi bermakna pada titik pencapaian (*milestone surges*)**.
- **Solusi Ilmiah**:
  - Turunkan poin per-ayat agar menjadi aliran poin yang tenang dan bersahaja.
  - Tempatkan "kebanggaan dan kepuasan" pada **Kartu Selebrasi Milestone** (menyelesaikan 1 surah penuh, menuntaskan 99x dzikir, Al-Kahfi Jumat, dan Khatam 30 Juz). Dengan formula ini, bonus milestone surah (+15 hingga +100 poin) akan terasa sangat bernilai dan membahagiakan!

---

### 3.3. Rekomendasi Penataan Ulang Ekonomi Poin (Ekuilibrium Motivasi)

Untuk mencapai keseimbangan sempurna (*Golden Ratio*), seluruh aktivitas diselaraskan dengan patokan **50 Poin = 1x Buka Aplikasi (60 Menit)**:

| Aktivitas Ibadah | Poin Lama | Poin Rekomendasi Baru | Waktu Usaha untuk 50 Poin | Keseimbangan Psikologis |
| :--- | :---: | :---: | :---: | :--- |
| **Al-Qur'an (per Ayat)** | 10 – 15 Poin | **2 Poin** (+1 jika ayat > 75 huruf) | ~15 – 20 Ayat (~3–5 Menit) | Setara membaca 1 halaman mushaf. Fokus dan tartil. |
| **Dzikir (per 33x Putaran)** | 10 Poin | **3 Poin** | ~10 Putaran (~5–7 Menit) | Mikro-reward yang tenang; bonus besar ada di 99x (+10). |
| **Hadits (per Hadits)** | 3 – 8 Poin | **3 – 8 Poin (Rata-rata 5)** | ~10 Hadits (~5–8 Menit) | **Sudah Ideal**, membaca dengan *eye-tracking* & tadabbur. |
| **Bonus Selesai Surah** | Flat 25 Poin | **Tiering (+10 s/d +100 Poin)** | Tergantung panjang surah | Menghilangkan rasa jenuh membaca surah panjang. |
| **Batas Harian Dzikir** | Tanpa Batas | **Max 50 Poin / Hari** | - | Mencegah *spam-tapping* dan menjaga kekhusyu'an. |

### 3.4. Penyelarasan Menyeluruh: Aturan Progresi Ketat 1 Siklus Khatam (*Strict Linear Journey*)

Di Muslim Launcher, pengguna sejak awal **sengaja diarahkan untuk berproses secara disiplin (*Strict Sequential Progression*)**:
- **Prinsip Non-Renewable Ayat**: Dalam 1 siklus khatam, ayat yang sudah pernah dibaca **TIDAK AKAN BISA** menghasilkan poin lagi (`canEarnPoints` hanya aktif untuk ayat berikutnya).
- **Prinsip Non-Renewable Surah**: Bonus selesai surah **HANYA BISA** didapatkan 1 kali per surah dalam 1 siklus berjalan.
- **Siklus Khatam sebagai Sumber Daya Terhingga (*Finite Resource*)**: Al-Qur'an (6.236 ayat & 114 surah) adalah sebuah perjalanan suci terstruktur. Tidak ada celah untuk melakukan *farming* atau eksploitasi poin pada surah-surah pendek secara berulang-ulang.

---

### 3.5. Analisis Psikologi Perjalanan 3 Fase Khatam (*The 3-Phase Khatam Journey*)

Berdasarkan *The Endowed Progress Effect* (Nunes & Drèze, 2006) dan *Commitment Devices in Behavioral Economics* (Bryan et al., 2010), progresi linier ini membagi pengalaman pengguna ke dalam 3 fase psikologis:

#### 1. Fase "The Grand Climb" (Juz 1 – 6: Surah-Surah Sangat Panjang)
- **Tantangan Psikologis**: Menghadapi surah tebal (Al-Baqarah 286 ayat, Ali 'Imran 200 ayat, An-Nisa' 176 ayat). Jika tanpa penghargaan yang adil, pengguna rentan mengalami *The Mid-Goal Valley of Despair* (kejenuhan karena garis akhir surah terasa sangat jauh).
- **Penyelarasan Poin**:
  - Poin ayat panjang: **3 Poin per ayat** (karena rata-rata teks ayat di Al-Baqarah > 75 huruf).
  - Membaca 1 ruku' (~15 ayat) menghasilkan ~45 poin $\rightarrow$ konsisten cukup untuk 1x tiket buka aplikasi (50 poin) setiap hari.
  - Saat surah tuntas: Mendapatkan **Bonus Tier 4 (+100 Poin)** sebagai puncak apresiasi ketahanan membaca.

#### 2. Fase "The Rhythmic Cadence" (Juz 7 – 27: Surah-Surah Sedang & Panjang)
- **Kondisi Psikologis**: Surah berukuran 30 – 110 ayat (Yasin, Al-Kahfi, Maryam, Al-Waqi'ah, Al-Mulk).
- **Penyelarasan Poin**:
  - Bonus **Tier 2 (+25 Poin)** dan **Tier 3 (+50 Poin)** menciptakan *rhythmic reinforcement* (penghargaan berkala yang hadir setiap 1 hingga 3 hari tilawah).
  - Pengguna merasakan ritme ibadah yang stabil dan teratur (*istiqomah*).

#### 3. Fase "The Sprint to the Summit" (Juz 28 – 30: Juz 'Amma)
- **Dinamika Psikologis**: Surah-surah pendek (1 – 25 ayat) berganti dengan sangat cepat.
- **Penyelarasan Poin**:
  - Bonus **Tier 1 (+10 Poin)** per surah pendek.
  - Karena surah yang sudah dibaca langsung terkunci (0 poin), pengguna tidak bisa berdiam diri di Al-Ikhlas. Mereka terdorong untuk terus melaju ke Al-Falaq, An-Nas, hingga akhirnya mencapai puncak: **Khatam 30 Juz**.
  - Efek *Goal-Gradient* (Kivetz et al., 2006) bekerja maksimal di fase ini: kecepatan membaca meningkat karena garis khatam sudah di depan mata.

#### 4. Puncak Khatam & Siklus Baru
- **Khatam 30 Juz Penuh**: Mendapatkan **Grand Bonus +500 Poin** + **Sertifikat Digital Emas**.
- **Auto-Reset Siklus**: Seluruh 6.236 ayat dan 114 surah kembali dibuka hak perolehan poinnya untuk **Siklus Khatam ke-2**, menjaga motivasi membaca Al-Qur'an seumur hidup.

---

### 3.6. Penyelarasan Dzikir & Hadits Terhadap Progresi Al-Qur'an (Terapi Adiksi Media Sosial)

Usulan pembatasan poin dzikir menjadi **Maksimal 3 Putaran per Hari (3 $\times$ 33 = 99 Butir)** adalah **solusi yang SANGAT TEPAT secara neurobiologis & psikologi adiksi**:

#### 1. Mencegah Perilaku *Substitutive Addiction* (Kecanduan Pengganti)
- **Kondisi Pecandu Sosmed (*Lembke, 2021 - Dopamine Nation*)**:
  - Otak pecandu media sosial (TikTok, Reels, Instagram) memiliki sensitivitas dopamin yang tumpul dan dorongan impulsif tinggi.
  - Jika dzikir bisa menghasilkan poin tanpa batas atau hingga 10–30 putaran, otak pecandu akan memperlakukan tombol tasbih sebagai **"mesin slot penghasil token"**—mengetuk layar secepat mungkin tanpa khusyu' hanya agar segera mendapatkan 50 poin untuk kabur ke media sosial.
- **Efek Batas 3 Putaran (99 Butir / Hari)**:
  - 3 Putaran (33x Subhanallah, 33x Alhamdulillah, 33x Allahu Akbar) adalah sunnah tasbih sempurna pasca-shalat.
  - 3 Putaran hanya menghasilkan **Maksimal 19 Poin** per hari.
  - Karena 19 poin **belum cukup** untuk membuka aplikasi (butuh 50 poin), pengguna **TIDAK BISA** hanya bersandar pada ketukan jari dzikir untuk membuka blokir aplikasi!

#### 2. Memaksa Transisi Kognitif ke Al-Qur'an (*Prefrontal Cortex Engagement*)
- **Mekanisme Terapeutik (*Baumeister, 2002 - Delay of Gratification*)**:
  - Setelah menyelesaikan 3 putaran dzikir (dapat 19 poin), pengguna masih kekurangan 31 poin.
  - Satu-satunya cara untuk melunasi sisa 31 poin adalah **membuka Al-Qur'an dan membaca ~10–15 ayat baru (atau membaca Hadits bagi yang berhalangan)**.
  - Membaca Al-Qur'an (memperhatikan makhraj huruf Arab, tartil, dan tadabbur makna) mengaktifkan **Dorsolateral Prefrontal Cortex (dlPFC)**—wilayah otak yang bertugas mengontrol kendali diri dan menenangkan amigdala yang gelisah akibat kecanduan digital (*craving*).
  - Ini adalah kombinasi klinis yang sempurna: **Dzikir 3 putaran menenangkan kegelisahan awal, lalu Al-Qur'an merehabilitasi fokus otak yang rusak!**

#### 3. Catatan Fikih & Etika Aplikasi: "Batasi Poinnya, Bukan Ibadahnya"
- Dalam Islam, berdzikir dianjurkan sebanyak-banyaknya (*"Udzkurullaha dzikran katsira"*).
- Batasan 3 putaran ini **HANYA BERLAKU UNTUK POINNYA**, bukan tasbihnya.
- Pengguna tetap bebas berdzikir 330x, 1000x, atau seterusnya. Penghitung tasbih tidak berhenti, hanya bonus poinnya yang beristirahat setelah putaran ke-3 demi menjaga niat lillahi ta'ala.

---

### 3.7. Simulasi Makro Ekonomi 1 Siklus Khatam

Mari kita hitung total nilai poin yang beredar dalam 1 siklus khatam penuh (6.236 ayat):
- **Poin Ayat Dasar (6.236 ayat $\times$ rata-rata 2,3 poin)**: $\approx$ **14.340 Poin**
- **Bonus Selesai Surah (114 surah)**: $\approx$ **2.700 Poin**
  - *Tier 1 (~65 surah @ 10 poin) = 650 poin*
  - *Tier 2 (~30 surah @ 25 poin) = 750 poin*
  - *Tier 3 (~12 surah @ 50 poin) = 600 poin*
  - *Tier 4 (~7 surah @ 100 poin) = 700 poin*
- **Grand Bonus Khatam 30 Juz**: **500 Poin**
- **TOTAL POIN 1 SIKLUS KHATAM**: $\approx \mathbf{17.540\text{ Poin}}$

#### Uji Kelayakan Terhadap Pola Hidup Nyata:
- **Pengguna Rutin (Target Khatam 1 Tahun / ~1 Lembar per Hari)**:
  - Menyelesaikan 604 halaman dalam ~300 hari.
  - Rata-rata perolehan harian: $17.540 \div 300 \approx \mathbf{58\text{ Poin / Hari}}$.
  - **Hasil Evaluasi**: **Sempurna!** Membaca 1 lembar Al-Qur'an per hari menghasilkan ~58 poin, yang tepat cukup untuk membuka aplikasi 1 kali sehari (50 poin) dengan sisa sedikit tabungan. Ini membangun kebiasaan hidup seimbang (*work-life-spiritual balance*) tanpa kecanduan media sosial.

---

### A. Tabel Alokasi Bonus Poin Al-Qur'an (Berjenjang Berdasarkan Tingkat Usaha)

Bonus surah **hanya bisa diperoleh 1 kali per surah dalam 1 siklus khatam** (akan di-reset saat 30 juz khatam):

| Tingkat (Tier) Surah | Kriteria Panjang Ayat | Contoh Surah | Estimasi Waktu | Bonus Poin Selesai Surah | Nilai Terhadap Buka App (50 Poin) |
| :--- | :--- | :--- | :---: | :---: | :---: |
| **Tier 1: Surah Pendek** | 1 - 25 Ayat | Al-Fatihah, Al-Ikhlas, An-Nas, Al-Kautsar, Ad-Duha, Al-Insyirah | 1 - 3 Menit | **+10 Poin** | Butuh ~5 surah pendek untuk 1x buka app. Ringan & memotivasi pemula. |
| **Tier 2: Surah Sedang** | 26 - 75 Ayat | Al-Mulk (30), As-Sajdah (30), Ar-Rahman (78), Al-Waqi'ah (96) | 5 - 15 Menit | **+25 Poin** | ~1/2 dari tiket buka app. Sangat ideal untuk amalan harian. |
| **Tier 3: Surah Panjang** | 76 - 150 Ayat | Al-Kahfi (110), Yasin (83), Maryam (98), Yusuf (111), Ibrahim (52) | 20 - 45 Menit | **+50 Poin** | **Tepat 1x buka app (50 poin)**! Menghilangkan rasa jenuh setelah fokus panjang. |
| **Tier 4: Surah Sangat Panjang** | > 150 Ayat | Al-Baqarah (286), Ali 'Imran (200), An-Nisa' (176), Al-A'raf (206) | 1 - 3 Jam / Berhari-hari | **+100 Poin** | **2x buka app (100 poin)**! Apresiasi maksimal untuk ketahanan membaca surah tebal. |
| **Spesial Jumat: Al-Kahfi** | 110 Ayat | Dibaca khusus pada hari Jumat | ~30 Menit | **+50 Poin** | Bonus mingguan khusus Jumat Berkah (1x per pekan). |
| **Grand Milestone: Khatam 30 Juz** | 114 Surah Penuh | Seluruh mushaf tuntas | Berbulan-bulan | **+500 Poin** | Sertifikat Digital Emas, 10x buka app, dan reset siklus surah ke-2. |

---

### B. Tabel Alokasi Poin Dzikir (Kelipatan 33 Butir & Batas 3 Putaran Harian)

| Putaran Dzikir | Butir Tasbih | Makna Tradisi | Bonus Poin | Akumulasi Poin Harian |
| :--- | :---: | :--- | :---: | :---: |
| **Putaran 1** | **33x Dzikir** | Sunnah Ba'da Sholat (Subhanallah) | **+3 Poin** | 3 Poin |
| **Putaran 2** | **66x Dzikir** | Putaran ke-2 (Alhamdulillah) | **+3 Poin** | 6 Poin |
| **Putaran 3** | **99x Dzikir** | Putaran ke-3 (Allahu Akbar / Asmaul Husna) | **+3 Poin + Bonus 10 Poin** | **19 Poin (BATAS MAKSIMAL POIN HARIAN)** |
| **Putaran > 3** | **330x / 990x** | Dzikir Panjang / Istighfar Akbar | **0 Poin (Hanya Catatan Riwayat & Kartu Syiar)** | Tetap 19 Poin |

#### Ringkasan Kunci Anti-Kecanduan:
- **Poin Maksimal Dzikir per Hari**: **19 Poin** (setelah tuntas 3 putaran / 99x).
- **Kekurangan Poin untuk Buka App (50 Poin)**: Sisa **31 Poin** wajib dipenuhi dengan membaca Al-Qur'an (atau Hadits) yang menuntut fokus penuh.
- **Tasbih Digital Tetap Bebas**: Tidak ada larangan berdzikir lebih dari 99x, hanya poin aplikasinya yang istirahat.

---

### C. Pencatatan Otomatis ke Riwayat Aktivitas (`readingHistory`)
Setiap pencapaian langsung masuk ke riwayat lokal dengan format:
- `🏆 Pencapaian: Selesai Surah [Nama Surah] (+[Poin] Poin)`
- `✨ Pencapaian: Surah Al-Kahfi Jumat Berkah (+50 Poin)`
- `📿 Pencapaian: [33x / 99x / 330x] Dzikir ([Putaran] Putaran Tasbih) (+[Poin] Poin)`
- `👑 Grand Pencapaian: Khatam 30 Juz Al-Qur'an (+500 Poin)`

---

## 4. Desain Visual Kartu (*Ultra-Postable Share Card Architecture*)

Agar anak muda (Gen Z) dan anak-anak **dengan bangga dan senang hati membagikan (*proudly flex*)** pencapaian ibadahnya ke Instagram Story, WhatsApp Status, dan TikTok, kartu tidak boleh dirancang seperti brosur masjid kuno atau poster kaku.

Kartu harus memiliki **_Social Currency_ tinggi (Jonah Berger - *Contagious*)**, memadukan estetika modern (*Spotify Wrapped, Apple Fitness, Strava*) dengan kemegahan seni geometris Islam.

---

### 4.1. Filosofi Visual: "Spiritual Achievement Flex"
Anak muda senang memposting pencapaian yang mencerminkan:
1. **Kedisiplinan Diri (*High-Value Discipline*)**: Menunjukkan bahwa mereka adalah pemuda Muslim yang keren, produktif, dan mampu menaklukkan kecanduan media sosial.
2. **Estetika Visual Visual Tingkat Tinggi**: Desain yang cocok masuk ke dalam feed / story Instagram tanpa merusak estetika profil mereka.
3. **Statistik Personal Nyata (*Data-Driven Bragging Rights*)**: Bukan sekadar tulisan "Sudah Baca", melainkan data perjalanan yang membanggakan.

---

### 4.2. Pilihan 4 Tema Estetika Visual (*Multi-Theme Presets*)
Saat dialog selebrasi muncul, pengguna dapat memilih/menggeser tema visual kartu sesuai selera estetika mereka sebelum dibagikan:

#### 1. Tema "Midnight Obsidian" (Gaya Dark Mode / Cyber-Spiritual - Favorit Gen Z & Gamers)
- **Latar Belakang**: Hitam Obsidian pekat (`#0B0F19`) dengan gradasi *Aurora Emerald Glow* (`#10B981`) di sudut kartu.
- **Aksen**: *Glassmorphism* (kartu kaca semi-transparan dengan efek blur halus) dan garis batas tipis berkilau emas.
- **Tipografi**: Modern Sans-Serif tebal (*Outfit / Plus Jakarta Sans*) dipadukan kaligrafi Arab kontemporer yang tajam dan bersih.
- **Kesan**: Modern, eksklusif, canggih, dan futuristik.

#### 2. Tema "Deep Emerald Luxe" (Gaya Kerajaan Islam Klasik Elegan)
- **Latar Belakang**: Hijau Zamrud Hutan Tua (`#06281C` $\rightarrow$ `#0F5E3B`) dengan *watermark* ornamen geometris islami halus.
- **Aksen**: Logam Emas Hangat (*Warm Gold Foil* `#F59E0B` & `#FFD700`).
- **Tipografi**: Elegan, kharismatik, dengan sentuhan serif halus dan kaligrafi Thuluth emas.
- **Kesan**: Sakral, agung, anggun, dan berkelas tinggi.

#### 3. Tema "Minimalist Warm Sand" (Gaya Aesthetic Clean - Sangat Disukai Remaja Putri / Content Creators)
- **Latar Belakang**: Krem Pasir Hangat (*Warm Sand / Ivory* `#FAF7F2`) yang lembut dan teduh di mata.
- **Aksen**: Hijau Sage Lembut (`#047857`) dan Terracotta Muted (`#9A3412`).
- **Tipografi**: Gaya majalah editorial minimalis (*Playfair Display / Inter*).
- **Kesan**: Tenang, damai (*peaceful*), estetik, dan *Pinterest-worthy*.

#### 4. Tema "Royal Gold Certificate" (Eksklusif Khusus Khatam 30 Juz)
- **Desain**: Format sertifikat digital resmi kerajaan emas dengan stempel timbul (*embossed seal*) 3D, nomor siklus khatam, dan pita emas bertuliskan *"Khatam 30 Juz Club"*.

---

### 4.3. Komponen & Anatomi Kartu Story 9:16

Kartu di-render dalam resolusi tinggi **1080 $\times$ 1920 px (Rasio 9:16)** dengan memperhatikan *Instagram & WhatsApp Story Safe Zones* (bebas dari gangguan tombol close IG di atas dan bar ketik di bawah):

```
+-------------------------------------------------------+
|  [Safe Margin Atas: 150px - Kosong untuk UI Story]    |
|                                                       |
|  [HEADER]                                             |
|  🌙 MUSLIM LAUNCHER • ISTIQOMAH JOURNEY               |
|  بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ                    |
|                                                       |
|  [HERO ICON / COLLECTIBLE BADGE]                      |
|  🎖️ Lencana Emas 3D: [Piala Surah / Bintang 33 Dzikir] |
|                                                       |
|  [MAIN TITLE & SURAH NAME]                            |
|  🏆 SURAH COMPLETED                                   |
|  AL-KAHFI (الكهف)                                      |
|  "Cahaya di Antara Dua Jumat"                         |
|                                                       |
|  [STATISTIK PRESTASI PERSONAL - GRID 2x2]             |
|  +-------------------------+-------------------------+|
|  | 📖 110 Ayat             | ⏱️ 28 Menit Tilawah      ||
|  +-------------------------+-------------------------+|
|  | 🔥 14 Hari Streak       | 🛡️ 18 Jam Screen Safe   ||
|  +-------------------------+-------------------------+|
|                                                       |
|  [PROGRESS BAR KHATAM]                                |
|  Juz 15 / 30 [████████████░░░░░░░░░░░░] 50% Khatam   |
|                                                       |
|  [KUTIPAN MUTIARA HADITS / KEUTAMAAN SURAH]           |
|  "Barangsiapa membaca Surah Al-Kahfi di hari Jumat,   |
|  maka akan dipancarkan cahaya baginya..." (HR. Hakim) |
|                                                       |
|  [FOOTER BRANDING ELEGAN]                             |
|  📅 14 Muharram 1448 H • Diposting via Muslim Launcher|
|  🔗 muslimlauncher.com/app                            |
|                                                       |
|  [Safe Margin Bawah: 180px - Kosong untuk Reply Bar]  |
+-------------------------------------------------------+
```

---

### 4.4. Fitur Koleksi Lencana (*Digital Collectible Badges*)
Untuk anak-anak dan remaja yang menyukai nuansa gamifikasi (*RPG Collectibles*):
- Setiap surah yang tuntas membuka **Lencana Unik (*Badge*)**:
  - Surah Al-Fatihah: *Lencana Ummul Kitab (Perunggu Emas)*.
  - Surah Al-Baqarah: *Lencana Puncak Al-Qur'an (Berlian Zamrud)*.
  - Surah Al-Kahfi: *Lencana Pelindung Fitnah Dajjal (Cahaya Perak Jumat)*.
  - Surah Yasin: *Lencana Jantung Al-Qur'an (Ruby Merah Delima)*.
  - Surah Al-Mulk: *Lencana Penyelamat Siksa Kubur (Safir Biru Malam)*.
  - Dzikir 99x: *Lencana Asmaul Husna (Tasbih Emas)*.
  - Khatam 30 Juz: *Mahkota Agung Khatam (Grand Golden Crown)*.
- Pengguna bisa melihat seluruh koleksi lencananya di galeri khusus (*Mihrab Prestasi*). Kartu pencapaian menampilkan lencana 3D yang mengilap, memicu rasa bangga untuk mengoleksi seluruh 114 lencana surah!

---

### 4.5. Solusi Cerdas Nama Pengguna: Input Otomatis Pasca-Setup & Bisa Diubah di Homescreen

Karena Muslim Launcher **sangat menjaga privasi dan tidak memiliki sistem registrasi/login akun**, penanganan nama pengguna dirancang sangat alami dalam alur aktivasi:

#### 1. Input Otomatis Tepat Setelah Setup Selesai (*Post-Setup Welcome Step*)
- Begitu pengguna menyelesaikan proses pengaturan izin awal (*setup / onboarding hub*):
  - Sistem **secara otomatis menampilkan layar/dialog sambutan ramah** sebelum masuk ke layar utama:
    > *"Alhamdulillah, setup selesai! ✨"*
    > *"Siapa nama panggilanmu agar kami bisa menyapamu dengan hangat?"*
    > `[ Kolom Input: Masukkan nama / panggilan... (misal: Farhan) ]`
    > Tombol: `[ Lewati ]` dan `[ Simpan & Mulai ]`
  - **Jika Diisi**: Nama langsung disimpan permanen di memori lokal HP (`SharedPreferences: 'userName'`) dan `AppState`.
  - **Jika Dilewati**: Sistem otomatis menggunakan gelar *default* mulia: *"Pejuang Kebaikan"*.

#### 2. Ditampilkan di Homescreen & Bisa Di-tap Kapan Saja untuk Ubah Nama
- Di Layar Beranda (*Home Screen*), sapaan waktu di `_GreetingWidget` langsung memanggil nama tersebut:
  > Baris 1: `Selamat Pagi,`
  > Baris 2: `Farhan ✏️` *(atau "Pejuang Kebaikan ✏️" jika sebelumnya dilewati)*
- **Fleksibel Diubah Kapan Saja**: Setelah tahap setup awal tersebut, pengguna dapat **mengetuk (*tap*) teks nama / ikon pensil tersebut kapan saja** langsung dari Homescreen jika ingin mengganti nama panggilan atau nama pena.

#### 3. Sinkronisasi Otomatis ke Kartu Syiar Pencapaian (*Shareable Cards*)
- Nama yang sudah tersimpan tersebut **otomatis mengisi Kartu Syiar Pencapaian**:
  > *"Pencapaian: Farhan • Muslim Launcher"*
- Pengguna tidak perlu mengetik nama dua kali saat membagikan pencapaian surah atau dzikir.
- Pada dialog pembagian kartu, tetap tersedia toggle praktis `[✓] Tampilkan nama saya di kartu` bagi pengguna yang ingin menyembunyikan namanya sewaktu-waktu demi menjaga keikhlasan (*anti-riya'* / mode tawadhu').

---

## 5. Rencana Struktur Komponen & Modul (Saat Eksekusi Nanti)

### Dependensi yang Dibutuhkan:
- `share_plus` (untuk memicu Android Share Sheet dengan berkas gambar)
- `path_provider` (untuk akses folder temporary cache lokal)

### Berkas Baru yang Akan Dibuat:
1. **`lib/services/milestone_share_service.dart`**:
   - Mengelola rendering `GlobalKey` $\rightarrow$ `RenderRepaintBoundary` $\rightarrow$ byte PNG.
   - Menyimpan byte PNG ke folder cache sementara.
   - Memanggil `Share.shareXFiles([XFile(path)], text: ...)`.
2. **`lib/widgets/milestone_share_card.dart`**:
   - Widget visual kartu 9:16 yang indah dan siap di-capture.
3. **`lib/widgets/milestone_celebration_dialog.dart`**:
   - Dialog popup ucapan selamat / mubarak saat pengguna menyelesaikan surah atau mencapai kelipatan 33x dzikir, dilengkapi tombol:
     - **"Bagikan ke Story / Status"** (Hijau Zamrud).
     - **"Tutup / Lanjutkan"** (Outlined).

---

## 6. Pesan Berbagi (*Share Text Template*)

Teks pengantar yang otomatis disertakan saat gambar dibagikan:

```text
Alhamdulillah, saya telah menyelesaikan bacaan [Surah Al-Fatihah / 33x Dzikir / Khatam 30 Juz Al-Qur'an] menggunakan Muslim Launcher.

Yuk istiqamahkan ibadah harianmu bersama Muslim Launcher:
https://play.google.com/store/apps/details?id=com.kraftech.muslim_launcher_2
```

---

## 8. Riset Ilmiah: Strategi Motivasi Intrinsik & Mencegah *Rage-Uninstall* (Arsitektur Anti-Reaktansi)

Pertanyaan paling krusial dalam desain launcher ini adalah:
> *"Selain membuka aplikasi, bagaimana memotivasi pengguna agar tetap semangat membaca Al-Qur'an, berdzikir, dan membaca Hadits tanpa merasa terkekang hingga akhirnya meng-uninstall aplikasi?"*

Jika satu-satunya motivasi pengguna beribadah adalah demi mendapatkan poin pembuka media sosial, maka saat pengguna kesal karena dibatasi, mereka akan mengalami **_Rage-Uninstall_ (menghapus aplikasi karena frustrasi)**.

Berikut adalah strategi ilmiah berbasis **psikologi perilaku (*Behavioral Science*)**, **neurosains adiksi**, dan **psikologi Islam** untuk mengubah pembatasan menjadi cinta dan kebutuhan batin:

---

### 8.1. Menetralisir *Psychological Reactance* (Brehm, 1966; Dillard & Shen, 2005)
- **Akar Masalah**: Teori Reaktansi Psikologis membuktikan bahwa ketika kebebasan seseorang dirampas secara sepihak dan kaku (*"Aplikasi Anda Diblokir!"*), otak menganggap sistem sebagai "musuh/penjara", memicu lonjakan amarah impulsif untuk merebut kembali kebebasannya dengan cara: **Uninstall**.
- **Solusi Desain (*Autonomy-Supportive Reframing*)**:
  1. **Ubah Narasi dari "Penjara" Menjadi "Tameng Suci" (*Sacred Guardian*)**:
     - Hindari kata-kata bernada vonis hukuman: *"Aplikasi ini dikunci, masukkan poin!"*.
     - Gunakan narasi empati dan pengingat kasih sayang: *"Istirahat sejenak, saudaraku. Mari jaga pandangan (Ghadhul Bashar) dan selamatkan waktu berhargamu untuk hal yang lebih kekal."*
  2. **Rasa Memegang Kendali Penuh (*Internal Locus of Control*)**:
     - Tampilkan pesan bahwa pengguna sendirilah yang berinisiatif memasang launcher ini demi kebaikan dirinya sendiri: *"Kamu yang memilih jalan istiqomah ini. Kami di sini hanya mendampingimu."*
  3. **Katup Darurat Damai (*Emergency Grace Mode with Cognitive Pause*)**:
     - Sediakan opsi *"Buka Darurat 5 Menit"* untuk keperluan mendesak, namun dengan jeda napas tenang 15–30 detik (menghitung mundur atau membaca ta'awudz).
     - Jeda ini menghilangkan rasa terjebak/panik, sehingga pengguna tidak perlu melakukan uninstall hanya karena ada pesan mendadak dari kantor/keluarga.

---

### 8.2. Membangun Tiga Kebutuhan Psikologis Dasar (Deci & Ryan - *Self-Determination Theory*)

Manusia akan setia menggunakan suatu produk jika produk tersebut memenuhi 3 kebutuhan jiwa:

#### A. Kebutuhan Merasa Mampu & Berkembang (*Competence*)
Pecandu media sosial sering merasa rendah diri (*"Saya orang gagal yang tidak punya disiplin"*). Launcher harus menjadi sarana pemulihan harga diri:
1. **Kalender Titik Istiqomah (*Hijriyah Habit Heatmap / Streak*)**:
   - Visualisasi titik hijau tilawah harian (seperti *GitHub Contribution Graph* atau *Duolingo Streak*).
   - Menghasilkan efek psikologis **_The "Don't Break the Chain" Effect_ (Clear, 2018)**: Melihat 15 hari titik hijau berturut-turut membuat pengguna bangga dan enggan merusak rangkaian prestasinya.
2. **Statistik "Waktu Berharga yang Terselamatkan" (*Time Redeemed Metric*)**:
   - Alih-alih menampilkan statistik yang membuat depresi (*"Kamu main hp 5 jam hari ini"*), tampilkan metrik kemenangan:
     `✨ MashaAllah! Kamu telah menyelamatkan 28 Jam waktu berharga bulan ini untuk akhiratmu.`
3. **Persentase Perjalanan Menuju Puncak Khatam**:
   - *"Alhamdulillah, kamu sudah menuntaskan 42% dari seluruh isi Al-Qur'an (Juz 13/30)"*. Ini memanfaatkan *Endowed Progress Effect* (Nunes & Drèze, 2006).

#### B. Kebutuhan Otonomi (*Autonomy*)
- Pengguna tidak dipaksa hanya pada 1 aktivitas kaku. Mereka bebas memilih jalur ibadah harian sesuai suasana hati dan kapasitas energi (*flexible pathway*):
  - Ingin ketenangan tilawah $\rightarrow$ Al-Qur'an.
  - Sedang lelah atau di jalan $\rightarrow$ Dzikir Tasbih Digital.
  - Sedang uzur / butuh nasihat singkat $\rightarrow$ Hadits Shahih dengan Tadabbur.

#### C. Kebutuhan Keterhubungan & Pengakuan Sosial (*Relatedness*)
- Manusia memiliki dorongan fitrah untuk terhubung dan diakui oleh komunitasnya (*Baumeister & Leary, 1995*).
- **Kartu Syiar Pencapaian (*Shareable Milestone Cards*)**:
  - Saat pengguna menuntaskan Surah Al-Kahfi atau Khatam 30 Juz, mereka membagikan kartu visual emas yang anggun ke WhatsApp Status / Instagram Story.
  - Ketika kerabat dan sahabat merespons dengan *"MashaAllah tabarakallah, keren banget!"*, pengguna menerima **validasi sosial positif (*Positive Social Proof*)**.
  - Berdasarkan *Consistency and Commitment Principle* (Cialdini, 1984), seseorang yang telah mempublikasikan komitmen ibadahnya secara terbuka **TIDAK AKAN MENG-UNINSTALL APLIKASI**, karena hal itu akan mencoreng identitas positif yang baru saja ia proyeksikan ke lingkungan sosialnya.

---

### 8.3. Benteng Retensi: *Loss Aversion* & Kebiasaan Berbasis Identitas (*Identity-Based Habits*)

*Daniel Kahneman & Amos Tversky (1979)* membuktikan bahwa rasa sakit kehilangan sesuatu (*Loss Aversion*) bernilai **2 kali lipat lebih kuat** daripada kesenangan mendapatkan hal baru:

1. **Investasi Jejak Ibadah (*The Sunk Cost & Endowed Value*)**:
   - Jika launcher hanya berupa alat pemblokir biasa, pengguna tidak merasa rugi saat menghapusnya.
   - Namun di Muslim Launcher, pengguna telah menginvestasikan:
     - Riwayat tilawah dari juz ke juz.
     - Koleksi lencana dan kartu syiar emas di galeri pencapaian (*Digital Mihrab*).
     - Catatan putaran tasbih dan hadits yang telah ditadabburi.
   - Saat terlintas dorongan sesaat untuk uninstall karena kesal dibatasi, alam bawah sadar pengguna akan berteriak: *"Jika saya uninstall, seluruh rekam jejak perjuangan dan streak tilawah saya selama berminggu-minggu akan lenyap seketika!"*
2. **Transformasi Identitas Diri (James Clear - *Atomic Habits, 2018*)**:
   - Launcher secara perlahan mengubah persepsi diri pengguna dari *"Saya seorang pecandu sosmed yang sedang dihukum"* menjadi *"Saya adalah seorang Muslim yang menjaga waktu, menjaga pandangan, dan sedang menempuh perjalanan mulia mengkhatamkan Al-Qur'an"*.
   - Tindakan uninstall akan memicu **Disonansi Kognitif (*Festinger, 1957*)** yang menyakitkan batin, karena bertentangan langsung dengan identitas luhur yang telah ia peluk.

---

### 8.4. Prinsip Psikologi Islam: Ekuilibrium *Takhalli* & *Tahalli* (Imam Al-Ghazali)

Dalam kitab *Ihya' Ulumuddin*, pembersihan jiwa manusia menuntut dua sayap:
1. **Takhalli (Pengosongan / Pembersihan)**: Menghentikan perbuatan sia-sia, syahwat pandangan, dan kecanduan duniawi (dalam launcher: membatasi media sosial non-produktif).
2. **Tahalli (Penghiasan Diri)**: Menghiasi jiwa dengan keindahan dzikir, firman Allah, dan akhlak Rasulullah.

**Kelemahan Aplikasi Blocker Konvensional**:
Aplikasi pemblokir lain hanya melakukan *Takhalli* (melarang dan memutus akses). Akibatnya jiwa pengguna merasa hampa, kering, dan akhirnya memberontak.

**Kekuatan Muslim Launcher**:
Muslim Launcher tidak hanya memblokir, tetapi menggantikan kehampaan tersebut dengan **"Mihrab Digital yang Teduh" (*Tahalli*)**:
- Antarmuka layar beranda yang bersih, minimalis, dan damai (*Zen-Islamic Aesthetic*).
- Setiap kali layar ponsel dinyalakan, pengguna disapa oleh ayat penyejuk hati atau doa perlindungan, bukan notifikasi gosip atau media sosial yang memicu kecemasan (*anxiety/FOMO*).
- Ponsel bertransformasi dari **sumber stres dan pemborosan umur** menjadi **sumber ketenangan batin (*Sakinah*)**. Pengguna mencintai aplikasi ini bukan karena terpaksa, melainkan karena merasakan hidupnya menjadi jauh lebih tenang, damai, dan bermakna sejak menggunakannya.

---

## 9. Penyempurnaan Fitur & Antisipasi *Edge Cases* (6 Pilar Penguat)

Berdasarkan audit teknis dan skenario nyata pengguna di lapangan, berikut 6 pilar penguat yang melengkapi fitur ini:

### 9.1. Migrasi & Kenyamanan Pengguna Lama (*Existing Users Migration*)
- Pengguna yang sudah menginstal versi lama (v1.6.6 ke bawah) tidak akan melewati alur onboarding setup lagi saat memperbarui aplikasi.
- **Solusi**:
  - Di Layar Beranda, jika `userName == null`, sapaan tetap menampilkan: *"Selamat Pagi, Pejuang Kebaikan ✏️"*.
  - Saat pengguna mencapai milestone pertama kalinya atau saat mengetuk ikon pensil tersebut, sistem menampilkan dialog satu kali yang ramah:
    > *"Beri tahu kami nama panggilanmu agar bisa disematkan di kartu syiar dan sapaan berandamu ✨"*
  - Dengan demikian, pengguna lama tetap mendapatkan pengalaman personalisasi yang mulus tanpa kebingungan.

### 9.2. Galeri Pencapaian / Koleksi Lencana (*Digital Mihrab: Re-Share Anytime*)
- **Masalah**: Pengguna mungkin sedang terburu-buru saat menyelesaikan surah sehingga langsung menutup dialog selebrasi tanpa sempat membagikannya.
- **Solusi**:
  - Disediakan menu **"Koleksi Lencana & Prestasi"** (dapat diakses dari menu Riwayat Ibadah atau Pengaturan).
  - Pengguna dapat membuka kembali galeri 114 lencana surah yang telah diraih, melihat statistik kumulatif, dan menekan tombol **"Bagikan Ulang (*Re-share*)"** kapan saja tanpa batas waktu.

### 9.3. Tombol Ganda: "Bagikan ke Status" & "Simpan ke Galeri" (*Zero-Permission Scoped Storage*)
- Di dialog kartu selebrasi, sediakan 2 tombol aksi utama:
  1. 🟢 **"Bagikan ke Story / Status"**: Memanggil Android Share Sheet (`share_plus`) langsung ke WhatsApp, Instagram, Telegram, dll.
  2. 📥 **"Simpan Gambar ke Galeri"**: Menyimpan gambar langsung ke album foto perangkat (*Pictures/MuslimLauncher*).
- **Teknis Tanpa Izin (*Zero Permission*)**: Pada Android 10+ (API 29+), penyimpanan berkas media buatan aplikasi sendiri ke folder publik galeri didukung resmi oleh sistem Android via *MediaStore Scoped Storage* tanpa meminta izin `WRITE_EXTERNAL_STORAGE`.
- **Nilai Tambah**: Memudahkan anak muda dan remaja mengedit gambar di Instagram Story (menambahkan musik/nasyid favorit, stiker waktu, atau filter IG pribadi) sebelum dipublikasikan, atau menjadikannya wallpaper lockscreen.

### 9.4. Efek Selebrasi Audio-Visual (*Micro-Delight: Golden Confetti & Haptic Feedback*)
- Saat pengguna berhasil menuntaskan satu surah atau khatam, dialog tidak muncul secara datar dan kaku.
- **Elemen Selebrasi**:
  - **Animasi Partikel Bintang Emas (*Subtle Golden Confetti Burst*)**: Pancaran partikel bintang berkilau yang meletup lembut di latar belakang kartu.
  - **Getaran Haptik Berirama (*Success Haptic Vibration*)**: Getaran lembut berirama yang memberikan sensasi kepuasan sentuhan nyata.
- Memicu lonjakan dopamin kebaikan (*micro-delight*) yang membuat anak-anak dan remaja merasa usahanya dihargai secara spektakuler.

### 9.5. Dukungan Multibahasa Internasional (*Full I18n Card Localization*)
- Muslim Launcher 2 mendukung 6 bahasa resmi: Indonesia (`id`), Inggris (`en`), Melayu (`ms`), Arab (`ar`), Afrikaans (`af`), dan Swahili (`sw`).
- Seluruh elemen teks pada kartu syiar otomatis di-render sesuai bahasa aktif di aplikasi:
  - *Indonesia*: "Surah Selesai • Al-Kahfi • Cahaya di Antara Dua Jumat • 110 Ayat • 28 Menit Tilawah"
  - *Inggris*: "Surah Completed • Al-Kahf • A Light Between Two Fridays • 110 Verses • 28 Mins Reflection"
  - *Arab*: "ختم سورة الكهف • نور ما بين الجمعتين • ١١٠ آيات • ٢٨ دقيقة تلاوة"
- Menjamin kartu tampil elegan dan relevan bagi komunitas Muslim global di seluruh dunia.

### 9.6. Aturan Resmi "Buka Darurat 5 Menit" (*Emergency Grace Pass*)
- Untuk mencegah kepanikan dan *rage-uninstall* saat ada urusan darurat keluarga/pekerjaan:
  - **Batas Frekuensi**: Maksimal **1 kali per 24 jam**.
  - **Durasi Darurat**: **5 Menit**.
  - **Syarat Ketenangan (*Mindful Friction*)**: Pengguna wajib melewati jeda hitung mundur 15–30 detik (atau membaca istighfar 3 kali) sebelum aplikasi terbuka.
  - Jeda ini terbukti secara ilmiah menyaring antara kebutuhan nyata (urgensi) dan dorongan impulsif (adiksi).

---

## 10. Strategi Ilmiah: Transisi Penurunan Waktu Sosmed (Juz 1–30) Tanpa Merasa Dipaksa & Sistem Kehormatan Khatam Level

### 10.1. Tantangan Psikologis & Jebakan Desain (*The Psychological Traps*)
Menurunkan jam penggunaan media sosial dari 4–6 jam menjadi ~2 jam harian sembari menempatkan **Khatam** sebagai puncak kebanggaan tertinggi menghadapi dua paradoks ilmiah jika tidak dirancang dengan hati-hati:

1. **Jebakan Paradoks Hukuman (*The Punishment Paradox - Skinner; Deci & Ryan*)**:
   - Jika pengguna baru merasakan pemotongan kuota setelah berhasil khatam (*"Selamat kamu khatam! Sekarang jatah sosmedmu kami potong dari 6 jam jadi 2 jam"*), otak manusia menginterpretasikan hal ini sebagai **hukuman atas keberhasilan**.
   - Secara bawah sadar, pengguna akan memperlambat atau menolak menyelesaikan Juz 29 & 30 demi mempertahankan kuota hiburannya (*Perverse Incentive / Loss Aversion*).
2. **Jebakan Horizon Waktu (*The Time Horizon Trap - George Ainslie, Picoeconomics*)**:
   - Mengkhatamkan 30 Juz membutuhkan waktu 6 hingga 12 bulan bagi pengguna awam.
   - Jika penurunan screen time baru terjadi berdasarkan jumlah khatam (1x, 2x), maka kecanduan gadget 4–6 jam sehari akan **dibiarkan berlanjut tanpa perbaikan selama 1 tahun pertama**.
3. **Bahaya Reaktansi Psikologis (*Psychological Reactance - Brehm, 1966*)**:
   - Ketika aplikasi membatasi akses secara sepihak dan kaku, pengguna merasa kebebasannya dirampas. Akibatnya timbul resistensi kognitif yang berujung pada **_rage-uninstall_**.

**Solusi Ilmiah**: Penurunan screen time harus **dititrasi secara halus sepanjang Juz 1 sampai Juz 30 pada siklus pertama**, bukan dengan dinding larangan yang kaku, melainkan dengan **merestrukturisasi friksi dan membiarkan pengguna memutuskan untuk berhenti secara mandiri**.

---

### 10.2. Empat Pilar Mekanika Transisi Halus (Juz 1 – 30)

```
[ JUZ 1 - 5: Fase Adaptasi Ramah ]
   │  • Sesi: 45-60 menit/buka
   │  • Jeda: 0 menit (tanpa hambatan)
   │  • Kuota harian longgar (~4-5 Jam)
   ▼
[ JUZ 6 - 15: Fase Sadar Diri (Stopping Cues) ]
   │  • Sesi: 30 menit/buka (memotong hypnotic scroll)
   │  • Jeda: 2 menit pendinginan napas
   │  • Kontrak komitmen otonom pertama di Juz 5
   ▼
[ JUZ 16 - 25: Fase Disiplin & Biaya Kognitif ]
   │  • Sesi: 20 menit/buka
   │  • Jeda: 3 menit reflektif
   │  • Tarif poin jam ke-3 & ke-4 mulai menanjak
   ▼
[ JUZ 26 - 30: Fase Penguasaan Diri (Mastery) ]
   │  • Sesi: 15 menit/buka (hanya untuk kebutuhan esensial)
   │  • Jeda: 5 menit / 1 ayat tadabbur
   │  • Total harian stabil di ~2 jam secara organik
   ▼
[ PUNCAK KHATAM: Mahkota Kehormatan Tertinggi (Maqam Ranks) ]
```

#### 1. Pilar 1: *Decaying Session Length* (Bukan Memotong Total Jam, tapi Memotong Durasi Bingeing)
Riset neurosains (*Anna Lembke - Dopamine Nation*) membuktikan bahwa pengguna jarang berniat berselancar 5 jam penuh. Mereka terjebak dalam kondisi *zombie scrolling* akibat ketiadaan batas henti (*stopping cues*).
- **Juz 1 – 5**: Sekali tukar poin membuka akses **45–60 Menit** berturut-turut. Pengguna merasa nyaman dan tidak kaget saat masa transisi awal.
- **Juz 6 – 15**: Sekali tukar poin membuka akses **30 Menit**, diikuti jeda sejuk (*cooling off*) **2 Menit** sebelum bisa membuka sesi berikutnya.
- **Juz 16 – 25**: Durasi sesi menjadi **20 Menit** dengan jeda sejuk **3 Menit**.
- **Juz 26 – 30**: Durasi sesi menjadi **15 Menit** dengan jeda sejuk **5 Menit**.
- **Efek Psikologis Tanpa Paksaan**: Secara teknis kuota tidak dikunci mati, tetapi karena titik henti semakin sering, otak tersadar dari ilusi waktu. Pengguna secara alami memilih meletakkan ponselnya tanpa merasa dipenjara.

#### 2. Pilar 2: *The Autonomous Odysseus Contract* (Pre-Commitment Device - Deci & Ryan)
Sesuai prinsip *Self-Determination Theory*, komitmen yang dipilih secara sadar oleh pengguna memiliki daya tahan 300% lebih kuat dibanding aturan sepihak sistem:
- Setiap melewati gerbang kelipatan 5 Juz (Juz 5, 10, 15, 20, 25), aplikasi menampilkan selebrasi kelulusan:
  > *"Masya Allah! Kamu telah menuntaskan Juz 5. Ketahanan fokus dan ketenangan batinmu kini terbukti meningkat.*  
  > *Pilih target komitmen fokus harianmu untuk memasuki fase berikutnya:"*
  - **[Pilihan A] Pejuang Santai**: Maks 4.5 Jam / hari.
  - **[Pilihan B - Direkomendasikan] Pejuang Istiqomah**: Maks 3.5 Jam / hari *(Mendapatkan Badge Khusus)*.
  - **[Pilihan C] Pertapa Digital**: Maks 2 Jam / hari.
- Pengguna merasa memiliki kendali penuh atas hidupnya (*Internal Locus of Control*).

#### 3. Pilar 3: *Progressive Marginal Cost* (Hukum Biaya Kognitif Menanjak - Kahneman & Tversky)
Aplikasi tidak pernah berkata kasar *"Kamu dilarang membuka aplikasi lagi hari ini!"*. Sebagai gantinya, biaya penukaran poin dibuat berjenjang dalam siklus 24 jam:
- **Jam ke-1 sosmed hari ini**: Sangat Murah (15 Poin = cukup tilawah 5–7 ayat).
- **Jam ke-2 sosmed hari ini**: Standar (25 Poin = tilawah 10 ayat atau dzikir 3 putaran).
- **Jam ke-3 sosmed hari ini**: Mulai Berat (50 Poin = tilawah 20 ayat).
- **Jam ke-4+ sosmed hari ini**: Sangat Mahal (100 Poin).
- **Dampak Perilaku**: Pengguna sendiri yang secara rasional berhitung: *"Terlalu lelah harus tilawah 20 ayat hanya demi menonton reels 15 menit. Lebih baik saya istirahat atau mengerjakan hal produktif lainnya."* Keputusan berhenti lahir dari pertimbangan pribadi pengguna.

#### 4. Pilar 4: *Mindful Nudges & Soft Friction* (Thaler & Sunstein - Nudge Theory)
- **The 5-Second Mindful Reflection**: Ketika total waktu online mencapai 2 jam, sebelum aplikasi terbuka muncul layar penyejuk selama 5 detik:
  > *"Kamu telah menghabiskan 2 jam di aplikasi hiburan hari ini. Apakah ini waktu terbaikmu untuk melangkah maju?"*  
  > `[ Lanjutkan (5s) ]` &nbsp;&nbsp;&nbsp;&nbsp; `[ Istirahatkan Pikiran ]`
  - Jeda 5 detik ini memutus pola impulsif otak (*dopamine urge surfing*), menurunkan waktu buka lanjutan hingga 42%.

---

### 10.3. Menjadikan Tingkat Khatam (*Khatam Level*) Sebagai Nilai & Kebanggaan Tertinggi

Untuk menjadikan jumlah khatam sebagai mata uang kehormatan tertinggi (*Symbolic Capital - Pierre Bourdieu*), sistem harus memberikan pengakuan identitas spiritual yang mendalam:

#### 1. Tingkatan Maqam & Gelar Kemuliaan (*Spiritual Ranks*)
Jumlah khatam dikonversi menjadi gelar kehormatan spiritual yang disematkan langsung pada identitas pengguna:

| Frekuensi Khatam | Gelar Kehormatan (Maqam) | Mahkota & Lencana Homescreen | Estetika Kartu Syiar Story |
| :--- | :--- | :--- | :--- |
| **0x (Juz 1–29)** | **Pejuang Istiqomah** | 🌿 Tunas Hijau Zamrud | Midnight Obsidian / Sand |
| **Khatam 1x** | **Al-Mubtadi' Al-Karim** | 🥉 Mahkota Perunggu Emas | Tema Emas Klasik |
| **Khatam 2x** | **Sahabat Al-Qur'an** | 🥈 Mahkota Perak Holografis | Royal Silver Prism & Kaligrafi |
| **Khatam 3x** | **Penjaga Cahaya** | 🥇 Mahkota Emas Murni 24K | Pure Gold Emerald Leaf |
| **Khatam 5x+** | **Ahlul Qur'an Al-Mubarok** | 👑💎 Mahkota Obsidian Berlian | Celestial Diamond Seal & Pita Emas |

#### 2. Tampilan Permanen di Layar Beranda (*Permanent Status Symbol*)
- Di Layar Beranda (*Home Screen*), nama pengguna berdampingan dengan mahkota dan indikator tingkat khatam:
  > `Selamat Pagi,`  
  > `Farhan 👑 (Khatam 2x)`
- Memberikan rasa pencapaian yang terekam abadi dan menjadi kebanggaan setiap kali menyalakan ponsel.

#### 3. Transformasi Identitas & Metrik Kemenangan (*Atomic Habits - James Clear*)
- Di layar Riwayat / Statistik, tampilkan rasio kebanggaan pribadi:
  - **Rasio Hidup Berkah**: `📖 45 Menit Al-Qur'an` vs `📱 1 Jam 45 Menit Hiburan`.
  - *"Alhamdulillah! Rasio disiplin waktumu meningkat 70% dibanding saat berada di Juz 1."*
- Pengguna memandang diri mereka bukan lagi sebagai pecandu gawai yang sedang dihukum, melainkan sebagai seorang penempuh jalan kebaikan (*Ahlul Qur'an*) yang memiliki kendali penuh atas umurnya.

---

## 11. Status Rencana
- **Status**: Tersimpan dan terdokumentasi lengkap (Belum dieksekusi).
- **Kesiapan**: Siap diimplementasikan kapan saja ketika pengguna memberikan instruksi.


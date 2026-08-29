# Muslim Launcher 2 🕌

[English](#english) | [Bahasa Indonesia](#bahasa-indonesia) | [Privacy Policy](#privacy-policy-)

---

## English

An innovative custom Android launcher designed specifically to reduce smartphone addiction in a meaningful way. It transforms screen-wasting habits (mindless scrolling) into a habit of reading the Holy Quran.

### Core Concept
Instead of simply blocking apps with standard timers, Muslim Launcher utilizes an **"Ibadah Points"** system. Distracting apps are automatically blocked.

To unlock and access blocked applications, you are **required to read the Holy Quran** through the built-in reader. Every interaction with the Quran earns you points, and you need a certain amount of points (e.g., 50 Points) to unlock a blocked application for 60 minutes.

### Key Features
* 📖 **Read Quran for Points:** Built-in Quran integration inside the launcher. Reading surahs earns you points that act as "currency" to use entertainment or social media apps.
* 🛡️ **Smart Background Blocking:** Powered by native Android `AccessibilityService`. If you attempt to open a blocked app without enough points, the lock screen instantly kicks you out.
* 🔒 **Temporary Unlock System:** Once points are spent, apps become accessible normally for 60 minutes. When the unlocked duration expires, apps are locked again, ensuring consistent Quran reading.
* ⬛ **Minimalist Aesthetics:** A clean, distraction-free interface with dark theme support to help break visual smartphone triggers.

### Quran Data Source 📖
The Quranic data in this app is sourced from the **[Tanzil Project](https://tanzil.net)** and bundled locally (`assets/quran.json`) for complete offline availability.

Included datasets:
* **Arabic Text:** Uthmani Script & Tajweed text from [Tanzil.net](https://tanzil.net).
* **Indonesian Translation:** Ministry of Religious Affairs (Kemenag RI) via Tanzil.
* **English Translation:** Saheeh International via Tanzil.
* **Transliteration (Latin):** Standard Latin transliteration via Tanzil.

Raw text files are merged and structured using custom scripts (`data_temp/merge_quran.dart` / `data_temp/merge_quran.py`) into an optimized JSON format for Flutter performance.

### Privacy Policy 🔒
This application respects your privacy. Muslim Launcher uses Android's **Accessibility Service** purely to detect when a blocked application is opened so it can redirect you to the lock screen.
* **No Data Collection:** We do not collect, store, or transmit any personal data, typing behavior, or screen content.
* **Offline First:** All core logic and Quranic data operate 100% offline on your local device.
* **Open Source Transparency:** The entire source code of this application is fully open source and publicly available in this repository, ensuring complete transparency of how the `AccessibilityService` is used under the hood.

---

## Bahasa Indonesia

Sebuah custom launcher Android inovatif yang dirancang khusus untuk mengurangi adiksi smartphone dengan cara yang bermanfaat. Aplikasi ini mengubah kebiasaan membuang waktu (scrolling) menjadi kebiasaan membaca Al-Quran.

### Konsep Utama
Alih-alih sekadar memblokir aplikasi dengan pengatur waktu seperti launcher pada umumnya, Muslim Launcher menggunakan sistem **"Poin Ibadah"**. Aplikasi-aplikasi yang rentan membuat Anda lalai akan diblokir secara otomatis. 

Untuk dapat membuka dan mengakses aplikasi yang diblokir tersebut, Anda **diwajibkan untuk membaca Al-Quran** melalui fitur bawaan aplikasi ini. Setiap interaksi dengan Al-Quran akan memberikan Anda poin, dan Anda membutuhkan sejumlah poin (contoh: 50 Poin) untuk membuka satu aplikasi yang diblokir selama 60 menit.

### Fitur Unggulan
* 📖 **Baca Quran untuk Poin:** Integrasi Al-Quran di dalam launcher. Membaca surah akan memberikan Anda poin yang bertindak sebagai "mata uang" untuk menggunakan aplikasi hiburan/sosial media.
* 🛡️ **Pemblokiran Latar Belakang Cerdas:** Berjalan menggunakan `AccessibilityService` asli bawaan Android. Jika Anda memaksa membuka aplikasi terlarang tanpa poin yang cukup, layar blokir akan langsung muncul dan menendang Anda keluar.
* 🔒 **Sistem "Unlock" Sementara:** Setelah poin digunakan, aplikasi akan dapat diakses secara normal selama 60 menit. Jika masa waktunya habis, aplikasi akan terkunci kembali, memastikan Anda harus konsisten membaca Al-Quran untuk terus menggunakannya.
* ⬛ **Estetika Minimalis:** Antarmuka yang bersih dan bebas distraksi dengan dukungan tema gelap, membantu Anda memutus siklus adiksi visual dari smartphone.

### Sumber Data Al-Quran 📖
Data Al-Quran yang digunakan dalam aplikasi ini bersumber dari **[Tanzil Project](https://tanzil.net)** dan dibundel secara lokal di dalam aplikasi (`assets/quran.json`) agar dapat diakses sepenuhnya secara offline.

Dataset yang digunakan meliputi:
* **Teks Arab:** Teks Rasm Uthmani & Tajweed dari [Tanzil.net](https://tanzil.net).
* **Terjemahan Bahasa Indonesia:** Kementerian Agama Republik Indonesia (Kemenag RI) via Tanzil.
* **Terjemahan Bahasa Inggris:** Saheeh International via Tanzil.
* **Transliterasi (Latin):** Transliterasi Latin via Tanzil.

Data mentah diproses dan digabungkan secara terstruktur menggunakan skrip pemroses (`data_temp/merge_quran.dart` / `data_temp/merge_quran.py`) menjadi format JSON yang dioptimalkan untuk kinerja aplikasi Flutter.

### Kebijakan Privasi (Privacy Policy) 🔒
Aplikasi ini sangat menghargai privasi Anda. Muslim Launcher menggunakan **Accessibility Service (Layanan Aksesibilitas)** bawaan Android semata-mata hanya untuk mendeteksi kapan aplikasi yang diblokir sedang dibuka agar dapat dicegah dan dikunci.
* **Tanpa Pengumpulan Data:** Kami sama sekali tidak mengumpulkan, menyimpan, atau mengirimkan data pribadi, riwayat pengetikan, maupun konten di layar Anda.
* **Berjalan Offline:** Seluruh sistem dan data Al-Quran berjalan 100% secara luring (offline) di dalam perangkat Anda.
* **Transparansi Open Source:** Seluruh kode sumber aplikasi ini bersifat sumber terbuka (*open source*) dan dapat dilihat secara publik di repositori ini, memberikan transparansi penuh tentang bagaimana `AccessibilityService` bekerja di belakang layar.

---
*Dibuat untuk memotivasi Anda lebih banyak berinteraksi dengan Al-Quran dan mengubah kecanduan smartphone menjadi pahala.*

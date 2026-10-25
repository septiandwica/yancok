# 🥚 YANCOK — Steal An Egg (100% Free & Keyless)

Suite automasi mandiri (*standalone*) khusus untuk game **Roblox: Steal An Egg**, dibuat bebas dari key system / iklan checkpoint.
Dibuat untuk repository: `https://github.com/septiandwica/yancok`

---

## ⚡ Loadstring (Cara Pakai di Delta / Executor)

Salin kode ini dan tempel di Delta Executor (atau executor lainnya):

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/septiandwica/yancok/refs/heads/main/main.lua"))()
```

> **Untuk Uji Coba Lokal di Executor:**
> ```lua
> loadstring(readfile("yancok/main.lua"))()
> ```

---

## 📖 Panduan Fitur (Mudah Dipahami Anak-Anak & Pemula)

Menu didesain sangat simpel, rapi, dan mudah dimengerti. Terdapat 5 menu utama:

### 1. 🥚 Ambil Telur (Auto Steal & Filter Rarity)
* **Ambil Telur Otomatis**: Karakter kamu jalan sendiri mencari telur terbaik dan mengambilnya tanpa perlu kamu gerak-gerakin jempol / keyboard.
* **Pilih 3 Rarity Sekaligus (Divine, Eternal, Secret)**:
  * Di bawah dropdown target, ada **3 tombol cepat**: **`[ 👑 Divine ]`**, **`[ ⚡ Eternal ]`**, dan **`[ 🔮 Secret ]`**.
  * Cukup sekali sentuh / klik untuk mengaktifkan atau mematikan kombinasi mana pun yang kamu mau. Mau ambil ketiganya sekaligus? Cukup nyalakan ketiga tombolnya!
* **Filter Target Rarity di Dropdown**:
  * Pilihan preset otomatis: **`👑 Divine + ⚡ Eternal + 🔮 Secret`** *(Paling Populer)*, **`👑 Divine + ⚡ Eternal`**, **`👑 Hanya Divine`**, **`⚡ Hanya Eternal`**, **`🔮 Hanya Secret`**, atau **`Semua (Prioritas Tertinggi)`**.
* **Hanya Ambil Rarity Ini (Toggle)**:
  * Jika **AKTIF**: Karakter **HANYA** akan mencuri telur kasta yang dipilih (misal hanya Divine, Eternal, dan Secret). Telur biasa/sampah akan diabaikan!
  * Jika **MATI**: Karakter memprioritaskan kasta dewa dulu (Divine $\rightarrow$ Eternal $\rightarrow$ Secret), jika sudah habis baru mengambil telur apa saja yang terdekat.
* **Cara Jalan Karakter**:
  * **Jalan Santai (Paling Aman)**: Karakter jalan biasa seperti pemain asli *(paling direkomendasikan & anti-kick)*.
  * **Meluncur Mulus**: Karakter meluncur mulus ke arah telur *(lebih cepat)*.
  * **Teleport Kilat**: Karakter langsung pindah sekejap di atas telur *(paling cepat)*.
* **Buka Telur Otomatis (Auto Hatch)**: Kalau kamu berdiri di dekat mesin penetas / incubator, script akan otomatis memecahkan telur terus-menerus (bisa pilih 1x, 3x, atau 8x sekaligus).
* **Live Counter Rarity**: Di kotak hasil panen, kamu bisa melihat berapa banyak telur **Divine**, **Eternal**, dan **Secret** yang sudah berhasil dicuri secara real-time!

---

## 👑 Tingkatan Kasta Rarity di Steal An Egg (Lengkap)

Urutan kasta dari yang termahal & terkuat sampai yang paling dasar:

| No | Kasta Rarity | Ikon | Contoh Pet Populer | Kisaran Pendapatan ($/detik) |
|---|---|:---:|---|---|
| **1** | **Divine** | 👑 | *Spirit World Guardian, Voidseer Pumpkin, Skeletal Sabertooth, Royal Skywhale, Mecha Scrambler, Aetheron, ArchAngel, Kitsune, Nightflame, Unicorn* | **$1 Miliar - $26+ Miliar / detik** |
| **2** | **Eternal** | ⚡ | *Octophant, Rhinobear, Void Serpent, Gorilla King, Shattered Drake, Oni Tiger, World Eater, Dreadscale* | **$100 Juta - $1 Miliar / detik** |
| **3** | **Secret** | 🔮 | *Galaxy, Rift, Celestial Pet Tersembunyi* | **$20 Juta - $100 Juta / detik** |
| **4** | **Cosmic** | 🌌 | *Supernova, Cosmic Guardian, Nebula* | **$5 Juta - $20 Juta / detik** |
| **5** | **Mythic** | 🌟 | *Hydra, Pegasus, Chimera* | **$1 Juta - $5 Juta / detik** |
| **6** | **Legendary** | 🔥 | *Ice Dragon, Lava Dragon, Phoenix* | **$100 Ribu - $1 Juta / detik** |
| **7** | **Epic** | 💎 | *Golem, Griffin* | **$10 Ribu - $100 Ribu / detik** |
| **8** | **Rare** | 🔹 | *Snow realm & Desert realm pets* | **$1.000 - $10.00 Server cash** |
| **9** | **Uncommon** | 🟢 | *Fennec, Fox, Owl* | **$100 - $1.000 / detik** |
| **10** | **Common** | ⚪ | *Chicken, Dog, Cat, Starter Frog* | **$1 - $50 / detik** |

---

### 2. 🚀 Pindah Server (Server Hop)
* **Pindah Server Otomatis**: Kalau telur di servermu sudah habis diambil orang lain, script akan otomatis memindahkan karakter kamu ke server lain yang masih banyak telurnya.
* **Pindah Kalau**:
  * **Bebas / Kapan Saja**: Pindah otomatis secara berkala.
  * **Target Tercapai**: Pindah setelah target jumlah telur terpenuhi (misal setelah dapat 40 telur).
  * **Waktu Habis**: Pindah setelah waktu di server habis (misal tiap 12 menit).
  * **Telur Habis**: Pindah jika dalam 60 detik tidak ada telur baru yang muncul.
  * **Tidak Ada Divine/Eternal**: Script akan otomatis gonta-ganti server sampai menemukan server yang ada telur **Divine** atau **Eternal**!
* **Cari Server Paling Sepi**: Otomatis memilih server yang pemainnya sedikit agar kamu bisa panen telur tanpa diganggu orang lain.
* **Tombol Pindah Sekarang**: Tombol untuk langsung ganti server saat itu juga.

### 3. 💬 Auto Chat
* **Kirim Chat Otomatis**: Karakter kamu bisa mengetik dan mengirim pesan sendiri di obrolan chat Roblox secara berkala.
* Terdapat 3 baris pesan yang otomatis bergantian dikirim agar kamu tidak dianggap spam oleh sistem Roblox.

### 4. 📹 Kamera
* **Kunci Kamera Dari Atas**: Mengunci sudut pandang kamera dari atas kepala (seperti melihat dari helikopter).
* Layar jadi tenang dan tidak goyang-goyang saat karakter ditinggal AFK tidur atau makan.
* **Kunci Posisi Kamera Sekarang**: Mengunci posisi kamera sesuai sudut pandang yang sedang kamu lihat saat ini.

### 5. ⚡ Anti-Lag & AFK
* **Anti Lag (Extreme FPS Boost)**: Menghapus bayangan, partikel asap, dan animasi yang bikin HP panas atau patah-patah. Game jadi **sangat enteng & lancar**.
* **Anti-Kick 20 Menit (Anti-AFK)**: Roblox biasanya mengeluarkan pemain kalau diam selama 20 menit. Fitur ini membuat akun kamu tetap aktif sehingga **bisa ditinggal semalaman tanpa di-kick**.
* **Otomatis Terima Teman**: Otomatis menerima permintaan teman dari pemain lain (berguna untuk fitur kirim hadiah telur).
* **Masuk Ulang Server Ini**: Tombol cepat untuk rejoin ke server yang sama jika game terasa nge-bug.

---

## 🎮 Cara Buka / Tutup Menu
* **Di HP / Tablet (Delta Executor)**: Ketuk tombol icon telur mengambang **`🥚`** di tepi layar.
* **Di Laptop / PC**: Tekan tombol **`RightShift`** di keyboard.

---

## 📁 Struktur File di Repo `yancok`

* **`main.lua`**: Script utama Steal An Egg (Native Auto Steal & Hatch, UI kontrol, Server Hop, FPS Boost, Auto Chat, Camera Lock).
* **`fps.lua`**: Modul standalone Extreme FPS Booster.
* **`hop.lua`**: Modul standalone Server Hopper & Chat.
* **`panelpos.lua`**: Modul penjaga posisi GUI di pojok kanan bawah.

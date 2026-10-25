# 🥚 YANCOK — Steal An Egg (100% Free & Keyless)

Suite automasi mandiri (*standalone*) khusus untuk game **Roblox: Steal An Egg**, dibuat bebas dari key system / iklan checkpoint.
Dibuat untuk repository: `https://github.com/septiandwica/yancok`

---

## ⚡ Loadstring (Cara Pakai di Executor)

Setelah repository GitHub `septiandwica/yancok` dibuat:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/septiandwica/yancok/refs/heads/main/main.lua"))()
```

> **Untuk Uji Coba Lokal di Executor:**
> ```lua
> loadstring(readfile("yancok/main.lua"))()
> ```

---

## 📁 Struktur File di Repo `yancok`

* **`main.lua`**: Script utama Steal An Egg (Native Auto Steal & Hatch, UI kontrol, Server Hop, FPS Boost, Auto Chat, Camera Lock).
* **`fps.lua`**: Modul standalone Extreme FPS Booster.
* **`hop.lua`**: Modul standalone Server Hopper & Chat.
* **`panelpos.lua`**: Modul penjaga posisi GUI di pojok kanan bawah.

---

## 🛠️ Fitur-Fitur Utama

1. **100% Keyless**: Tidak ada dialog kunci, tidak ada verifikasi browser.
2. **Auto Claim & Steal Eggs**: Terhubung langsung ke remote claim game.
3. **Smart Auto Hop**:
   - Pindah server otomatis jika target klaim tercapai (default: 40 klaim).
   - Pindah server jika server sepi / telur habis (*no-match timeout*).
   - Memilih server publik paling sepi (2–6 pemain) dan menghindari server penuh.
   - Menggunakan `queueonteleport` agar script otomatis aktif kembali di server tujuan.
4. **Extreme FPS Booster (Built-in)**:
   - Menghapus material, bayangan, partikel, ombak air, dan tekstur telur.
   - Dilengkapi `DescendantAdded` live watcher agar telur yang baru spawn langsung diringankan.
5. **Auto Accept Friends & Auto Chat**:
   - Memudahkan fitur kirim hadiah telur (*gifting*).
   - Mengirim chat acak berkala untuk meramaikan server atau promosi.
6. **Top-Down Camera Lock**:
   - Menjaga sudut pandang kamera dari atas karakter agar nyaman saat AFK.
7. **Toggle GUI**:
   - Tekan tombol **`RightShift`** di keyboard untuk menyembunyikan atau memunculkan kembali jendela panel.

# crDroid 11 (Android 15) build environment for Rakuten Mini (c330ae)

NixOS上でRakuten Mini (c330ae / SDM439) 向けcrDroid Android 15をビルドするための環境です。

## デバイス情報

| 項目 | 内容 |
|---|---|
| デバイス | Rakuten Mini |
| コードネーム | c330ae |
| SoC | Qualcomm SDM439 (MSM8937) |
| ターゲット | crDroid 11 / LineageOS 22.2 (Android 15) |

## 必要環境

- NixOS (または Nix パッケージマネージャー)
- Nix Flakes 有効化済み
- 約 300 GB の空きディスク容量
- 16 GB 以上のメモリ推奨

## セットアップ

```bash
# 1. このリポジトリをクローン
git clone https://github.com/<your-username>/c330-crDroid.git
cd c330-crDroid

# 2. Nix FHS 環境に入る
nix develop

# 3. ソースの取得とビルド環境の初期化
./setup.sh
```

`./setup.sh` は以下を自動で実行します：
1. Android ソースを `~/android/crdroid/` に `repo init`
2. ローカルマニフェストをインストール
3. `repo sync` でソースを取得

## ビルド

```bash
# Nix FHS 環境内で実行
nix develop

cd ~/android/crdroid
source build/envsetup.sh
breakfast c330ae

# userdebug ビルド（ADB デフォルト有効）
make -j$(nproc) bacon

# user ビルド
lunch lineage_c330ae-user && make -j$(nproc) bacon

# KernelSU 有効ビルド
WITH_KSU=true make -j$(nproc) bacon
```

ビルド成果物は `out/target/product/c330ae/` に出力されます。

## ダウンロード

ビルド済みのOTAパッケージおよびイメージファイルは [Releases](../../releases) からダウンロードできます。

| ファイル | 用途 |
|---|---|
| `crDroidAndroid-15.0-*-c330ae-*.zip` | OTA パッケージ（標準ビルド） |
| `crDroidAndroid-15.0-*-c330ae-*-ksu.zip` | OTA パッケージ（KernelSU 対応） |

## フラッシュ

### OTA (TWRP サイドロード・推奨)

TWRP リカバリから `Install` → ダウンロードした ZIP を選択してサイドロードしてください。

### fastboot

```bash
fastboot flash system system.img
fastboot flash vendor vendor.img
fastboot flash boot boot.img
fastboot flash dtbo dtbo.img
fastboot flash vbmeta vbmeta.img
fastboot -w
fastboot reboot
```

## KernelSU

`WITH_KSU=true` を指定してビルドすると KernelSU 対応カーネルが生成されます。
ビルド後に [KernelSU Manager](https://github.com/tiann/KernelSU/releases) アプリをインストールして動作を確認してください。

## リポジトリ構成

| ファイル/ディレクトリ | 内容 |
|---|---|
| `flake.nix` | NixOS FHS ビルド環境定義 |
| `flake.lock` | Nix パッケージバージョンロック |
| `local_manifests/c330ae.xml` | repo ローカルマニフェスト |
| `setup.sh` | 初期セットアップスクリプト |

## 関連リポジトリ

- [デバイスツリー](https://github.com/2by2-Project-Devices/android_device_rakuten_c330ae) — `lineage-22.2`
- [カーネル](https://github.com/2by2-Project-Devices/android_kernel_rakuten_sdm439) — `lineage-22.2`
- [ベンダー](https://github.com/2by2-Project-Devices/proprietary_vendor_rakuten_c330ae) — `lineage-22.2`
- [crDroid Android](https://github.com/crdroidandroid/android) — `15.0`

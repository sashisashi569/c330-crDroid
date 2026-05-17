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
git clone https://github.com/sashisashi569/c330-crDroid.git
cd c330-crDroid

# 2. Nix FHS 環境に入る
nix develop

# 3. ソースの取得とビルド環境の初期化
./setup.sh
```

`./setup.sh` は以下を自動で実行します：
1. Android ソースを `~/android/crdroid/` に `repo init`
2. ローカルマニフェストをインストール（フォーク済みデバイスツリー・カーネルを使用）
3. `repo sync` でソースを取得

## ビルド

```bash
# Nix FHS 環境内で実行
nix develop

# setup.sh build サブコマンドで一括実行
./setup.sh build

# または手動で
cd ~/android/crdroid
source build/envsetup.sh
lunch lineage_c330ae-bp1a-user
make -j$(nproc) bacon
```

ビルド成果物は `out/target/product/c330ae/` に出力されます。

## ダウンロード

ビルド済みのOTAパッケージは [Releases](../../releases) からダウンロードできます。

| ファイル | 用途 |
|---|---|
| `crDroidAndroid-15.0-*-c330ae-*.zip` | OTA パッケージ |

## フラッシュ

### OTA (TWRPサイドロード・推奨)

1. TWRP リカバリを起動
2. `Advanced` → `ADB Sideload` を選択
3. `adb sideload crDroidAndroid-15.0-*-c330ae-*.zip` を実行

### fastboot

```bash
fastboot flash boot boot.img
fastboot flash dtbo dtbo.img
fastboot flash vbmeta vbmeta.img
fastboot -w
fastboot reboot
```

## リポジトリ構成

| ファイル/ディレクトリ | 内容 |
|---|---|
| `flake.nix` | NixOS FHS ビルド環境定義 |
| `flake.lock` | Nix パッケージバージョンロック |
| `local_manifests/c330ae.xml` | repo ローカルマニフェスト |
| `setup.sh` | セットアップ・ビルドスクリプト |
| `releases/` | ビルド成果物のチェックサム |

## 関連リポジトリ

- [デバイスツリー](https://github.com/sashisashi569/android_device_rakuten_c330ae) — `lineage-22.2`（フォーク・パッチ適用済み）
- [カーネル](https://github.com/sashisashi569/android_kernel_rakuten_sdm439) — `lineage-22.2`（フォーク・パッチ適用済み）
- [ベンダー](https://github.com/2by2-Project-Devices/proprietary_vendor_rakuten_c330ae) — `lineage-22.2`
- [crDroid Android](https://github.com/crdroidandroid/android) — `15.0`

### フォークに含まれる変更

**デバイスツリー** (`sashisashi569/android_device_rakuten_c330ae`):
- userビルド時の SELinux `qti_debugfs` ルールをuserdebug/eng限定に分離（userビルドのコンパイル失敗を修正）
- userdebugビルド時のみ ADB をデフォルト有効化

**カーネル** (`sashisashi569/android_kernel_rakuten_sdm439`):
- dm-verity を無効化

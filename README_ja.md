# ad-refkit-sample
FPGAデザインコンテスト向けリファレンスキットのサンプルデザインです

## Overview
- Digilent ZYBO Z7-20を使用
- 自動走行の基本的なプログラムとしてライントレースの実行が可能
- PS部においてUbuntu18.04が動作
- Device Tree Overlayによるデバイスツリーの動的な変更が可能
- FPGA Regionによるビットストリームの動的な読み込みが可能

## Riquirements
- ビルドに利用したホストPCの環境は以下の通りです
    - Ubuntu18.04LTS
    - Vivado2019.1.3
        - MIPI CSI-2 RX Subsystem IPの利用が可能な有料ライセンスが必要です

## Directory structure
``` sh
.
├── assets
│   └── cad
├── docs
└── zybo
    ├── BOOT_FS
    ├── ROOT_FS
    │   ├── app
    │   ├── driver
    │   ├── dts
    │   ├── firmware
    │   ├── lib
    │   ├── package
    │   └── zynq_bsp
    └── vivado
        ├── ip
        ├── prj
        ├── script
        ├── src
        └── xdc
```

- `assets/cad`
    - 3DCADのデータを置いています
- `docs`
    - サンプルデザインのセットアップに関するドキュメントを置いています
- `zybo`
    - サンプルデザインのソースコードやスクリプトなどを置いています
- `zybo/BOOT_FS`
    - Linuxを起動するためのビルド済みのファイル群を置いています
    - Boot File Systemに配置します
- `zybo/ROOT_FS`
    - アプリケーションを実行するためのソースコード・スクリプト等を置いています
    - Root File Systemに配置します
- `zybo/ROOT_FS/app`
    - アプリケーションのソースコードを置いています
- `zybo/ROOT_FS/driver`
    - 必要なデバイスドライバを置いています
- `zybo/ROOT_FS/dts`
    - Device Tree Overlay向けのDTSを置いています
- `zybo/ROOT_FS/firmware`
    - `/lib/firmware`下に配置するファイルを置いています
- `zybo/ROOT_FS/lib`
    - アプリケーション向け共有ライブラリのソースコードを置いています
- `zybo/ROOT_FS/package`
    - 必要なdebパッケージを置いています
- `zybo/ROOT_FS/zynq_bsp`
    - 自動生成されるBSPファイルを配置するためのディレクトリです
- `zybo/vivado`
    - ビットストリームファイルを生成するためのソースコードやスクリプトを置いています
- `zybo/vivado/ip`
    - サンプルデザインにおいて使用するIPを置いています
- `zybo/vivado/prj`
    - プロジェクトを配置するためのディレクトリです
- `zybo/vivado/script`
    - プロジェクトの生成・高位合成の実行・binファイルの生成等を行うスクリプトを置いています
- `zybo/vivado/src`
    - RTLコード、および、高位合成向けC++コードを置いています
- `zybo/vivado/xdc`
    - 制約ファイルを置いています

## How to setup
1. [車体の構築](./docs/sec1/index_ja.md)
2. [ビットストリームの生成](./docs/sec2/index_ja.md)
3. [Linuxカーネルのビルド](./docs/sec3/index_ja.md)
4. [SDカードの準備](./docs/sec4/index_ja.md)
5. [アプリケーションの実行](./docs/sec5/index_ja.md)

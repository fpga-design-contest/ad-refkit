## アプリケーションの実行

### ad-sample
NOTE: 動作未確認

``` sh
$ cd <root path of this repository>/zybo/ROOT_FS/app/pcam-test
$ mkdir build && cd build
$ cmake ..
$ make
$ ./pcam-test
```

### make-calibration-param
NOTE: 動作未確認

OpenCVを用いたカメラキャリブレーションを実行します。\
はじめに、以下の手順に従って画像データを用意して下さい。

1. チェッカーボードを印刷する
2. キャリブレーションを行うカメラでチェッカーボードを様々な角度から30枚程度撮影する
    - チェッカーボード全体が映るように撮影してください
    - 画像ファイルは同一ディレクトリ下に保存してください
    - png形式で保存して下さい
    - ファイル名は`img<番号>.png`としてください
    - `<番号>`は`0`から始まる連番にしてください

画像データが用意できたらキャリブレーションを実行します。

``` sh
$ cd <root path of this repository>/zybo/ROOT_FS/app/make-calibration-param
$ mkdir build && cd build
$ cmake ..
$ make
$ ./make-calibration-param
```

### make-homography-params
前方の路面の俯瞰画像を得る際に必要な射影変換行列を導出します。\
はじめに、以下の手順に従って画像データを用意して下さい。

1. 正方形の紙、もしくは、薄い板を用意する
2. 用意した紙、もしくは、薄い板を車体の前方正面の床面に設置する
3. 撮影する

画像データが用意できたらプログラムを実行します。

``` sh
$ python3 make-homography-params.py
```

正方形の四隅をクリックし、倍率、オフセットを指定すると射影変換行列が出力されます。

### motor-test
モータの動作を確認することが出来ます。

``` sh
$ cd <root path of this repository>/zybo/ROOT_FS/app/motor-test
$ mkdir build && cd build
$ cmake ..
$ make
$ ./motor-test
```

### pcam-test
NOTE: 動作未確認

``` sh
$ cd <root path of this repository>/zybo/ROOT_FS/app/pcam-test
$ mkdir build && cd build
$ cmake ..
$ make
$ ./pcam-test
```

### webcam-test
NOTE: 動作未確認

``` sh
$ cd <root path of this repository>/zybo/ROOT_FS/app/webcam-test
$ mkdir build && cd build
$ cmake ..
$ make
$ ./webcam-test
```

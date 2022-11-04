## 基本

### tar

### curl

## パッケージインストール
---
### apt

#### アーキテクチャ追加

`sudo dpkg --add-architecture i386*`

`sudo dpkg --add-architecture armhf`


#### 依存関係解決した状態でダウンロード

`sudo apt install -d --install-suggests --install-recommends <package-name>`

実行すると`/var/cache/apt/archives`にダウンロードされる

#### debからインストール


#### /var/cache/apt/archivesのクリア

`sudo apt clean`

## 監視
---
### ファイル変更検知


## ネットワーク
---
#### netstat
|  オプション  |  説明  |
| ---- | ---- |
|  `-p`  |  プロセス名を表示  |
|  `-t`  |  TCPポートを表示  |
|  `-u`  |  UDPポートを表示  |
|  `-i`  | ネットワークインターフェース表示 |

### 開いているポート確認

#### debian

`ss -tualpn`

`netstat -an`

### 特定ポートで通信しているプロセス名

#### debian

`netstat -anp`

## バックアップ＆復旧

### mysql
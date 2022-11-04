# 基本

### tar


### curl

---

# パッケージインストール



### apt

#### アーキテクチャ追加

```sudo dpkg --add-architecture i386*```

```sudo dpkg --add-architecture armhf```


#### 依存関係解決した状態でダウンロード

```sudo apt install -d --install-suggests --install-recommends <package-name>```

実行すると`/var/cache/apt/archives`にダウンロードされる

#### debからインストール


#### /var/cache/apt/archivesのクリア

```sudo apt clean```

---

# 監視

### ファイル変更検知

---

# ネットワーク

#### netstat
|  オプション  |  説明  |
| ---- | ---- |
|  `-p`  |  プロセス名を表示  |
|  `-t`  |  TCPポートを表示  |
|  `-u`  |  UDPポートを表示  |
|  `-i`  | ネットワークインターフェース表示 |

### 開いているポート確認

```ss -tualpn```

```netstat -an```

### 特定ポートで通信しているプロセス名

```netstat -anp```

---

# バックアップ＆復旧

### mysql

#### ダンプ出力

```mysqldump --single-transaction -u DBユーザ名 -p DB名 > 出力先ファイル名```

#### 復元

```mysql -u ユーザー名 -p データベース名 < dumpファイル名```


#!/bin/bash
 
# 接続情報
DATABASE1_HOST=localhost
DATABASE1_PORT=3301
DATABASE1_USER=root
DATABASE1_PASS=password

DATABASE2_HOST=localhost
DATABASE2_PORT=3302
DATABASE2_USER=root
DATABASE2_PASS=password

# 設定
MYSQL_SCHEMA="db"
MYSQL_TABLE="__cluster_check_temporary_table"
ROOT_DIRECTORY="/var/tmp"

CMD1_MYSQL="mysql -h $DATABASE1_HOST --port=$DATABASE1_PORT -u $DATABASE1_USER --password=$DATABASE1_PASS --show-warnings $MYSQL_SCHEMA"
CMD2_MYSQL="mysql -h $DATABASE2_HOST --port=$DATABASE2_PORT -u $DATABASE2_USER --password=$DATABASE2_PASS --show-warnings $MYSQL_SCHEMA"

LOG_NAME=/dev/stdout
# LOG_NAME=./mysql-sh.log
# 実行時間の取得
PID=$$_`date '+%H%M%N'`
# ログ出力
exec 1> >(awk '{print strftime("[%Y-%m-%d %H:%M:%S]") "[""'$PID'""]" $0} {fflush()} ' >>$LOG_NAME)
exec 2> >(awk '{print strftime("[%Y-%m-%d %H:%M:%S]") "[""'$PID'""]" $0} {fflush()} ') >2
 
function initQuery() {
    local QUERY="create table if not exists \`$MYSQL_TABLE\`(data text); insert into \`$MYSQL_TABLE\`(data) values('$PID');"
    local VALUE
    VALUE=`echo ${QUERY} | ${CMD1_MYSQL}`
    RES_CODE=$?
    if [[ ! $RES_CODE -eq 0 ]]; then
        echo "[ERROR] '$DATABASE1_HOST:$DATABASE1_PORT' に接続できませんでした"
        return 1
    fi
    echo "[INFO] '$DATABASE1_HOST:$DATABASE1_PORT' の接続に成功しました"
    if [[ $? -eq 0 ]]; then
        # echo $VALUE
        echo "[INFO] '$DATABASE1_HOST:$DATABASE1_PORT' へレコードを挿入しました"
        return 0
    else
        echo "[ERROR] '$DATABASE1_HOST:$DATABASE1_PORT' にレコードを挿入できませんでした"
        return 1
    fi
}

function selectQuery() {
    local QUERY="select data from \`$MYSQL_TABLE\` where data = '$PID';"
    local VALUE
    VALUE=`echo ${QUERY} | ${CMD2_MYSQL}`
    RES_CODE=$?
    if [[ ! $RES_CODE -eq 0 ]]; then
        echo "[ERROR] '$DATABASE2_HOST:$DATABASE2_PORT'に接続できませんでした"
        return 1
    fi
    echo "[INFO] '$DATABASE2_HOST:$DATABASE2_PORT'の接続に成功しました"
    if [[ -n $VALUE ]]; then
        # echo $VALUE
        echo "[INFO] '$DATABASE1_HOST:$DATABASE1_PORT' -> '$DATABASE2_HOST:$DATABASE2_PORT'の同期を確認しました"
        return 0
    else
    
        echo "[ERROR] '$DATABASE1_HOST:$DATABASE1_PORT' -> '$DATABASE2_HOST:$DATABASE2_PORT'で同期を確認できませんでした"
        return 1
    fi
}

function dropQuery() {
    local QUERY="drop table if exists \`$MYSQL_TABLE\`;"
    local VALUE
    VALUE=`echo ${QUERY} | ${CMD1_MYSQL}`
    RES_CODE=$?
    if [[ ! $RES_CODE -eq 0 ]]; then
        echo "[ERROR] '$DATABASE1_HOST' is down/unreachable."
        return 1
    fi
}
 
# 結果のチェック
function checkResult() {
    if [ $1 -eq 1 ]; then
        echo "[ERROR] $0 同期の確認に失敗しました"
        exit 1
    elif [ $1 -eq 0 ]; then
        echo "[INFO] $0 同期を確認しました"
        exit 0
    fi
}
 
# 実際の処理開始
echo "[INFO] $0 DB同期確認 開始"
 
initQuery && \
selectQuery; checkResult $?

# dropQuery;

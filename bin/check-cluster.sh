#!/bin/bash
 
# 接続情報
DATABASE1_HOST=127.0.0.1
DATABASE1_PORT=3301
DATABASE1_USER=root
DATABASE1_PASS=password1

DATABASE2_HOST=127.0.0.1
DATABASE2_PORT=3302
DATABASE2_USER=root
DATABASE2_PASS=password2

# 確認DB設定
MYSQL_SCHEMA="db"
MYSQL_TABLE="__cluster_check_temporary_table"

# メール設定
MAIL_TO="root"
MAIL_FROM="root"
MAIL_SUBJECT="DB同期 確認失敗通知"
MAIL_BODY="DB同期の確認ができませんでした"

# メールコマンド
MAIL_CMD="mail -s \"$MAIL_SUBJECT\" -r $MAIL_FROM $MAIL_TO"
# mysqlコマンド
CMD1_MYSQL="mysql -h $DATABASE1_HOST --port=$DATABASE1_PORT -u $DATABASE1_USER --password=$DATABASE1_PASS --show-warnings $MYSQL_SCHEMA"
CMD2_MYSQL="mysql -h $DATABASE2_HOST --port=$DATABASE2_PORT -u $DATABASE2_USER --password=$DATABASE2_PASS --show-warnings $MYSQL_SCHEMA"

LOG_OUT=/dev/stdout
LOG_ERR=/dev/stderr
# LOG_NAME=./mysql-sh.log

# 実行時間の取得
DATE=`date '+%H%M%N'`

# ログ出力
exec 1> >(awk '{print strftime("[%Y-%m-%d %H:%M:%S]") "[""'$PID'""]" $0} {fflush()} ' >>$LOG_OUT)
exec 2> >(awk '{print strftime("[%Y-%m-%d %H:%M:%S]") "[""'$PID'""]" $0} {fflush()} ' >>$LOG_ERR)
 
function initQuery() {
    local QUERY="create table if not exists \`$MYSQL_TABLE\`(data text); insert into \`$MYSQL_TABLE\`(data) values('$DATE');"
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
        echo "[INFO] '$DATABASE1_HOST:$DATABASE1_PORT' へレコードを挿入しました 挿入:\`$DATE\`"
        return 0
    else
        echo "[ERROR] '$DATABASE1_HOST:$DATABASE1_PORT' にレコードを挿入できませんでした"
        return 1
    fi
}

function selectQuery() {
    local QUERY="select data from \`$MYSQL_TABLE\` where data = '$DATE';"
    local VALUE
    VALUE=`echo ${QUERY} | ${CMD2_MYSQL}`
    if [[ $? -ne 0 ]]; then
        echo "[ERROR] '$DATABASE2_HOST:$DATABASE2_PORT' の接続実行に失敗しました"
        return 1
    fi
    VALUE=`echo "$VALUE" | sed -z 's/data\n//g' /dev/stdin`
    echo "[INFO] '$DATABASE2_HOST:$DATABASE2_PORT' の接続に成功しました"
    # $VALUE=`sed -i -z 's/\n//g' "$VALUE"`
    if [[ "$DATE" = "$VALUE" ]]; then
        # echo $VALUE
        echo "[INFO] '$DATABASE1_HOST:$DATABASE1_PORT' -> '$DATABASE2_HOST:$DATABASE2_PORT' の同期を確認しました 取得:\`$VALUE\`"
        return 0
    else
    
        echo "[ERROR] '$DATABASE1_HOST:$DATABASE1_PORT' -> '$DATABASE2_HOST:$DATABASE2_PORT' で同期を確認できませんでした 取得:\`$VALUE\`"
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

function deleteQuery() {
    local QUERY="delete from \`$MYSQL_TABLE\`;"
    local VALUE
    VALUE=`echo ${QUERY} | ${CMD1_MYSQL}`
    RES_CODE=$?
    if [[ ! $RES_CODE -eq 0 ]]; then
        echo "[ERROR] '$DATABASE1_HOST' is down/unreachable."
        return 1
    fi
    echo "[INFO] '$DATABASE1_HOST:$DATABASE1_PORT' で一時レコードを削除しました"
    return 0
}

# 結果のチェック
function checkResult() {
    if [ $1 -eq 1 ]; then
        echo "[ERROR] $0 同期の確認に失敗しました"
        return "1"
    elif [ $1 -eq 0 ]; then
        echo "[INFO] $0 同期を確認しました"
        return "0"
    fi
    echo "[ERROR] 正常に終了しませんでした"
    return "$1"
}

function sendMail () { 
    # Send mail
    echo "$MAIL_BODY" | $MAIL_CMD

}
 
# 実際の処理開始
echo "[INFO] $0 DB同期確認 開始"

# 同期確認
initQuery && \
selectQuery; checkResult $?
CODE=$?

# 一時レコード削除
deleteQuery
# dropQuery

sendMail
if [ "$CODE" = "0" ]; then
    exit 0
else
    exit 1
fi

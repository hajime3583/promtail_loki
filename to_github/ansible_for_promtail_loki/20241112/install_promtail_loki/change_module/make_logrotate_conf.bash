#!/bin/bash

### 基本情報変数
target_host=`uname -n`
target_system="logrotate"

### 置換用の変数を定義
###source_dir="/var/log/promtail/logs/"
###target_dir="root@192.168.6.125:/var/log/promtail/logs/"
###target_sshpassword="P@ssw0rd"

### サービスファイル用変数
###service_file="/usr/lib/systemd/system/lsyncd.service"
###service_file_tmp="/usr/lib/systemd/system/lsyncd.service"
###service_file_new="/usr/lib/systemd/system/lsyncd.service_${target_host}.service"
template_file="/root/logrotate.d_template.conf"
output_file="/etc/logrotate.d/promtail"
service_name=$(basename $service_file)
###conf_dir=/etc/lsyncd

# ディレクトリの配列
###dirs=(
###    "$conf_dir"
###)

# ディレクトリが存在しない場合は作成し、パーミッションと所有者を設定
###for dir in "${dirs[@]}"; do
###    if [ ! -d "$dir" ]; then
###        mkdir -p "$dir"  # ディレクトリを作成
###        chmod 655 "$dir"  # パーミッションを655に設定
###        chown promtail:promtail "$dir"  # 所有者をloki:lokiに設定
###        echo "ディレクトリを作成しました: $dir"
###    else
###        echo "ディレクトリは既に存在します: $dir"
###    fi
###done

# 既存ファイルのバックアップ
if [ -f "$output_file" ]; then
        bk_file="$output_file"_"file_$(date +%Y%m%d%H%M%S)"
        cp -p $output_file $bk_file # 既存ファイルのバックアップ
        echo "ファイルをバックアップしました: $bk_file"
else
        echo "既存ファイルは存在しません。何もしません: $bk_file"
fi

# sedを使用してテンプレートのプレースホルダーを変数で置換し、出力ファイルに書き込む
sed -e '' "$template_file" > "$output_file"

# 権限の設定
###chmod 644 "$output_file"
###chown promtail:promtail "$output_file"

# サービスの起動
#systemctl restart $service_name
###cp -p ${service_file_tmp} ${service_file_new}

###echo "設定ファイルが生成されました: $output_file"
# systemdの設定ファイルを更新
###if [ -f "$service_file_new" ]; then
###    sed -i "s|^ExecStart=.*|ExecStart=/usr/bin/promtail -config.file $output_file|" $service_file_new
###    systemctl daemon-reload
###    systemctl restart $service_name

###    echo $service_file_new"のExecStartを更新しました: $service_file_new"
###else
###    echo $service_file_new"が見つかりません: $service_file_new"
###fi

# crontabの登録
#!/bin/bash

# cronジョブを複数行追加する
jobs=(
    "0 * * * * /usr/sbin/logrotate -f /etc/logrotate.d/promtail" 
)

# 現在のcrontab内容を取得し、一時ファイルに保存
tmpfile=$(mktemp)
crontab -l 2>/dev/null > "$tmpfile"

# 新しいジョブを一時ファイルに追加
for job in "${jobs[@]}"; do
    echo "$job" >> "$tmpfile"
done

# crontabを更新
crontab "$tmpfile"
rm "$tmpfile"

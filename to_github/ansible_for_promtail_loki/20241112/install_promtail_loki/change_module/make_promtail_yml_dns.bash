#!/bin/bash

### 基本情報変数
target_host="$1"
target_ip="$2"
target_system="dns"

### 置換用の変数を定義
http_listen_port="$3"
grpc_listen_port="$4"
positions_file="$5"
client1_url="$6"
client2_url="$7"
job_name="$8"
job="$9"
log_path="${10}"
conf_dir="/etc/promtail/conf"
timezone="${11}"
conf_dir="/etc/promtail/conf"

# ymlテンプレートファイルと出力ファイルのパスを指定
template_file="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/nxlog_${target_system}_template.yml"
output_file="/etc/promtail/conf/config.yml.from.nxlog_${target_system}"

### サービスファイル用変数
service_file_tmp="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/template.service_${target_system}"
service_file_new="/etc/systemd/system/promtail_${target_system}.service"
template_file="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/promtail_template_${target_system}.yml"
output_file="/etc/promtail/conf/config.yml.from.nxlog_${target_system}"
service_name=$(basename $service_file_new)

# ディレクトリの配列
dirs=(
    "$conf_dir"
)

# ディレクトリが存在しない場合は作成し、パーミッションと所有者を設定
for dir in "${dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"  # ディレクトリを作成
        chmod 655 "$dir"  # パーミッションを655に設定
        chown promtail:promtail "$dir"  # 所有者をloki:lokiに設定
        echo "ディレクトリを作成しました: $dir"
    else
        echo "ディレクトリは既に存在します: $dir"
    fi
done

# sedを使用してテンプレートのプレースホルダーを変数で置換し、出力ファイルに書き込む
sed -e "s|{http_listen_port}|$http_listen_port|g" \
    -e "s|{grpc_listen_port}|$grpc_listen_port|g" \
    -e "s|{positions_file}|$positions_file|g" \
    -e "s|{client1_url}|$client1_url|g" \
    -e "s|{client2_url}|$client2_url|g" \
    -e "s|{job_name}|$job_name|g" \
    -e "s|{job}|$job|g" \
    -e "s|{log_path}|$log_path|g" \
    -e "s|{timezone}|$timezone|g" \
    "$template_file" > "$output_file"

# 権限の設定
#chmod 644 "$output_file"
#chown promtail:promtail "$output_file"

# サービスの起動
cp -p ${service_file_tmp} ${service_file_new}

echo "設定ファイルが生成されました: $output_file"
# systemdの設定ファイルを更新
if [ -f "$service_file_new" ]; then
    sed -i "s|^ExecStart=.*|ExecStart=/usr/bin/promtail -config.file $output_file|" $service_file_new
    systemctl daemon-reload
    systemctl restart $service_name

    echo $service_file_new"のExecStartを更新しました: $service_file_new"
else
    echo $service_file_new"が見つかりません: $service_file_new"
fi

# 既存デフォルトサービスの停止および無効化
if systemctl is-active --quiet promtail; then
    echo "Promtail service is running. Stopping and disabling it..."
    # サービスの停止
    sudo systemctl stop promtail
    # サービスの無効化
    sudo systemctl disable promtail
    echo "Promtail service has been stopped and disabled."
else
    echo "Promtail service is not running."
fi

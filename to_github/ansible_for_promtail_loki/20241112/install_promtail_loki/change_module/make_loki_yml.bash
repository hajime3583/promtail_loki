#!/bin/bash

### 基本情報変数
target_host="$1"
target_ip="$2"
#target_system="loki"

# 変数の定義
http_listen_port="${5}"
path_prefix="${6}"
active_index_directory="${7}"
cache_location="${8}"
directory="${9}"
loki_service_file="/etc/systemd/system/loki.service"

# ディレクトリの配列
dirs=(
    "$cache_location"
    "$path_prefix"
    "$active_index_directory"
    "$directory"
)

# ディレクトリが存在しない場合は作成し、パーミッションと所有者を設定
for dir in "${dirs[@]}"; do
    ##if [ ! -d "$dir" ]; then
        mkdir -p "$dir"  # ディレクトリを作成
        chmod 755 "$dir"  # パーミッションを655に設定
        chown loki:loki "$dir"  # 所有者をloki:lokiに設定
        echo "ディレクトリを作成しました: $dir"
    ##else
    ##    echo "ディレクトリは既に存在します: $dir"
    ##fi
done

# テンプレートファイルのパス
template_file="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/loki_template.yml"
output_file="/etc/loki/loki_generated.yml"

# テンプレートを変換しながら新しいファイルに保存
sed -e "s|{cache_location}|$cache_location|g" \
    -e "s|{http_listen_port}|$http_listen_port|g" \
    -e "s|{path_prefix}|$path_prefix|g" \
    -e "s|{active_index_directory}|$active_index_directory|g" \
    -e "s|{directory}|$directory|g" \
    "$template_file" > "$output_file"

echo "設定ファイルが生成されました: $output_file"

# systemdの設定ファイルを更新
if [ -f "$loki_service_file" ]; then
    sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/loki -config.file /etc/loki/loki_generated.yml|' "$loki_service_file"
    systemctl daemon-reload
    systemctl restart loki.service

    echo "loki.serviceのExecStartを更新しました: $loki_service_file"
else
    echo "loki.serviceファイルが見つかりません: $loki_service_file"
fi


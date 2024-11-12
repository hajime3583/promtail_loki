import subprocess
import os
import logging
import sys

# ログ設定
logging.basicConfig(filename='script.log', level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# リストファイルを読み込み、インストールする対象を取得
def read_list_file(file_path):
    if not os.path.exists(file_path):
        logging.error(f"List file not found: {file_path}")
        raise FileNotFoundError(f"No such file: '{file_path}'")

    with open(file_path, 'r') as file:
        return [line.strip() for line in file]

# RPMをインストールする関数
def install_rpm(rpm_path):
    try:
        logging.info(f"Installing RPM: {rpm_path}")
        subprocess.run(["rpm", "-ivh", rpm_path], check=True)
        logging.info(f"{rpm_path} installed successfully!")
    except subprocess.CalledProcessError as e:
        logging.error(f"Error installing {rpm_path}: {e}")

# Promtailのインストール
def install_promtail(rpm_files):
    try:
        logging.info("Installing Promtail...")
        install_rpm(rpm_files['promtail'])
        install_rpm(rpm_files['lsync'])  # Promtailインストール時にlsyncもインストール
        install_rpm(rpm_files['sshpass'])  # Promtailインストール時にsshpassもインストール
        #install_rpm(rpm_files['rsyslog'])  # Promtailインストール時にrsyslogもインストール
        subprocess.run(["yum", "install", "-y", "rsyslog"], check=True)
        logging.info("Promtail and dependencies installed successfully!")
    except subprocess.CalledProcessError as e:
        logging.error(f"Error installing Promtail or its dependencies: {e}")

# Lokiのインストール
def install_loki(rpm_files):
    try:
        logging.info("Installing Loki...")
        install_rpm(rpm_files['loki'])
        logging.info("Loki installed successfully!")
    except subprocess.CalledProcessError as e:
        logging.error(f"Error installing Loki: {e}")

# メインのインストール処理
def main(script_path, item):
    rpm_files = {
        'promtail': os.path.join(script_path, 'promtail-2.9.0.x86_64.rpm'),
        'loki': os.path.join(script_path, 'loki-2.9.4.x86_64.rpm'),
        'lsync': os.path.join(script_path, 'lsyncd-2.2.2-9.el8.x86_64.rpm'),
        'sshpass': os.path.join(script_path, 'sshpass-1.09-4.el8.x86_64.rpm'),
        'rsyslog': os.path.join(script_path, 'rsyslog-8.2102.0-15.el8.x86_64.rpm') #これは不要かもしれないのでVM払い出し後に確認！
    }

    if item.lower() == 'promtail':
        install_promtail(rpm_files)
    elif item.lower() == 'loki':
        install_loki(rpm_files)
    else:
        logging.warning(f"Unknown installation target: {item}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python install_script.py <target>")
        sys.exit(1)

    item = sys.argv[1]  # インストール対象 ('promtail' または 'loki' など)
    script_dir = os.path.dirname(os.path.abspath(__file__))  # スクリプトが存在するディレクトリを取得
    main(script_dir, item)


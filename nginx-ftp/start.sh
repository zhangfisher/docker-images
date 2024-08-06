#!/bin/sh

# 定义源目录和目标目录
SRC_DIR="/initdata"
DEST_DIR="/data"

# 遍历源目录中的所有文件和子目录
find "$SRC_DIR" -type f | while read -r FILE; do
  # 获取相对路径
  REL_PATH="${FILE#$SRC_DIR/}"
  # 获取目标文件路径
  DEST_FILE="$DEST_DIR/$REL_PATH"
  # 获取目标文件的目录
  DEST_DIR_PATH=$(dirname "$DEST_FILE")

  # 如果目标文件的目录不存在，则创建
  if [ ! -d "$DEST_DIR_PATH" ]; then
    mkdir -p "$DEST_DIR_PATH"
  fi

  # 如果目标文件不存在，则复制
  if [ ! -f "$DEST_FILE" ]; then
    cp "$FILE" "$DEST_FILE"
  fi
done

mkdir -p /data/logs
chmod -R 777 /data/logs
chown -R $FTP_ADMIN_USER:$FTP_ADMIN_USER /data/www
chmod -R 777 /data/www


# 启动
vsftpd /data/config/vsftpd.conf & nginx -c /data/config/nginx.conf -g 'daemon off;'
#!/bin/bash

set -e  # 遇到错误立即退出

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

# 定义源目录和目标目录
SRC_DIR="/initdata"
DEST_DIR="/data"

log "开始初始化..."

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
chown -R $ADMIN_USER:$ADMIN_USER /data/www
chmod -R 777 /data/www

# 支持环境变量覆盖vsftpd被动模式端口配置
if [ -n "$PASV_MIN_PORT" ] && [ -n "$PASV_MAX_PORT" ]; then
    log "更新vsftpd被动端口范围: $PASV_MIN_PORT-$PASV_MAX_PORT"
    sed -i "s/^pasv_min_port=.*/pasv_min_port=$PASV_MIN_PORT/" /data/config/vsftpd.conf
    sed -i "s/^pasv_max_port=.*/pasv_max_port=$PASV_MAX_PORT/" /data/config/vsftpd.conf
fi

# 启动SSH服务
log "启动SSH服务..."
/usr/sbin/sshd || {
    error "SSH启动失败"
    # 不退出，SSH失败不影响其他服务
}

# 生成索引文件
log "生成索引文件..."
/buildindex.sh || {
    error "索引生成失败"
    # 不退出，索引失败不影响其他服务
}

# 启动vsftpd
log "启动vsftpd FTP服务..."

# 创建最小化的vsftpd配置（避免兼容性问题）
cat > /data/config/vsftpd.conf << 'EOF'
listen=YES
listen_port=21
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
xferlog_enable=YES
xferlog_file=/data/logs/vsftpd.log
chroot_local_user=YES
allow_writeable_chroot=YES
seccomp_sandbox=NO
pasv_enable=YES
pasv_min_port=10000
pasv_max_port=10010
local_root=/data/www
background=YES
EOF

# 更新被动端口配置
if [ -n "$PASV_MIN_PORT" ] && [ -n "$PASV_MAX_PORT" ]; then
    log "更新vsftpd被动端口范围: $PASV_MIN_PORT-$PASV_MAX_PORT"
    sed -i "s/^pasv_min_port=.*/pasv_min_port=$PASV_MIN_PORT/" /data/config/vsftpd.conf
    sed -i "s/^pasv_max_port=.*/pasv_max_port=$PASV_MAX_PORT/" /data/config/vsftpd.conf
fi

# 启动vsftpd并记录详细错误
log "启动vsftpd进程..."
vsftpd /data/config/vsftpd.conf 2>&1 | tee -a /data/logs/startup.log &
VSFTPD_PID=$!

sleep 3

if ! pgrep -x "vsftpd" > /dev/null; then
    error "vsftpd启动失败！详细诊断:"

    error "1. 当前配置文件内容:"
    cat /data/config/vsftpd.conf | tee -a /data/logs/startup.log

    error "2. vsftpd详细错误信息:"
    vsftpd /data/config/vsftpd.conf -dd 2>&1 | head -30 | tee -a /data/logs/startup.log

    error "3. 检查vsftpd二进制文件:"
    which vsftpd
    vsftpd -version 2>&1 | tee -a /data/logs/startup.log

    error "4. 检查端口占用:"
    netstat -tlnp | grep 21 2>&1 | tee -a /data/logs/startup.log || ss -tlnp | grep 21 2>&1 | tee -a /data/logs/startup.log

    error "5. 检查日志文件:"
    ls -la /data/logs/ 2>&1 | tee -a /data/logs/startup.log
    cat /data/logs/vsftpd.log 2>&1 | tee -a /data/logs/startup.log || true

    error "vsftpd启动失败，停止容器"
    exit 1
fi

log "vsftpd启动成功 (PID: $(pgrep -x vsftpd))"

# 启动文件监控服务
log "启动文件监控服务..."
/watch.sh &

# 启动Nginx (前台运行)
log "启动Nginx服务..."
exec nginx -c /data/config/nginx.conf -g 'daemon off;'
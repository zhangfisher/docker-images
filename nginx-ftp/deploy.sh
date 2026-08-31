#!/bin/bash

echo "=== Nginx-FTP 完整部署和测试脚本 ==="
echo ""

CONTAINER_NAME="ftp-docs"
IMAGE_NAME="nginx-ftp:latest"
VOLUME_PATH="/home/meeyi/docs"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

error() {
    echo -e "${RED}✗ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# 1. 停止并删除旧容器
echo "1. 清理旧容器..."
if docker ps -a | grep -q $CONTAINER_NAME; then
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
    success "旧容器已清理"
else
    warning "没有找到旧容器"
fi
echo ""

# 2. 重新构建镜像
echo "2. 重新构建镜像..."
docker build -t $IMAGE_NAME . || {
    error "镜像构建失败"
    exit 1
}
success "镜像构建完成"
echo ""

# 3. 启动新容器
echo "3. 启动新容器..."
docker run -d --name $CONTAINER_NAME \
  --restart always \
  -p 80:80 \
  -p 20:20 \
  -p 21:21 \
  -p 222:22 \
  -p 21100-21110:21100-21110 \
  -v "$VOLUME_PATH:/data" \
  -e PASV_MIN_PORT=21100 \
  -e PASV_MAX_PORT=21110 \
  $IMAGE_NAME

if [ $? -eq 0 ]; then
    success "容器已启动"
else
    error "容器启动失败"
    exit 1
fi
echo ""

# 4. 等待服务启动
echo "4. 等待服务启动..."
for i in {1..10}; do
    echo -n "."
    sleep 1
done
echo ""
echo ""

# 5. 检查容器状态
echo "5. 检查容器状态:"
if docker ps | grep -q $CONTAINER_NAME; then
    success "容器正在运行"
    docker ps | grep $CONTAINER_NAME
else
    error "容器未运行"
    docker logs --tail 20 $CONTAINER_NAME
    exit 1
fi
echo ""

# 6. 检查启动日志
echo "6. 检查启动日志:"
docker logs --tail 30 $CONTAINER_NAME
echo ""

# 7. 检查vsftpd进程
echo "7. 检查vsftpd进程:"
if docker exec $CONTAINER_NAME ps aux | grep -q vsftpd; then
    success "vsftpd进程运行中"
    docker exec $CONTAINER_NAME ps aux | grep vsftpd
else
    error "vsftpd进程未运行"
fi
echo ""

# 8. 检查nginx进程
echo "8. 检查nginx进程:"
if docker exec $CONTAINER_NAME ps aux | grep -q nginx; then
    success "nginx进程运行中"
    docker exec $CONTAINER_NAME ps aux | grep nginx
else
    error "nginx进程未运行"
fi
echo ""

# 9. 检查端口监听
echo "9. 检查端口监听:"
echo "vsftpd端口21:"
if docker exec $CONTAINER_NAME netstat -tlnp 2>/dev/null | grep -q ":21 "; then
    success "端口21已监听"
    docker exec $CONTAINER_NAME netstat -tlnp 2>/dev/null | grep ":21"
elif docker exec $CONTAINER_NAME ss -tlnp 2>/dev/null | grep -q ":21"; then
    success "端口21已监听"
    docker exec $CONTAINER_NAME ss -tlnp 2>/dev/null | grep ":21"
else
    error "端口21未监听"
fi
echo ""

echo "nginx端口80:"
if docker exec $CONTAINER_NAME netstat -tlnp 2>/dev/null | grep -q ":80 "; then
    success "端口80已监听"
    docker exec $CONTAINER_NAME netstat -tlnp 2>/dev/null | grep ":80"
elif docker exec $CONTAINER_NAME ss -tlnp 2>/dev/null | grep -q ":80"; then
    success "端口80已监听"
    docker exec $CONTAINER_NAME ss -tlnp 2>/dev/null | grep ":80"
else
    error "端口80未监听"
fi
echo ""

# 10. 测试FTP连接
echo "10. 测试FTP连接:"
if timeout 5 bash -c "echo > /dev/tcp/localhost/21" 2>/dev/null; then
    success "FTP端口21可访问"

    # 测试FTP协议
    FTP_RESPONSE=$(echo "QUIT" | timeout 5 nc localhost 21 2>/dev/null)
    if [[ "$FTP_RESPONSE" == *"220"* ]]; then
        success "FTP服务响应正常: $FTP_RESPONSE"
    else
        warning "FTP服务响应异常: $FTP_RESPONSE"
    fi
else
    error "FTP端口21不可访问"
fi
echo ""

# 11. 测试Web连接
echo "11. 测试Web连接:"
if timeout 5 bash -c "echo > /dev/tcp/localhost/80" 2>/dev/null; then
    success "Web端口80可访问"

    # 测试HTTP响应
    HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" localhost:80 2>/dev/null)
    if [ "$HTTP_RESPONSE" = "200" ] || [ "$HTTP_RESPONSE" = "301" ] || [ "$HTTP_RESPONSE" = "302" ]; then
        success "HTTP服务响应正常 (状态码: $HTTP_RESPONSE)"
    else
        warning "HTTP服务响应异常 (状态码: $HTTP_RESPONSE)"
    fi
else
    error "Web端口80不可访问"
fi
echo ""

# 12. 测试FTP认证
echo "12. 测试FTP认证:"
FTP_AUTH=$(echo -e "USER admin\nPASS 123456##**\nQUIT" | timeout 5 nc localhost 21 2>/dev/null)
if echo "$FTP_AUTH" | grep -q "230"; then
    success "FTP认证成功！"
else
    warning "FTP认证可能有问题"
    echo "$FTP_AUTH" | head -5
fi
echo ""

echo "=== 部署测试完成 ==="
echo ""
echo "📋 后续维护命令:"
echo "  查看日志: docker logs -f $CONTAINER_NAME"
echo "  进入容器: docker exec -it $CONTAINER_NAME /bin/bash"
echo "  重启容器: docker restart $CONTAINER_NAME"
echo "  停止容器: docker stop $CONTAINER_NAME"
echo ""
echo "🌐 服务访问地址:"
echo "  FTP: ftp://localhost:21 (用户: admin, 密码: 123456##**)"
echo "  Web: http://localhost:80"
echo "  SSH: ssh -p 222 admin@localhost (密码: 123456##**)"
echo ""
echo "📊 实时监控:"
echo "  docker stats $CONTAINER_NAME"
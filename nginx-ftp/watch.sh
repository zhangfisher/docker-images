#!/bin/bash


# 监听的目录
WATCH_DIR="/data/www"

# 要执行的脚本：自动重新生成index.json文件
EXECUTE_SCRIPT="/buildindex.sh"

# 使用inotifywait监听readme.md和index.html文件的创建和修改事件
inotifywait -m -r -e create -e modify --format '%w%f' "$WATCH_DIR" | while read FILE
do
  if [[ "$FILE" == *"readme.md" || "$FILE" == *"index.html" ]]; then
    echo "Detected change in $FILE. Executing $EXECUTE_SCRIPT..."
    bash "$EXECUTE_SCRIPT"
  fi
done
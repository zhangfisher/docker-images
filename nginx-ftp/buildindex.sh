#!/bin/bash

# 扫描根目录下的所有子文件夹里面的README.md和index.hrml文件，生成index.json文件
# index.json文件提取所有子文件夹里面的README.md和index.hrml文件的标题和描述
#!/bin/bash

# 定义处理 README.md 文件的函数
process_readme() {
  local file="$1"
  local folder_name=$(basename "$(dirname "$file")")
  local title=""
  local description=""
  local in_description=false

  while IFS= read -r line; do
    if [[ -z "$title" && "$line" =~ ^# ]]; then
      title="${line#\# }"
    elif [[ -z "$title" && -n "$line" ]]; then
      continue
    elif [[ -n "$title" && "$line" =~ ^# ]]; then
      break
    elif [[ -n "$title" ]]; then
      description+="$line\n"
    fi
  done < "$file"

  # Remove trailing newline from description
  description=$(echo -e "$description" | sed ':a;N;$!ba;s/\n/\\n/g')

  echo "{ \"name\": \"$folder_name\", \"title\": \"$title\", \"description\": \"$description\" }," >> "$output_file"
}

# 定义处理 index.html 文件的函数
process_html() {
  local file="$1"
  local folder_name=$(basename "$(dirname "$file")")
  local title=$(sed -n 's:.*<title>\(.*\)</title>.*:\1:p' "$file")
  local description=$(sed -n 's:.*<meta name="description" content="\([^"]*\)".*:\1:p' "$file")

  echo "{ \"name\": \"$folder_name\", \"title\": \"$title\", \"description\": \"$description\" }," >> "$output_file"
}

# 导出函数和变量以便 find -exec 使用
export -f process_readme
export -f process_html
export output_file="index.json"

# 定义输出文件
echo "[" > "$output_file"
cd /data/www
# 查找所有 README.md 和 index.html 文件并处理它们
find . -type f \( -name "readme.md" -o -name "index.html" \) -exec bash -c '
  file="$1"
  if [[ "$file" == *"index.html" ]]; then
    process_html "$file"
  else
    process_readme "$file"
  fi
' _ {} \;

# 移除最后一个逗号并关闭 JSON 数组
sed -i '$ s/,$//' "$output_file"
echo "]" >> "$output_file"
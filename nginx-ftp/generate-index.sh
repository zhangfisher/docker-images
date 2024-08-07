#!/bin/bash

# 扫描根目录下的所有子文件夹里面的README.md和index.hrml文件，生成index.json文件
# index.json文件提取所有子文件夹里面的README.md和index.hrml文件的标题和描述


output_file="index.json"
echo "[" > $output_file

# Function to process each README.md file
process_readme() {
  local file=$1
  local folder_name=$(dirname "$file")
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

  echo "{ \"name\": \"$folder_name\", \"title\": \"$title\", \"description\": \"$description\" }," >> $output_file
}

# Function to process each index.html file
process_html() {
  local file=$1
  local folder_name=$(dirname "$file")
  local title=$(grep -oP '(?<=<title>).*?(?=</title>)' "$file")
  local description=$(grep -oP '(?<=<meta name="description" content=").*?(?=")' "$file")

  echo "{ \"name\": \"$folder_name\", \"title\": \"$title\", \"description\": \"$description\" }," >> $output_file
}

# Export the functions to be used by find -exec
export -f process_readme
export -f process_html


export output_file

# Find all README.md and index.html files and process them
find docs -type f \( -name "readme.md" -o -name "index.html" \) -exec bash -c '
  if [[ "$0" == *"index.html" ]]; then
    process_html "$0"
  else
    process_readme "$0"
  fi
' {} \;

# Remove the last comma and close the JSON array
sed -i '$ s/,$//' $output_file
echo "]" >> $output_file
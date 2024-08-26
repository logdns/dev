#!/bin/bash

# 函数：判断文件或文件夹是否是系统运行所必需
function is_critical_system_path() {
    local filepath=$1
    local critical_paths=(
        "/bin" "/boot" "/dev" "/etc" "/lib" "/proc" "/sbin" "/sys" "/usr" "/var"
        "/lib64" "/run" "/opt" "/root" "/srv" "/tmp" "/mnt"
    )

    for critical_path in "${critical_paths[@]}"; do
        if [[ $filepath == $critical_path* ]]; then
            return 0  # 是关键系统路径
        fi
    done

    return 1  # 不是关键系统路径
}

# 查找占用存储最多的文件或文件夹
echo "查找系统中占用存储最多的文件或文件夹..."
du -ah / | sort -rh | head -n 20 > /tmp/largest_files.txt

# 显示占用最多的前20个文件或文件夹，并标记是否为关键系统路径
echo "以下是系统中占用存储最多的前20个文件或文件夹："
while read -r line; do
    filepath=$(echo $line | awk '{print $2}')
    if is_critical_system_path "$filepath"; then
        echo "[系统关键路径] $line"
    else
        echo "$line"
    fi
done < /tmp/largest_files.txt

echo "操作完成。"
echo "临时文件保存在 /tmp/largest_files.txt"

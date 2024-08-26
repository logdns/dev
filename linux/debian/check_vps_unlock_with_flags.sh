#!/bin/bash

# ===================================================================
#  __  _____ _   _    _    ___   ____  _____ 
#  \ \/ /_ _| \ | |  / \  |_ _| |  _ \| ____|
#   \  / | ||  \| | / _ \  | |  | | | |  _|  
#   /  \ | || |\  |/ ___ \ | |  | |_| | |___ 
#  /_/\_\___|_| \_/_/   \_\___| |____/|_____|
#
#                VPS 流媒体解锁检测脚本 v1.0
#                    作者: xinai.de
# ===================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
NC='\033[0m' # No Color

CHECK_MARK="${GREEN}✓${NC}"
CROSS_MARK="${RED}✗${NC}"
ARROW=">"
ROCKET="*"

declare -A services=(
  ["Netflix"]="https://www.netflix.com/title/80018499"
  ["YouTube"]="https://www.youtube.com/"
  ["Hulu"]="https://www.hulu.com/"
  ["DisneyPlus"]="https://www.disneyplus.com/"
  ["AmazonPrimeVideo"]="https://www.primevideo.com/"
  ["BBCiPlayer"]="https://www.bbc.co.uk/iplayer"
  ["HBO"]="https://www.hbo.com/"
  ["ChatGPT"]="https://chat.openai.com/"
)

declare -A country_codes=(
  ["US"]="美国" ["JP"]="日本" ["GB"]="英国" ["DE"]="德国" ["FR"]="法国"
  ["CN"]="中国" ["IN"]="印度" ["KR"]="韩国" ["CA"]="加拿大"
)

show_title() {
    echo -e "${CYAN}${BOLD}"
    echo "========================================================"
    echo "  __  _____ _   _    _    ___   ____  _____            "
    echo "  \\ \\/ /_ _| \\ | |  / \\  |_ _| |  _ \\| ____|       "
    echo "   \\  / | ||  \\| | / _ \\  | |  | | | |  _|          "
    echo "   /  \\ | || |\\  |/ ___ \\ | |  | |_| | |___         "
    echo "  /_/\\_\\___|_| \\_/_/   \\_\\___| |____/|_____|      "
    echo "                                                        "
    echo "          VPS 流媒体解锁检测脚本 v1.0                   "
    echo "              作者: xinai.de                            "
    echo "========================================================"
    echo -e "${NC}"
}

get_geo_info() {
    local ip_info=$(curl -s https://ipinfo.io)
    local country=$(echo $ip_info | jq -r .country)
    local region=$(echo $ip_info | jq -r .region)
    local city=$(echo $ip_info | jq -r .city)
    local country_name=${country_codes[$country]}
    echo -e "${BOLD}${UNDERLINE}当前 VPS 信息:${NC}"
    echo -e "  ${CYAN}国家/地区:${NC} $country_name ($country)"
    echo -e "  ${CYAN}城市:${NC} $city"
    echo -e "  ${CYAN}地区:${NC} $region"
}

check_tools() {
    local missing_tools=()
    for tool in curl jq; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=($tool)
        fi
    done
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}${BOLD}错误: 以下工具未安装:${NC} ${missing_tools[*]}"
        echo -e "${YELLOW}请安装缺失的工具后重试。${NC}"
        exit 1
    fi
}

check_service() {
    local service_name=$1
    local service_url=$2
    printf "${ARROW} ${BOLD}%-20s${NC}" "$service_name"

    case $service_name in
        "Netflix")
            local response=$(curl -s -L "$service_url")
            if [[ "$response" =~ "Sorry, we can't find that page" ]]; then
                echo -e "$CROSS_MARK ${RED}未解锁${NC}"
            else
                echo -e "$CHECK_MARK ${GREEN}已解锁${NC}"
            fi
            ;;
        "YouTube")
            local status_code=$(curl -s -o /dev/null -w "%{http_code}" "$service_url")
            if [ "$status_code" -eq 200 ]; then
                echo -e "$CHECK_MARK ${GREEN}已解锁${NC}"
            else
                echo -e "$CROSS_MARK ${RED}未解锁${NC}"
            fi
            ;;
        "DisneyPlus")
            local response=$(curl -s -L "$service_url")
            if [[ "$response" =~ "Sorry, Disney+ is not available in your region" ]]; then
                echo -e "$CROSS_MARK ${RED}未解锁${NC}"
            else
                echo -e "$CHECK_MARK ${GREEN}已解锁${NC}"
            fi
            ;;
        "BBCiPlayer")
            local response=$(curl -s -L "$service_url")
            if [[ "$response" =~ "BBC iPlayer only works in the UK" ]]; then
                echo -e "$CROSS_MARK ${RED}未解锁${NC}"
            else
                echo -e "$CHECK_MARK ${GREEN}已解锁${NC}"
            fi
            ;;
        *)
            local status_code=$(curl -s -o /dev/null -w "%{http_code}" "$service_url")
            if [ "$status_code" -eq 200 ]; then
                echo -e "$CHECK_MARK ${GREEN}已解锁${NC}"
            else
                echo -e "$CROSS_MARK ${RED}未解锁 ${DIM}(状态码: $status_code)${NC}"
            fi
            ;;
    esac
}

main() {
    show_title
    check_tools
    get_geo_info
    echo -e "\n${YELLOW}${BOLD}${UNDERLINE}服务解锁状态检测:${NC}\n"

    local country=$(curl -s https://ipinfo.io | jq -r .country)
    local country_name=${country_codes[$country]}
    echo -e "${BLUE}${BOLD}检测 $country_name ($country) 地区流媒体服务...${NC}\n"
    
    for service in "${!services[@]}"; do
        check_service "$service" "${services[$service]}"
    done

    echo -e "\n${GREEN}${BOLD}${ROCKET} 检测完成！${NC}"
}

main

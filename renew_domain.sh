#!/bin/bash

# domains.txt의 각 줄에서 첫 번째 컬럼만 추출하여 "-d "를 붙입니다.
domain_args=$(awk '{print "-d", $1}' domains.txt)

if [ "$1" = "init" ]; then
    echo "Initializing certificate with nginx plugin..."
    sudo certbot --nginx $domain_args
elif [ "$1" = "update" ]; then
    echo "Updating certificate using certificate name nansan.site..."
    sudo certbot certonly --cert-name nansan.site $domain_args
else
    echo "Usage: $0 {init|update}"
    exit 1
fi

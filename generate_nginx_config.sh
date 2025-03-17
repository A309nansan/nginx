#!/bin/bash

# 생성할 Nginx 설정 파일 저장 경로
config_dir="/etc/nginx/conf.d"

# http-redirect.conf 파일 생성
cat <<'EOF' | sudo tee "$config_dir/http-redirect.conf" > /dev/null
server {
    listen 80;
    server_name nansan.site *.nansan.site;

    return 301 https://$host$request_uri;
}
EOF

echo "Created $config_dir/http-redirect.conf"

# 도메인 리스트 파일 경로
subdomain_list_file="domains.txt"

# 파일 존재 여부 확인
if [ ! -f "$subdomain_list_file" ]; then
    echo "Error: File '$subdomain_list_file' not found in the current directory!"
    exit 1
fi

# 서브 도메인 리스트 파일을 한 줄씩 읽음
while read -r domain port; do
    # 빈 줄 또는 주석 무시
    [[ -z "$domain" || "$domain" == \#* ]] && continue

    if [ "$domain" == "nansan.site" ]; then
        output_file="$config_dir/default.conf"
        log_prefix="nansan"
    else
        # 도메인 이름의 맨 앞 부분을 추출
        prefix=$(echo "$domain" | cut -d '.' -f1)
        output_file="$config_dir/${prefix}.conf"
        log_prefix="$prefix"
    fi

    # 파일이 존재하지 않을 경우에만 Nginx 설정 파일 생성
    if [ ! -f "$output_file" ]; then
        cat <<EOF > "$output_file"
server {
    listen 443 ssl http2;
    server_name ${domain};

    include /etc/nginx/snippets/headers.conf;
    include /etc/nginx/snippets/ssl.conf;

    access_log /var/log/nginx/${log_prefix}_nansan_access.log main;
    error_log  /var/log/nginx/${log_prefix}_nansan_error.log warn;

    location / {
        proxy_pass http://127.0.0.1:${port};
        include /etc/nginx/snippets/proxy-settings.conf;
    }
}
EOF
        echo "Created $output_file"
    else
        echo "$output_file already exists. Skipping creation."
    fi
done < "$subdomain_list_file"

echo "All configurations generated successfully!"

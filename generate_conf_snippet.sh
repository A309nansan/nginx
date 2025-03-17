#!/bin/bash

# 스니펫 파일들이 저장될 디렉터리
snippet_dir="/etc/nginx/snippets"

# 스니펫 디렉터리가 없으면 생성
if [ ! -d "$snippet_dir" ]; then
    echo "Creating directory $snippet_dir"
    sudo mkdir -p "$snippet_dir"
fi

# headers.conf 생성
cat <<'EOF' | sudo tee "$snippet_dir/headers.conf" > /dev/null
# HSTS (HTTP Strict Transport Security) 적용
# 브라우저가 오직 HTTPS로만 접속하도록 강제
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
# 페이지가 같은 도메인 내의 다른 페이지에 의해서만 iframe으로 포함될 수 있음을 명시
# clickjacking 공격을 예방
add_header X-Frame-Options SAMEORIGIN always;
# 브라우저가 서버에서 지정한 Content-Type을 따르도록 강제
# XSS 공격 등을 예방
add_header X-Content-Type-Options nosniff always;
# 브라우저의 내장 XSS 필터를 활성화하여, 악성 스크립트가 감지되면 페이지의 렌더링을 차단
add_header X-XSS-Protection "1; mode=block" always;
# HTTPS 페이지에서 HTTP 페이지로 이동할 때는 Referer 정보를 전송하지 않고, 그 외에는 전송
add_header Referrer-Policy "no-referrer-when-downgrade" always;
EOF

echo "Created $snippet_dir/headers.conf"

# ssl.conf 생성
cat <<'EOF' | sudo tee "$snippet_dir/ssl.conf" > /dev/null
# SSL 인증서 설정
ssl_certificate /etc/letsencrypt/live/nansan.site/fullchain.pem; # managed by Certbot
ssl_certificate_key /etc/letsencrypt/live/nansan.site/privkey.pem; # managed by Certbot
include /etc/letsencrypt/options-ssl-nginx.conf;
# DH 키 교환 방식은 양측이 안전하게 공유 비밀을 생성하는 방법 중 하나로, Perfect Forward Secrecy (PFS) 를 보장
ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
EOF

echo "Created $snippet_dir/ssl.conf"

# proxy-settings.conf 생성
cat <<'EOF' | sudo tee "$snippet_dir/proxy-settings.conf" > /dev/null
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
# 프록시를 통해 전달되는 클라이언트 IP와 프로토콜 정보를 애플리케이션에 전달
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
# 클라이언트가 전송할 수 있는 요청 본문의 최대 크기를 제한하여, 대용량 업로드로 인한 서비스 거부(DoS) 공격을 예방
client_max_body_size 10M;
EOF

echo "Created $snippet_dir/proxy-settings.conf"

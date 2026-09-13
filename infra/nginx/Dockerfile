FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/nginx.conf

# 베이스 이미지의 기본 conf.d/default.conf(server_name: localhost)를 제거하지 않으면
# Host: localhost로 오는 요청이 우리 app.conf(server_name: _)보다 그쪽과 먼저 매칭되어
# 버려진다 (nginx는 파일 순서보다 정확한 server_name 일치를 우선한다).
RUN rm -f /etc/nginx/conf.d/*.conf
COPY conf.d/ /etc/nginx/conf.d/

HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD wget -qO- http://localhost/healthz || exit 1

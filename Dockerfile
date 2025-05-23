# установка зависимостей vue js
FROM node:18-alpine AS dependencies

WORKDIR /app
COPY src/static/app/package.json .
COPY src/static/app/vite.config.js .

RUN npm install \
    && npm update \
    && npm install pinia@latest \
    && npm install pinia-plugin-persistedstate \
    && npm install marked

# Сбока приложения
FROM node:18-alpine AS builder
WORKDIR /app

COPY . .
COPY --from=dependencies /node_modules /app/src/static/app/

RUN /app/src/static/app/ \
    && npm run build \
    &&  rm -rf node_modules

FROM alpine:latest as production
LABEL maintainer="dselen@nerthus.nl"

# Устанавливаем все зависимости за один RUN
RUN apk update && apk add --no-cache \
    bash curl wget unzip sudo tzdata \
    wireguard-tools python3 py3-psutil py3-bcrypt openresolv \
    iproute2 iptables ip6tables openrc procps git \
 && wget -q -O /tmp/awg-tools.zip $(curl -s https://api.github.com/repos/amnezia-vpn/amneziawg-tools/releases/latest | grep -o 'https.*alpine-3.19-amneziawg-tools.zip') \
 && unzip -j /tmp/awg-tools.zip -d /usr/bin/ \
 && chmod +x /usr/bin/awg /usr/bin/awg-quick \
 && rm /tmp/awg-tools.zip \
 && apk del git

ENV TZ="Europe/Amsterdam" \
    global_dns="9.9.9.9" \
    wgd_port="10086" \
    public_ip="" \
    WGDASH=/opt/wgdashboard \
    hello='wprld'

# Создаем необходимые директории
RUN mkdir -p /data /configs ${WGDASH}/src /etc/amnezia/amneziawg

# Копируем файлы
COPY --from=builder /app/src ${WGDASH}/src
COPY entrypoint.sh /entrypoint.sh

# Настройки здоровья и портов
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep -a gunicorn || exit 1

EXPOSE 10086
WORKDIR ${WGDASH}

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]

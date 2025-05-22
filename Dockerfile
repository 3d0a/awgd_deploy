# STAGE 1: Установка зависимостей
FROM node:18-alpine AS dependencies

WORKDIR /
# Копируем только package.json сначала для лучшего кэширования
COPY src/static/app/package*.json ./src/static/app/
COPY src/static/app/vite.config.js ./src/static/app/
COPY src/static/app/proxy.js ./src/static/app/  
COPY src/static/app/package.json ./src/static/app/  
# Устанавливаем зависимости в правильной директории
RUN cd src/static/app && \
    npm install && \
    npm update && \
    npm install pinia@latest pinia-plugin-persistedstate marked

# STAGE 2: Сборка приложения
FROM node:18-alpine AS builder
WORKDIR /app

# Копируем исходный код
COPY src ./src
# Копируем node_modules из предыдущей стадии
COPY --from=dependencies /src/static/app/node_modules ./src/static/app/node_modules

# Собираем приложение
RUN cd src/static/app && \
    npm run build

# STAGE 3: Production образ
FROM alpine:latest as production
LABEL maintainer="dselen@nerthus.nl"

# Устанавливаем зависимости за один RUN
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
    WGDASH=/opt/wgdashboard

# Создаем необходимые директории
RUN mkdir -p /data /configs ${WGDASH}/src /etc/amnezia/amneziawg

# Копируем только собранные файлы из стадии builder
COPY --from=builder /app/src/static/app/dist ${WGDASH}/src
COPY ./entrypoint.sh /entrypoint.sh

# Настройки здоровья и портов
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep -a gunicorn || exit 1

EXPOSE 10086
WORKDIR ${WGDASH}

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]

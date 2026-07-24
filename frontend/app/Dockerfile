# Stage 1: Build the Flutter web application
FROM debian:bookworm-slim AS build

ARG FLUTTER_VERSION=3.38.3

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates git unzip xz-utils zip libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    | tar -xJ -C /usr/local/ \
    && git config --global --add safe.directory /usr/local/flutter

ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN flutter precache --web --no-android --no-ios --no-linux --no-macos --no-windows --no-fuchsia

WORKDIR /app

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:stable-alpine

RUN apk add --no-cache curl

# index.html, o service worker e main.dart.js não têm hash no nome do
# arquivo (diferente do conteúdo de /assets/) — sem no-cache aqui, o
# navegador pode nunca buscar um build novo após o deploy, mesmo com
# reload manual (o Service Worker do Flutter intercepta antes do HTTP).
RUN echo 'server { \
    listen 80; \
    location / { \
        root /usr/share/nginx/html; \
        try_files $uri $uri/ /index.html; \
    } \
    location ~* ^/(index\.html|flutter_bootstrap\.js|flutter_service_worker\.js|version\.json|main\.dart\.js)$ { \
        root /usr/share/nginx/html; \
        add_header Cache-Control "no-cache, no-store, must-revalidate"; \
    } \
}' > /etc/nginx/conf.d/default.conf

COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

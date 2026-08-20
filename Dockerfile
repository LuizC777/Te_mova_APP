FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter config --enable-web

# Render injeta env vars também como build args.
ARG API_BASE=http://127.0.0.1:8000
ARG APP_BASE=http://127.0.0.1:5050

RUN flutter build web --release \
    --dart-define=API_BASE=${API_BASE} \
    --dart-define=APP_BASE=${APP_BASE}

FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["/bin/sh", "-c", "sed -i \"s/listen 80;/listen ${PORT:-80};/\" /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]

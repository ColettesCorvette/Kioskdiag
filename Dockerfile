# syntax=docker/dockerfile:1
#
# Construit le bundle flutter-pi pour la carte RK3568  
#
# Build + extraction du bundle dans ./dist :
#   docker build --target export --output type=local,dest=dist .
# Puis copier dist/ sur la carte cf. README section « Déployer et lancer ».

# ============================ Build ============================
FROM ubuntu:24.04 AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip xz-utils zip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# flutter-pi suit un moteur publié pour une version précise de Flutter.
# 3.41.7 au moment du dev 
# >=3.44 n'ont pas encore de moteur.
ARG FLUTTER_VERSION=3.41.7
RUN git clone --depth 1 -b "${FLUTTER_VERSION}" \
    https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:/root/.pub-cache/bin:${PATH}"
RUN git config --global --add safe.directory /opt/flutter \
    && flutter --version \
    && dart pub global activate flutterpi_tool

WORKDIR /app

# Dépendances d'abord, pour les mettre en cache.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Le reste du code, puis build du bundle arm64.
COPY . .
RUN flutterpi_tool build --arch arm64 --cpu generic --release

# ============================ Export ============================
# Image vide ne contenant que le bundle, extrait sur l'hôte avec
# `docker build --target export --output type=local,dest=dist .`.
FROM scratch AS export
COPY --from=builder /app/build/flutter-pi/aarch64-generic/ /

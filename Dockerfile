# ---- ETAPA 1: Construcción ----
FROM haskell:9.10.3 AS builder

WORKDIR /build

# Copiamos solo los archivos de configuración primero para cachear las dependencias
COPY stack.yaml package.yaml ./*.cabal ./
RUN stack build --system-ghc --only-dependencies

# Copiamos el resto del código y compilamos
COPY . .
RUN stack build --system-ghc --copy-bins

# ---- ETAPA 2: Imagen final ----
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y libsqlite3-0 ca-certificates && rm -rf /var/lib/apt/lists/*

# Copiamos el binario desde la etapa builder
COPY --from=builder /root/.local/bin/personal-page-exe /usr/local/bin/personal-page

# Copiamos la carpeta static
COPY static /usr/local/share/personal-page/static

EXPOSE 8080
ENV STATIC_DIR=/usr/local/share/personal-page/static
CMD ["personal-page"]

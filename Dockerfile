# ---- ETAPA 1: Construcción ----
FROM haskell:9.10.3 AS builder

WORKDIR /build

# Copiamos solo los archivos de configuración primero para cachear las dependencias
COPY stack.yaml package.yaml *.cabal ./
RUN stack build --system-ghc --only-dependencies

# Copiamos el resto del código y compilamos
COPY . .
RUN stack build --system-ghc --copy-bins

# ---- ETAPA 2: Imágen final (pequeña) ----
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y libsqlite3-0 ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /root/.local/bin/personal-page-exe /usr/local/bin/personal-page

EXPOSE 8080

CMD ["personal-page"]
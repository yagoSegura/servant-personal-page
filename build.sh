#!/bin/bash

echo "=== 1. Compilando Frontend (Elm) ==="
cd frontend
elm make src/Main.elm --output=../static/index.html --optimize
cd ..

echo "=== 2. (Opcional) Generar tipos de Elm desde Haskell ==="
stack run generate-elm

echo "=== 3. Construyendo Backend (Haskell) ==="
stack build

echo "=== 4. ¡Build completado! Ejecuta: stack run ==="

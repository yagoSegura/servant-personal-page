#!/bin/bash
cd frontend
elm make src/Main.elm --output=../static/index.html --optimize
echo "Frontend compilado y movido a static/"

#!/bin/bash

# Script para generar la versión MSDOS de FALSEDL.PRG
# Copia FALSEDL.PRG a FALSEM2.PRG y lo convierte a CP437

echo "Generando versión MSDOS..."

# Copiar el archivo
cp FALSEDL.PRG FALSEM2.PRG

# Convertir a CP437
iconv -f utf-8 -t cp437 -c FALSEM2.PRG > temp && mv temp FALSEM2.PRG

echo "Versión MSDOS generada: FALSEM2.PRG"
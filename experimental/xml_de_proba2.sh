#!/bin/bash

# Definim fișierele implicite
INPUT_FILE="input_plante.xml"
OUTPUT_FILE="output_plante.xml"

# Inițializăm fișierul de ieșire cu începutul structurii XML

# Verificăm existența fișierului de intrare
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Fișierul de intrare $INPUT_FILE nu există!"
    exit 1
fi

# Procesăm fișierul XML linie cu linie
while read -r line; do
    # Dacă linia conține un tag complet, îl procesăm
    if echo "$line" | grep -q '<[^>]*>[^<]*<\/[^>]*>'; then
        # Extragem numele tag-ului
        tag=$(echo "$line" | sed -n 's/.*<\([^\/>][^>]*\)>.*<\/\1>.*/\1/p')
        # Extragem conținutul tag-ului
        content=$(echo "$line" | sed -n 's/.*<[^>]*>\(.*\)<\/[^>]*>/\1/p')
        # Afișăm conținutul în consolă
        echo "Conținutul tag-ului <$tag> este: $content"
        # Scriem tag-ul și conținutul său în fișierul de ieșire
        echo "    <$tag>$content</$tag>" >> "$OUTPUT_FILE"
	# \n
    fi
done < "$INPUT_FILE"

# Închidem structura XML în fișierul de ieșire

# Mesaj de finalizare
echo "Fișierul XML procesat a fost scris în $OUTPUT_FILE."

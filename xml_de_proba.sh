#!/bin/bash

INPUT_FILE="input_studenti.xml"
OUTPUT_FILE="output_studenti.xml"

#verificam fis de intrare
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Fișierul de intrare $INPUT_FILE nu există!"
    exit 1
fi

#extragem nume studenti
echo "Studenți existenți:"
grep "<name>" "$INPUT_FILE" | sed 's/<[^>]*>//g' | sed 's/^[[:space:]]*//'

#construim inca un student
NEW_NAME="Alice Johnson"
NEW_AGE="20"
NEW_GRADE="A+"

NEW_STUDENT="    <student>
        <name>$NEW_NAME</name>
        <age>$NEW_AGE</age>
        <grade>$NEW_GRADE</grade>
    </student>"

#adaugam student
awk -v new_student="$NEW_STUDENT" '
/<\/students>/ {
    print new_student
}
{ print }
' "$INPUT_FILE" > "$OUTPUT_FILE"

echo "Noul fișier XML a fost scris în $OUTPUT_FILE:"
cat "$OUTPUT_FILE"

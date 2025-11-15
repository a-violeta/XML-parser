# Script shell parsare fisiere xml
Citește și scrie date din, respectiv, în format `xml`. Este limitat la fisiere xml mai simpliste, un input complex poate genera rezultate eronate.

## Instalare
```bash
git clone https://github.com/a-violeta/XML-parser.git
cd XML-parser
chmod +x citire.sh #daca e nevoie de setare permisiuni de executare
chmod +x scriere.sh
```

## Utilizare
Creați un fisier xml, mai jos am folosit fisierul `input.xml`. Scriptul se rulează din terminal și primește fișierul creat.
### Exemple
```bash
./citire.sh input.xml
./scriere.sh input.xml
```

## Funcționalități
- **citire.sh**
  - Validează input-ul XML
  - Afișeaza pe ecran conținutul fiecărui tag
  - Precizează dacă conținutul unui tag este un `string`, un `obiect de tipul unui tag` sau un `vector de obiecte`
- **scriere.sh**
  - Inserează în document un tag citit de la tastatură
  - Tag-ul citit de la tastatură este căutat în fișierul dat
  - Tag-ul citit de la tastatură este *dublat* în fișier, dar continutul tag-urilor ce aveau `string`-uri este modificat.

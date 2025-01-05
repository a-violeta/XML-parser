#!/bin/bash

# Funcție pentru verificarea validității unui fișier XML
check_xml_validity() {
    file=$1
    stack=()  # Array pentru a ține evidența tag-urilor deschise
    ok="1"
    # Citim fișierul linie cu linie
    while IFS= read -r line; do
        # Căutăm tag-urile deschise și închise în fiecare linie
        while [[ $line =~ <([^/][^>]*)> ]]; do
            tag="${BASH_REMATCH[1]}"  # Extragem tag-ul
            line="${line/${BASH_REMATCH[0]}/}"  # Eliminăm tag-ul procesat din linie

            # Verificăm dacă este un tag de deschidere
            if [[ ! "$tag" =~ ^/ ]]; then
                # Adăugăm tag-ul în stack (tag deschis)
                stack+=("$tag")
	    else
		#daca tag ul de inchidere gasit este identic ultimului tag din stack => il sterg din stack
		tag_pereche=$(echo "$tag" | sed 's#</#<#')
		echo "$tag_pereche"

		last_element="${stack[-1]}" #bash versiunea 4.2
		if [[ "$tag_pereche" == "$last_element" ]]; then
		   unset 'stack[-1]'  # În Bash modern
		   #sau poate stack-=("$tag_pereche")
		else
		   #echo "Fisierul nu este valid!"
		   ok="0" #verificatorul
		   break
		fi
            fi #si daca nu e tag, e continut ce ii face?
        done
    done < "$file"

    # Dacă la final stack-ul nu este gol, înseamnă că există tag-uri deschise neînchise
    if [ ${#stack[@]} -ne 0 ] || [ ok == 0 ]; then
        echo "Fișierul XML nu este valid: există tag-uri deschise neînchise."
        return 1
    fi

    # Dacă toate tag-urile sunt corect închise și imbricate, fișierul este valid
    echo "Fișierul XML este valid."
    return 0
}

#de aici am parsarea

# Funcție pentru procesarea unui obiect XML (tag care conține câmpuri și valori)
process_object() {
    tag=$1
    # Căutăm câmpurile și valorile asociate tag-ului (presupunând că tag-urile sunt simple)
    echo "tag-ul <$tag> este un obiect de tip <$tag> ce conține câmpurile și valorile:"

    # Folosim xmllint pentru a obține toate câmpurile pentru tag-ul curent
    xmllint --xpath "//$tag/*" $file | sed -n 's/<\([^>]*\)>/\1/p' | while read field; do
        value=$(xmllint --xpath "string(//$tag/$field)" $file)
        echo "  $field: $value"
    done
}

# Funcție pentru procesarea unui array de tag-uri XML
process_array() {
    parent_tag=$1
    nested_tag=$2
    echo "tag-ul <$parent_tag> conține un array de tipul <$nested_tag>"

    # Folosim xmllint pentru a parcurge toate elementele din array
    items=$(xmllint --xpath "//$parent_tag/$nested_tag" $file | sed -n 's/<\([^>]*\)>/\1/p')

    # Procesăm fiecare element din array ca un obiect
    for item in $items; do
        echo "Procesăm elementul din array: <$nested_tag> cu valoarea: $item"
        process_object $nested_tag
    done
}

# Funcție principală pentru parsarea fișierului XML
parse_xml() {
    file=$1
    # Extragem toate tag-urile unice din fișierul XML
    tags=$(xmllint --xpath "//*[not(*)]" $file | sed -n 's/<\([^>]*\)>/\1/p' | sort | uniq)

    # Adăugăm tag-ul root pentru a fi procesat
    root_tag=$(xmllint --xpath "/*" $file | sed -n 's/<\([^>]*\)>/\1/p')
    if [ ! -z "$root_tag" ]; then
        tags="$root_tag $tags"
    fi

    # Procesăm tag-ul root cu un mesaj special
    if [ "$root_tag" ]; then
        echo "tag-ul <$root_tag> este tag-ul principal ce conține:"
    fi

    # Pentru fiecare tag, verificăm dacă este un array sau un obiect
    for tag in $tags; do
        # Verificăm dacă există un tag imediat următor de același tip (array)
        next_tag=$(xmllint --xpath "//$tag[2]" $file | sed -n 's/<\([^>]*\)>/\1/p')

        if [ "$next_tag" == "$tag" ]; then
            # Dacă există un alt tag de același tip, procesăm ca array
            nested_tag=$tag
            process_array $tag $nested_tag
        else
            # Dacă nu există un alt tag, procesăm ca obiect
            process_object $tag
        fi
    done
}

#de aici urmeaza main practic

# Verificăm dacă fișierul a fost transmis ca argument
if [ $# -eq 0 ]; then
    echo "Vă rugăm să specificați un fișier XML."
    exit 1
fi

file=$1

# Apelăm funcția pentru a verifica fișierul XML
check_xml_validity $1
if [ ok -eq 0 ]; then
   echo "iesire."
   exit 1
fi
# Apelăm funcția principală pentru parsarea fișierului
parse_xml $1

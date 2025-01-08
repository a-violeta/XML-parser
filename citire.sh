#!/bin/bash

# Funcție pentru verificarea validității unui fișier XML
check_xml_validity() {

    local file="$1"	#$1 este primul parametru dat functiei, adica fisierul pe care l am redenumit file
    stack=()  		# Array pentru a ține evidența tag-urilor, e rezolvarea problemei parantezarii
    ok=1

    # Citim fișierul linie cu linie
    while IFS= read -r line; do
        # Căutăm tag-urile deschise și închise în fiecare linie
        while [[ $line =~ (<[^>]+>) ]]; do	#cat timp avem tag in line
            tag="${BASH_REMATCH[1]}"  # Extragem tag-ul
            line="${line/${BASH_REMATCH[0]}/}"  # Eliminăm tag-ul procesat din linie
            # Verificăm dacă este un tag de deschidere prin verificarea lipsei semnului "/"
            if [[ ! "$tag" =~ "/" ]]; then
                # Adăugăm tag-ul în stack (doar tag urile deschise)
                stack+=("$tag")
												#for el in "${stack[@]}"; do #for range based sau cum se numea, am verificat ce am in vector la fiecare pas
												#echo "$el"
												#done
												#echo -e "\n"
	    else #clar am gasit un tag de inchidere
		#daca tag ul de inchidere gasit este identic ultimului tag din stack => il sterg din stack
		tag_pereche=$(echo "$tag" | sed 's#</#<#')
		last_element="${stack[-1]}" #bash versiunea 4.2
		if [[ "$tag_pereche" == "$last_element" ]]; then
		   unset 'stack[-1]'  # În Bash modern
		else
		   ok=0 #verificatorul
#echo "AICI: $tag"
		   break
		fi
            fi
        done
    done < "$file"

    # Dacă la final stack-ul nu este gol, înseamnă că există tag-uri deschise neînchise
    if [ ${#stack[@]} -ne 0 ] || [ "$ok" == 0 ]; then
        echo "Fișierul XML nu este valid."
#echo "$ok"
        return 1
    fi

#POT AVEA TAG URI GOALE? ALTFEL INCA O PARCURGERE CU CAUTARE "><"

    # Dacă toate tag-urile sunt corect închise și imbricate, fișierul este valid
    echo "Fișierul XML este valid."
    return 0
}

#de aici am parsarea

parse_xml() {
    #local file="$1"
    root=0 #variabila booleana ca sa stiu daca linia e root
    vector=() #vector cu toate tag urile
    repetitive_tags=() #vector pt tag urile care se repeta, adica sunt elemente intr un vector
    found=0 #o variabila booleana

    mapfile -t lines < "$1" #iterez prin liniile documentului de mai multe ori asa ca fac vector din linii ca sa le pot parcurge de cate ori vreau

    for line in "${lines[@]}"; do
#echo "procesam linia: $line"
	if [[ $line =~ (<[^>]+>) ]]; then #if linia are tag
	    tag="${BASH_REMATCH[1]}" #iau tag ul
	    line="${line/${BASH_REMATCH[0]}/}" #din linie elimin portiunea cu tag ul
#echo "tag ul gasit este: $tag"
	    vector+=("$tag") #adaug tag ul in vectorul de tag uri
	    if [[ $line =~ (<[^>]+>) ]]; then #cam prostesc, dar daca mai am tag uri pe linie si vreau sa le adaug am pus doar if, while era mai bun. dar noi avem in general maxim 2 tag uri pe linie
		tag="${BASH_REMATCH[1]}"
		vector+=("$tag")
	    fi
	fi
    done

    for ((i=0; i<${#vector[@]}-1; i++)); do #iterez prin vectorul de tag uri
#echo "$el"
#aici verific ce elemente sunt vectori si le pun in... ceva doar cu elem unice.
	current=${vector[$i]}
	next=${vector[$i+1]}
	#pun in 'next' caracterul "/", daca e deja nu mi pasa, doar verific daca sunt identice, primul inchis, al doilea deachis
	closing_next="</${next#<}"
	if [ "$current" == "$closing_next"  ]; then
	    repetitive_tags+=("$next")
	fi
    done
#echo -e "\n"
#for el in "${repetitive_tags[@]}"; do
#echo "$el"
#done
echo -e "\n"
echo "primul el din vector: ${repetitive_tags[0]}" #verificam cum se lucreaza cu vectori

    for line in "${lines[@]}"; do
	if [[ $line =~ (<[^>]+>) ]]; then                               #mereu true, liniile contin tag uri
        tag="${BASH_REMATCH[1]}"
	fi

	if [[ "$root" == 0 ]]; then
	    echo "avem root de tip $tag ce contine:"
	    root=1
	else
#echo "procesam linia: $line"
	    count=$(echo "$line" | grep -o "<" | wc -l)
#echo "count: $count"
	    content=$(echo "$line" | sed -n 's/.*>\(.*\)<.*/\1/p')
	    if [[ "$count" == 2 ]]; then
		echo "tag ul $tag ce contine '$content'"
	    else
		if [[ ! "$tag" =~ "/" ]]; then				#tag deschidere si unic pe linie
#		    (i++)						#stim poz lui in vector
		    echo -e "\n"
echo "$tag"									#if tag in repetitive_tags, echo "avem vector"
		    found=0
		    for ((i=0; i<${#repetitive_tags[@]}-1; i++)); do
echo "avem $tag si il comparam cu ${repetitive_tags[$i]}"
			if [ "${repetitive_tags[$i]}" == "$tag" ]; then
			    unset 'repetitive_tags[$i]'
			    found=1
			    break
			fi
		    done
		    if [ "$found" == 1 ]; then
			echo "avem un vector de elemente de tip $tag:"
		    fi
			echo "avem obiectul de tip $tag ce contine mai departe:"
#retine in vector toate tag urile de deschidere, eventual doar pe alea fara content, cu root?
#if v[i+1]==v[i+2] avem array, else obiect. dar vectorul nu stie imbricarile mai complexe.
#poti avea dezordine: people: students and workers mixed? nu
#obiect in obiect? se poate, iar asa se strica conditia, arbore. sau facem vectorul de la 0 ca sa ia strict ...
#SAU CAUT </tag><tag> IN VECTOR CU TOATE TAG URILE, retin in alt vect tag urile astea si cand le gasesc afisez mesaj
#pot cauta secventa </tag><tag> si intr o variabila text cu tot documentul fara whitespaces
		fi
	    fi
	fi
    done

#    file=$1
    # Extragem toate tag-urile unice din fișierul XML
#    tags=$(xmllint --xpath "//*[not(*)]" $file | sed -n 's/<\([^>]*\)>/\1/p' | sort | uniq)

    # Adăugăm tag-ul root pentru a fi procesat
#    root_tag=$(xmllint --xpath "/*" $file | sed -n 's/<\([^>]*\)>/\1/p')
#    if [ ! -z "$root_tag" ]; then
#        tags="$root_tag $tags"
#    fi

    # Procesăm tag-ul root cu un mesaj special
#    if [ "$root_tag" ]; then
#        echo "tag-ul <$root_tag> este tag-ul principal ce conține:"
#    fi

    # Pentru fiecare tag, verificăm dacă este un array sau un obiect
#    for tag in $tags; do
        # Verificăm dacă există un tag imediat următor de același tip (array)
#        next_tag=$(xmllint --xpath "//$tag[2]" $file | sed -n 's/<\([^>]*\)>/\1/p')

#        if [ "$next_tag" == "$tag" ]; then
            # Dacă există un alt tag de același tip, procesăm ca array
#            nested_tag=$tag
#            process_array $tag $nested_tag
#        else
            # Dacă nu există un alt tag, procesăm ca obiect
#            process_object $tag
#        fi
#    done
}

#de aici urmeaza main practic

# Verificăm dacă fișierul a fost transmis ca argument
if [ $# -eq 0 ]; then
    echo "Vă rugăm să specificați un fișier XML."
    exit 1
fi
# Apelăm funcția pentru a verifica fișierul XML
check_xml_validity "$1"
if [ "$ok" == 0 ]; then
   echo "iesire."
   exit 1
fi
# Apelăm funcția principală pentru parsarea fișierului
parse_xml "$1"

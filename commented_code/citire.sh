#!/bin/bash

# Funcție pentru verificarea validității unui fișier XML
#validarea e practic verificarea imbricarii, ca ultimul tag deschis e primul inchis
check_xml_validity() {

    local file="$1"	#$1 este primul parametru dat functiei, se cheama argument si il ia din apelul functiei acre e la sfarsitul codului
    stack=()  		# Array pentru a ține evidența tag-urilor, e rezolvarea problemei parantezarii
    ok=1		#variabila booleana, verifica daca nu e buna imbricarea

    # Citim fișierul linie cu linie
    while IFS= read -r line; do
        # Căutăm tag-urile deschise și închise din fiecare linie
        while [[ $line =~ (<[^>]+>) ]]; do	#cat timp avem tag in line
            tag="${BASH_REMATCH[1]}"  # Extragem tag-ul
            line="${line/${BASH_REMATCH[0]}/}"  # Eliminăm tag-ul procesat din linie
            # Verificăm dacă este un tag de deschidere prin verificarea lipsei semnului "/" in tag
            if [[ ! "$tag" =~ "/" ]]; then
                # Adăugăm tag-ul în stack (doar tag urile deschise)
                stack+=("$tag")
												#for el in "${stack[@]}"; do #am verificat ce am in vector la fiecare pas la debugging
												#echo "$el"
												#done
												#echo -e "\n"
	    else 			#clar am gasit un tag de inchidere
					#daca tag ul de inchidere gasit este identic ultimului tag din stack => il sterg din stack
		tag_pereche=$(echo "$tag" | sed 's#</#<#')	#in tag am un tag de inchidere, in stack am doar tag uri de deschidere, trebuie sa le compar asa ca fac tag_pereche care e tag ul de deschidere pt tag
		last_element="${stack[-1]}"
		if [[ "$tag_pereche" == "$last_element" ]]; then
		   unset 'stack[-1]'				#sterg ultimul elem din stack
		else
		   ok=0						#verificatorul de imbricare corecta, cred ca e inutil, oricum verific la final daca stack e gol sau nu
#echo "AICI: $tag"
		   break
		fi
            fi
        done
    done < "$file"

    # Dacă la final stack-ul nu este gol sau ok e 0, înseamnă că există tag-uri deschise neînchise
    if [ ${#stack[@]} -ne 0 ] || [ "$ok" == 0 ]; then
        echo "Fișierul XML nu este valid."
        return 1
    fi

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
#retine in vector toate tag urile de deschidere, eventual doar pe alea fara content, si cu root deocamdata
#if v[i+1]==v[i+2] avem array, else obiect. dar vectorul asta nu stie imbricarile mai complexe.
#obiect in obiect? se poate, iar asa se strica conditia, arbore. sau refacem vectorul de fiecare data cand gasim tag
#SAU CAUT </tag><tag> IN VECTOR CU TOATE TAG URILE, retin in alt vect tag urile astea si cand le gasesc afisez mesaj
#pot cauta secventa </tag><tag> si intr o variabila text cu tot documentul fara whitespaces

#pot sa caut in vectorul lines direct. modificari necesare
		fi
	    fi
	fi
    done

#de aici urmeaza main practic

# Verificăm dacă fișierul a fost transmis ca argument
if [ $# -eq 0 ]; then
    echo "Vă rugăm să specificați un fișier XML."
    exit 1
fi
# Apelăm funcția pentru validare
check_xml_validity "$1"
if [ "$ok" == 0 ]; then
   echo "iesire."
   exit 1
fi
# Apelăm funcția principală pentru parsarea fișierului
parse_xml "$1"

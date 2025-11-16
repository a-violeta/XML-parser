#!/bin/bash

check_xml_validity() {

    local file="$1"
    stack=()
    ok=1

    while IFS= read -r line; do

        while [[ $line =~ (<[^>]+>) ]]; do
            tag="${BASH_REMATCH[1]}"
            line="${line/${BASH_REMATCH[0]}/}"

            if [[ ! "$tag" =~ "/" ]]; then
                stack+=("$tag")

	    else
		tag_pereche=$(echo "$tag" | sed 's#</#<#')
		last_element="${stack[-1]}"
		if [[ "$tag_pereche" == "$last_element" ]]; then
		   unset 'stack[-1]'
		else
		   ok=0
		   break
		fi
            fi
        done
    done < "$file"

    if [ ${#stack[@]} -ne 0 ] || [ "$ok" == 0 ]; then
        echo "Fișierul XML nu este valid."
        return 1
    fi

    echo "Fișierul XML este valid."
    return 0
}


parse_xml() {

    is_root=0
    vector=()
    repetitive_tags=()
    found=0
    root=' '

    mapfile -t lines < "$1"

    for line in "${lines[@]}"; do

	if [[ $line =~ (<[^>]+>) ]]; then
	    tag="${BASH_REMATCH[1]}"
	    line="${line/${BASH_REMATCH[0]}/}"
	    vector+=("$tag")

	    if [[ $line =~ (<[^>]+>) ]]; then
		tag="${BASH_REMATCH[1]}"
		vector+=("$tag")
	    fi
	fi
    done

    for ((i=0; i<${#vector[@]}-1; i++)); do
	current=${vector[$i]}
	next=${vector[$i+1]}
	closing_next="</${next#<}"

	found=0

	if [[ ${#repetitive_tags[@]} -ne 0 ]]; then
            for ((j=0; j<${#repetitive_tags[@]}; j++)); do
        	if [ "${repetitive_tags[$j]}" == "$next" ]; then
            	found=1
            	break
            	fi
            done
	fi


	if [[ "$current" == "$closing_next" && "$found" == 0 ]]; then
	    repetitive_tags+=("$next")
	fi
    done

    for line in "${lines[@]}"; do
	if [[ $line =~ (<[^>]+>) ]]; then
        tag="${BASH_REMATCH[1]}"
	fi

	if [[ "$is_root" == 0 ]]; then
	    echo "Avem un root de tip $tag ce contine:"
	    root="</${tag#<}"
	    is_root=1

	else
	    count=$(echo "$line" | grep -o "<" | wc -l)
	    content=$(echo "$line" | sed -n 's/.*>\(.*\)<.*/\1/p')
	    if [[ "$count" == 2 ]]; then
		echo "Tag-ul $tag ce contine '$content'"
	    else
		if [[ ! "$tag" =~ "/" ]]; then #tag deschidere, unic pe linie
		    echo -e "\n"

		    if [[ ${#repetitive_tags[@]} -ne 0 ]]; then
			found=0

			for ((i=0; i<${#repetitive_tags[@]}; i++)); do
			    if [ "${repetitive_tags[$i]}" == "$tag" ]; then
				unset 'repetitive_tags[$i]'
				found=1
				break
			    fi
			done

			if [ "$found" == 1 ]; then
			    echo "Avem un vector de elemente de tip $tag:"
			    echo -e "\n"
			fi
		    fi
			echo "Avem obiectul de tip $tag ce contine:"

		else
		    if [[ ! "$root" == "$tag" ]]; then
			tag=$(echo "$tag" | sed 's#</#<#')
			echo "Aici se termina obiectul de tip $tag"
		    fi
		fi
	    fi
	fi
    done
    return 0
}

if [ $# -eq 0 ]; then
    echo "Va rugam sa specificati un fisier XML."
    exit 1
fi

check_xml_validity "$1"
if [ "$ok" == 0 ]; then
   echo "Iesire."
   exit 1
fi
echo -e "\n"

parse_xml "$1"

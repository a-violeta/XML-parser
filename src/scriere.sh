#!/bin/bash

scriere() {
   if [[ ! -f "$1" ]]; then
      echo "Fisierul nu exista."
      return 1
   fi

   echo "Introduceti numele tag-ului pe care doriti sa-l adaugati: "
   read tag_adaugat
   noul_text=$'\n'
   i=0
   adaugare=-1
   root=1
   verificare=0
   newline=$'\n'

   tag_adaugat_pereche="</${tag_adaugat#<}"

   mapfile -t lines < "$1"

   for line in "${lines[@]}"; do

      count=$(echo "$line" | grep -o "<" | wc -l)

      if [[ "$adaugare" == 0 ]]; then
        if [[ $line =~ (<[^>]+>) ]]; then
	   tag="${BASH_REMATCH[1]}"
        fi
	line2="${line/${BASH_REMATCH[0]}/}"
	line2=$(echo "$line2" | tr -d '[:space:]')

	if [ -n "$line2" ]; then
	   line=$(echo "$line" | sed 's/>\(.*\)/>/')
	   noul_text="$noul_text$line"
	   ((i++))
	   content="content $i"
	   noul_text="$noul_text$content"
	   tag_inchidere="</${tag#<}"
	   noul_text="$noul_text$tag_inchidere"
	   noul_text="$noul_text$newline"
	else
	   noul_text="$noul_text$line"
	   noul_text="$noul_text$newline"
	fi

	if [[ "$tag" =~ "/" ]]; then
	   if [[ "$tag" == "$tag_adaugat_pereche" ]]; then
	      adaugare=1
	      break
	   fi
	fi
      else
	if [[ "$adaugare" == -1 ]]; then
	   if [[ $line == *$tag_adaugat* ]]; then
	      adaugare=0
	      if [[ "$root" == 1 || "$count" == 2 ]]; then
	        root=0
	        noul_text=-1
	        adaugare_finalizata=1
		verificare=-1
		break
	      else
	        noul_text="$noul_text$line"
		noul_text="$noul_text$newline"
		verificare=1
	      fi
           fi
	else
	   break
	fi
      fi
      if [[ "$root" == 1 ]]; then
	root=0
      fi
   done

   if [[ "$verificare" -eq 0 ]]; then
      echo "Tag-ul nu a fost gasit in document!"
      return 1
   fi

   if [ "$verificare" == "-1" ]; then
     echo "Tag-ul nu este corespunzator!"
      return 1
   fi

   echo "Vom adauga documentului $1 portiunea: $noul_text"
   verificare=1
   > output.xml

   for line in "${lines[@]}"; do
      echo "$line" >> output.xml
      count=$(echo "$line" | grep -o "<" | wc -l)
      if [[ $line =~ (<[^>]+>) && "$count" == 1 ]]; then
	tag="${BASH_REMATCH[1]}"
	if [[ "$tag" == "$tag_adaugat_pereche" && "$verificare" == 1 ]]; then
	   echo "$noul_text" >> output.xml
	   verificare=0
	fi
      fi
   done

   return 0
}

scriere "$1"

#!/bin/bash

scriere() {
   if [[ ! -f "$1" ]]; then
      echo "Fisierul nu exista"
      return 1
   fi

   #citire tag_adaugat
   echo "introduceti numele tagului pe care doriti sa l adaugati: "
   #aici daca introduci faca <> nu l gaseste,
   #daca introduci tag de inchidere o sa copieze continutul fisierului pana gaseste <//tag> ceea ce e imposibil
   #nu are sens sa se introduca un tag ce contine doar content, xml nu prea dupleaza tag uri imbricate, daca exista cazuri in care are sens nu le am vazut
   #root este unic
   read tag_adaugat
   noul_text=$'\n'
   i=0
   adaugare=-1						#-1 pt neinceput, 0 pt procesare, 1 pt finalizat
   root=1
   verificare=0
   newline=$'\n'

   tag_adaugat_pereche="</${tag_adaugat#<}"		#vrem sa adaugam noul text imediat dupa tag ul original
#   echo "tag ul de inchidere al tag ului furnizat este: $tag_adaugat_pereche"

   mapfile -t lines < "$1"				#trebuie sa parcurg documentul de 2 ori deci fac vector din liniile sale

   #caut tag_adaugat
   for line in "${lines[@]}"; do

      count=$(echo "$line" | grep -o "<" | wc -l)

      if [[ "$adaugare" == 0 ]]; then					#creez tag ul
        if [[ $line =~ (<[^>]+>) ]]; then				#mereu true, liniile contin tag uri
	   tag="${BASH_REMATCH[1]}"
									#else avem eroare din validare
        fi
	line2="${line/${BASH_REMATCH[0]}/}" 				#e linia dar fara tag ul procesat
	line2=$(echo "$line2" | tr -d '[:space:]')			#tot linia dar si fara spatii

	if [ -n "$line2" ]; then					#if linia are continut, a ramas cu el
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
	   tag_pereche="$tag"
	else
	   tag_pereche="</${tag#<}"
	fi

	if [[ "$tag_pereche" == "$tag_adaugat_pereche" ]]; then
	   adaugare=1
	   break
	fi
      else								#nu adaugam acum
	if [[ "$adaugare" == -1 ]]; then
	   if [[ $line == *$tag_adaugat* ]]; then			#am gasit tag ul
	      adaugare=0
	      if [[ "$root" == 1 || "$count" == 2 ]]; then		#nu e bun daca e root sau tag cu content
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
      echo "tag ul nu a fost gasit!"
      return 1
   fi

   if [ "$verificare" == "-1" ]; then
     echo "tag ul nu este corespunzator!"
      return 1
   fi

#   echo -e "\n"
   echo "vom adauga documentului portiunea: $noul_text"
   verificare=1
   > output.xml									#sterg continutul fis pt ca in el pun outputul de fiecare data cand rulez

   #citesc linie cu linie si adaug noul text la locul sau
   for line in "${lines[@]}"; do
      echo "$line" >> output.xml
      count=$(echo "$line" | grep -o "<" | wc -l)
      #if [[ "$line" =~ "/" && "$count" == 1 ]]; then				#tag de inchidere
      if [[ $line =~ (<[^>]+>) && "$count" == 1 ]]; then
	tag="${BASH_REMATCH[1]}"
	#echo "AICI ESTE $tag"
	if [[ "$tag" == "$tag_adaugat_pereche" && "$verificare" == 1 ]]; then	#tag ul dupa care adaugam si unic
	   echo "$noul_text" >> output.xml
	   verificare=0
	fi
      fi
   done

   return 0
}
echo "$1"
scriere "$1"					#apel functie

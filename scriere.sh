#!/bin/bash

scriere(){
   echo "introduceti numele tagului pe care doriti sa l adaugati: "
   #citire tag_adaugat
   noul_text="0"

   #caut name si vad daca e tag obiect sau tag array. accept doar obiect
   while read -r line; do
      if [[ $line =~ <([^/][^>]*)> ]]; then
        tag="${BASH_REMATCH[1]}"
        if [[ "$tag" == "$tag_adaugat" ]]; then
	   #verific daca in el urmeaza un tag fara continut folosind o functie sau ceva?
    	   #bag tag ul de deschidere
    	   #while line diferita de tag ul de inchidere:
	   #in variabila noul_text introduc fiecare tag gasit
	   #si in loc de content bag text de la tastatura
	   #dupa orice tag deschis gasit verific daca urmeaza continut si daca da il inlocuiesc in var
    	   #bag tag ul de inchidere
	fi
      fi
   done

   if [ "$noul_text" == "0" ]; then
      echo "tag ul nu a fost gasit!"
      return 1
   fi

   #daca nu mi convine tag ul de adaugat pt ca e array sau ceva naspa, in var pun -1
   if [ "$noul_text" == "-1" ]; then
     echo "tag ul nu este corespunzator!"
      return 1
   fi

   #citesc linie cu linie
   while read -r line; do
      if [[ $line =~ <([^/][^>]*)> ]]; then
	tag="${BASH_REMATCH[1]}"
	if [[ "$tag" == "$tag_adaugat" ]]; then
	   #adaug in fisier noul_text
	else
	   #scrie line in noul document
	fi
      fi
   done

}

#!/bin/bash

scriere(){
   #citire tag_adaugat
   echo "introduceti numele tagului pe care doriti sa l adaugati, asigurandu va ca acesta exista deja in fisierul xml: "
   read tag_adaugat
   echo "Ati introdus: $tag_adaugat"
   noul_text=0
   i=0
   adaugare_finalizata=0

   #caut tag_adaugat
   while read line; do
      echo "linia curenta este: $line"
      if [[ $noul_text == $tag_adaugat* && "$adaugare_finalizata" -eq 0 ]]; then #stiu ca l am gasit si acum procesez b>
        if [[ $line =~ <([^/][^>]*)> ]]; then #if tag de deschidere
           tag="${BASH_REMATCH[1]}"
           echo "tag ul curent de adaugat este: $tag"
           line="${line/${BASH_REMATCH[0]}/}"  # Eliminăm tag-ul procesat din linie
           echo "linia modificata este: $line"
           noul_text="$noul_text$tag" #alipesc tag ul de deschidere
           echo "noul text este: $noul_text"
           if [ -n "$line" ]; then #if linie cu continut
              ((i++))
              content="content $i"
              noul_text="$noul_text$content" #alipesc content si tag ul de inchidere
              tag_pereche="</${tag#<}"
              echo "$tag_pereche"
              noul_text="$noul_text$tag_pereche"
           #else linia are doar tag deschidere si nu fac nimic
           fi
	else #tag de inchidere, il adaug doar
           tag="${BASH_REMATCH[1]}"
           noul_text="$noul_text$tag"
           tag_pereche=$(echo "$tag" | sed 's#</#<#')
           #echo "$tag_pereche"
           if [ "$tag_pereche" == "$tag_adaugat" ]; then
              adaugare_finalizata=1
           fi
	fi
      else
        if [[ $line =~ <([^/][^>]*)> ]]; then #if tag de deschidere
           tag="${BASH_REMATCH[1]}"
           echo "tag ul gasit este: $tag"
           if [[ "$tag" == "$tag_adaugat" ]]; then
              #verific daca in el urmeaza un tag fara continut folosind o functie sau ceva?
              noul_text="$tag_adaugat" #bag tag ul de deschidere
              #newline deasemenea
           fi
        fi
      fi
   done

   if [[ "$noul_text" -eq 0 ]]; then
      echo "tag ul nu a fost gasit!"
      return 1
   fi

   #daca nu mi convine tag ul de adaugat pt ca e array sau ceva naspa, in var pun -1
   if [ "$noul_text" == "-1" ]; then
     echo "tag ul nu este corespunzator!"
      return 1
   fi

   tag_adaugat_pereche="</${tag_adaugat#<}"
   echo "$tag_adaugat_pereche"

   #citesc linie cu linie
   while read line; do
      if [[ "$line" =~ </[^>]+> ]]; then #tag de inchidere
        tag="${BASH_REMATCH[1]}"
        if [[ "$tag" == "$tag_adaugat_pereche" ]]; then
           #adaug in fisier noul_text
        else
           #scrie line in noul document
        fi
      else
        #scrie line
      fi
   done

}

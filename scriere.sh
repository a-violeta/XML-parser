#!/bin/bash

#fac vector din liniile documentului, la prime iterare prin linii caut tag ul pe care o sa l dublez si fac o variabila ce retine noul text pe care il pun in fisierul output
#la a doua iterare scriu toate liniile in output, dar cand gasesc sfarsitul tag ului pe care l am dublat, adaug in output variabila cu noul_text apoi adaug liniile ramase tot asa ca la inceput

scriere() {
   if [[ ! -f "$1" ]]; then
      echo "Fisierul nu exista."
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
   adaugare=-1						#-1 pt neinceput, negasit, 0 pt procesare, adica se creaza variavila noul_text, 1 pt finalizat creare noul_text
   root=1
   verificare=0
   newline=$'\n'					#adaug \n cand e cazul

   tag_adaugat_pereche="</${tag_adaugat#<}"		#retin tag ul de inchidere al tag ului furnizat (din tag ul furnizat sterg "<" si adaug "</")

   mapfile -t lines < "$1"				#trebuie sa parcurg documentul de 2 ori deci fac vector din liniile sale

   #caut tag_adaugat, adica tag ul pe care il dublez
   for line in "${lines[@]}"; do

      count=$(echo "$line" | grep -o "<" | wc -l)			#in functie de nr de "<" de pe linie stim cate tag uri are, iar deobieci fisierele xml au pe linii ori cate un tag de deschidere sau inchidere sau au ambele tag uri cu content intre ele

      if [[ "$adaugare" == 0 ]]; then					#sunt in procesul de creare al tag ului dublat
        if [[ $line =~ (<[^>]+>) ]]; then				#mereu true, mergem pe ideea ca toate liniile contin tag uri, dar asa a zis chat gpt
	   tag="${BASH_REMATCH[1]}"
        fi
	line2="${line/${BASH_REMATCH[0]}/}" 				#e linia curenta, dar fara tag ul procesat
	line2=$(echo "$line2" | tr -d '[:space:]')			#tot linia curenta, dar si fara spatii

	if [ -n "$line2" ]; then					#if linia nu e goala inseamna ca mai are content si tag de inchidere
	   line=$(echo "$line" | sed 's/>\(.*\)/>/')			#iau linia originala si o tai ca sa aiba spatiile si tag ul de deschidere
	   noul_text="$noul_text$line"					#asta adaug variabilei mele, asa pastrez si tab urile daca sunt
	   ((i++))
	   content="content $i"						#noul tag adaugat poate avea drept content ceva generic gen "content 1" "content 2" sau citire de la tastatura
	   noul_text="$noul_text$content"
	   tag_inchidere="</${tag#<}"
	   noul_text="$noul_text$tag_inchidere"
	   noul_text="$noul_text$newline"				#am concatenat continutul tag ului si tag ul de inchidere si newline
	else								#else, linia are doar un tag si il adaug pe el (linia cu el pt a avea tab urile) si newline
	   noul_text="$noul_text$line"
	   noul_text="$noul_text$newline"
	fi

	if [[ "$tag" =~ "/" ]]; then					#la fiecare tag gasit fac tag ul de inchidere si verific daca e inchiderea tag ului pe care il dublez, daca este atunci am terminat
	   tag_pereche="$tag"
	else								#s ar putea sa fie o greseala de logica aici sau nu mai stiu eu ce am scris
	   tag_pereche="</${tag#<}"
	fi

	if [[ "$tag_pereche" == "$tag_adaugat_pereche" ]]; then
	   adaugare=1							#am terminat cu succes crearea variabilei noul_text
	   break
	fi
      else								#inca nu creez variabila noul_text
	if [[ "$adaugare" == -1 ]]; then				#inca nu am gasit tag ul de dublat
	   if [[ $line == *$tag_adaugat* ]]; then			#daca am gasit tag ul, acesta fiind prezent il linie
	      adaugare=0
	      if [[ "$root" == 1 || "$count" == 2 ]]; then		#nu e bun tag ul daca e root sau tag cu content, pe alea nu vreau sa le dublez
	        root=0							#semnalez ca am trecut de linia cu root
	        noul_text=-1
	        adaugare_finalizata=1
		verificare=-1
		break
	      else							#am gasit tag ul de dublat si e bun, incep sa adaug variabilei noul_text
	        noul_text="$noul_text$line"
		noul_text="$noul_text$newline"
		verificare=1						#asa stiu ca am gasit ce trebuie
	      fi
           fi
	else
	   break
	fi
      fi
      if [[ "$root" == 1 ]]; then					#daca sunt la linia root, semnalez ca de acuma nu mai urmeaza root
	root=0
      fi
   done

   if [[ "$verificare" -eq 0 ]]; then					#daca verificare egal cu 0
      echo "tag ul nu a fost gasit!"
      return 1
   fi

   if [ "$verificare" == "-1" ]; then
     echo "tag ul nu este corespunzator!"
      return 1
   fi

#   echo -e "\n"
   echo "vom adauga documentului portiunea: $noul_text"
   verificare=1									#folosesc iar variabila asta
   > output.xml									#sterg continutul fis pt ca in el pun outputul de fiecare data cand rulez

   #citesc linie cu linie si adaug noul text la locul sau
   for line in "${lines[@]}"; do
      echo "$line" >> output.xml						#scriu fiecare linie in output
      count=$(echo "$line" | grep -o "<" | wc -l)
      #if [[ "$line" =~ "/" && "$count" == 1 ]]; then
      if [[ $line =~ (<[^>]+>) && "$count" == 1 ]]; then			#am o linie cu doar 1 tag
	tag="${BASH_REMATCH[1]}"
	#echo "AICI ESTE $tag"
	if [[ "$tag" == "$tag_adaugat_pereche" && "$verificare" == 1 ]]; then	#verificam daca este tag ul dupa care adaugam si verificare ne asigura ca nu l am adaugat deja
	   echo "$noul_text" >> output.xml
	   verificare=0
	fi
      fi
   done

   return 0
}
#echo "$1"
scriere "$1"					#apel functie

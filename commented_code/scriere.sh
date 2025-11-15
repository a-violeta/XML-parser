#!/bin/bash

#fac vector din liniile documentului, la prima iterare prin linii caut tag ul pe care o sa l 'dublez' si fac o variabila ce retine noul text pe care il pun in fisierul output
#variabila noul_text: o sa aiba ceva de genul:
#<tag1>
#	<tag2>...</tag2>
# 	<tag3>...</tag3>
#</tag1>
#variabila se creaza concatenand linie cu linie in functie de cum arata tag ul original in document. practic doar ce cu '...' va fi diferit de tag ul din document, adica doar liniile cu content in interiorul tag urilor vor fi modificate, restul sunt doar copiate
#la a doua iterare scriu toate liniile in output, dar cand gasesc sfarsitul tag ului pe care l am dublat, adaug in output variabila noul_text apoi adaug liniile ramase. asa stim sigur ca adaugam variabila noul_text unde are sens, la sfarsitul unui tag de acelasi tip
#variabila adaugare: cand eu caut tag ul de dublat pentru a creea variabila noul_text
#variabila i este pt scrierea aia 'content 1' 'content 2'...
#variabila root e o variabila booleana care e 1 daca linia curenta este linia cu tag ul root ului, 0 altfel. e initializata cu 1 pt ca root e prima linie din document
#variabila verificare indica daca s a putut dubla tag ul sau nu: -1 pt tag necorespunzator (root sau tag cu content) si 0 pt tag ce nu se gaseste deja in fisier (nu putem adauga in fisier un tag ce nu stim ca se gaseste deja acolo)
#variabila verificare e initializata 0 si daca nu gaseste tag ul in document deloc, ramane 0, daca gaseste dar e un tag necorespunzator ia valoarea -1
#variabila newline ajuta sa punem newline in noul_text
#variabila tag_adaugat_pereche este practic </student> pt <student>, student fiind tag ul citit de la tastatura

scriere() {
   if [[ ! -f "$1" ]]; then	# $1 este fisierul transmis, primul (si singurul) argument al programului
      echo "Fisierul nu exista."
      return 1
   fi

   echo "introduceti numele tagului pe care doriti sa l adaugati: "	#cu echo scriem
   #aici daca introduci numele tag ului fara < > nu l gaseste
   #daca introduci tag de inchidere in loc de deschidere o sa copieze continutul fisierului pana gaseste '<//tag>' ceea ce e imposibil
   #deci nu voi dubla tag uri de genul '<tag>continut</tag>'
   #root (tag ul ce contine tot ce e in document, adica primul tag) trebuie sa ramana unic
   read tag_adaugat	#asa citim de la tastatura
   noul_text=$'\n'
   i=0
   adaugare=-1						#va avea valoarea -1 pentru tag negasit, 0 pt procesare, adica se creaza variavila noul_text, 1 pt finalizat creare noul_text
   root=1
   verificare=0
   newline=$'\n'					#adaug \n cand e cazul

   tag_adaugat_pereche="</${tag_adaugat#<}"		#fac tag ul de inchidere al tag ului furnizat (din tag ul furnizat sterg "<" si adaug "</")

   mapfile -t lines < "$1"				#trebuie sa parcurg documentul de 2 ori deci fac vector din liniile sale

   #caut tag ul pe care il dublez si il dublez in noul_text
   for line in "${lines[@]}"; do	#for line in lines
      #count retine nr de aparitii al "<", explicatie: echo afiseaza linia curenta si o paseaza cu "|" (pipe) comenzii grep ce cauta simbolul si apoi o paseaza lui wc care numara nr de aparitii
      count=$(echo "$line" | grep -o "<" | wc -l)			#in functie de nr de "<" de pe linie stim cate tag uri are, iar deobieci fisierele xml au pe linii ori cate un tag de deschidere sau inchidere sau au ambele tag uri cu content intre ele

      if [[ "$adaugare" == 0 ]]; then					#sunt in procesul de creare al tag ului dublat
        if [[ $line =~ (<[^>]+>) ]]; then				#if linia curenta contine tag, asa a zis chat gpt
	   tag="${BASH_REMATCH[1]}"
        fi
	line2="${line/${BASH_REMATCH[0]}/}" 				#e linia curenta, dar fara tag ul ei
	line2=$(echo "$line2" | tr -d '[:space:]')			#tot linia curenta, dar si fara spatii, e tot comanda cu pipe si asta

	if [ -n "$line2" ]; then					#if line2 nu e null inseamna ca mai are si content si tag de inchidere
	   line=$(echo "$line" | sed 's/>\(.*\)/>/')			#iau LINIA ORIGINALA si o tai ca sa pot adauga in noul_text '	<tag_i>' nu doar '<tag_i>'
	   noul_text="$noul_text$line"					#asa concatenez line la noul_text
	   ((i++))
	   content="content $i"						#"content 1" "content 2" ...
	   noul_text="$noul_text$content"				#concatenez
	   tag_inchidere="</${tag#<}"					#din tag ul curent creez si tag ul de inchidere eliminand "<" si adaugand "</"
	   noul_text="$noul_text$tag_inchidere"
	   noul_text="$noul_text$newline"				#concatenez si tag ul de inchidere si newline
	else								#else, linia curenta are doar un tag si il adaug variabilei impreuna cu newline
	   noul_text="$noul_text$line"
	   noul_text="$noul_text$newline"
	fi								#if se incheie cu fi, regula generala

	if [[ "$tag" =~ "/" ]]; then					#if tag contine "/"
	   if [[ "$tag" == "$tag_adaugat_pereche" ]]; then		#if tag ul asta de inchidere e tag ul de inchidere al tag ului pe care il dublam
	      adaugare=1						#am terminat cu succes crearea variabilei noul_text
	      break							#for ul asta si a indeplinit scopul
       	   fi
	fi
      else								#else: inca nu creez variabila noul_text, fie n am gasit tag ul de dublat, fie l am gasit si nu a fost corespunzator
	if [[ "$adaugare" == -1 ]]; then				#if inca nu am gasit tag ul de dublat
	   if [[ $line == *$tag_adaugat* ]]; then			#if linie contine tag ul cautat
	      adaugare=0						#am gasit tag ul, modific variabila adaugare
	      if [[ "$root" == 1 || "$count" == 2 ]]; then		#if nu e bun tag ul, e pe linia root (este tag ul de root) sau tag cu content (pe linia asta sunt 2 simboluri "<")
	        root=0							#semnalez ca am trecut de linia cu root
	        noul_text=-1						#irelevanta modificare, am facut asta doar pt ca pot
	        adaugare_finalizata=1					#irelevanta si asta, dar intradevar am finalizat cu variabila noul_text
		verificare=-1						#pt mesajul de eroare "tag necorespunzator"
		break
	      else							#else: am gasit tag ul de dublat si e bun, incep sa adaug variabilei noul_text
	        noul_text="$noul_text$line"
		noul_text="$noul_text$newline"
		verificare=1						#verificare asigura ca am gasit ce trebuie
	      fi
           fi
	else
	   break							#am gasit tag ul dar nu a fost corespunzator
	fi
      fi
      if [[ "$root" == 1 ]]; then					#daca sunt la linia root, semnalez ca de acuma nu mai urmeaza root, asa variabila root ramane 0 pt fiecare linie care nu e prima
	root=0
      fi
   done

   if [[ "$verificare" -eq 0 ]]; then					#if verificare equal 0
      echo "tag ul nu a fost gasit!"
      return 1								#return ceva diferit de 0 pt a arata eroare
   fi

   if [ "$verificare" == "-1" ]; then
     echo "tag ul nu este corespunzator!"
      return 1
   fi

#   echo -e "\n"							#doar pt afisare estetica
   echo "vom adauga documentului portiunea: $noul_text"
   verificare=1
   #folosesc iar variabila asta ca sa stiu daca am adaugat deja noul_text in output sau nu.
   #am stabilit ca adaugam planta dupa planta, studentul dupa student, dar daca gasim mai multi studenti nu adaugam dupa fiecare
   
   > output.xml									#sterg continutul fis pt ca in el pun outputul de fiecare data cand rulez programul

   #citesc linie cu linie si adaug noul text la locul sau
   for line in "${lines[@]}"; do
      echo "$line" >> output.xml						#scriu fiecare linie in output.xml folosind tot comanda echo
      count=$(echo "$line" | grep -o "<" | wc -l)
      #if [[ "$line" =~ "/" && "$count" == 1 ]]; then
      if [[ $line =~ (<[^>]+>) && "$count" == 1 ]]; then			#if linie cu doar 1 tag
	tag="${BASH_REMATCH[1]}"
	if [[ "$tag" == "$tag_adaugat_pereche" && "$verificare" == 1 ]]; then	#verificam daca este tag ul dupa care adaugam si 'verificare' ne asigura ca nu l am adaugat deja
	   echo "$noul_text" >> output.xml
	   verificare=0								#am adaugat deja noul_text, de acum nu mai poate fi adaugat
	fi
      fi
   done

   return 0
}

scriere "$1"					#apel functie cu argumentul $1 care este luat din rularea scriptului. dupa ce dai chmod +x scriere.sh pt a avea permisiunea de executie poti rula cu ./scriere.sh input_plante.xml

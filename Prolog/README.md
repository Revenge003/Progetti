Il progetto è una libreria per la compressione 
e decompressione di "documenti"
basata sul metodo di Huffman.

L'editor usato è Emacs di swi-prolog.
Per l'indentazione abbiamo usato il comando alt-x+prolog-mode e poi
atl-x+indent-region dell'editor di Emacs.
Alcune righe sono ulteriormente mandate a capo, per evitare il superamento
delle 80 colonne.

L'idea di base è rappresentata dal predicato 
hucodec_generate_huffman_tree che prende una lista di coppie 
definite come sw(Key, Weight),
trasforma le coppie in nodi definiti come 
node(Key, Weight, LeftChild, RightChild)
dove LeftChild e RightChild sono impostati a void durante 
la prima iterazione, e genera l'albero di Huffman associato alla lista.

Nella lista di coppie SwList da dare in input al predicato 
hucodec_generate_huffman_tree, se il simbolo è una lettera maiuscola 
oppure uno spazio, è necessario scrivere il simbolo tra apici singoli (' '),
per evitare che l'interprete SWI-Prolog consideri 
le lettere maiuscole come variabili e lo spazio come un errore.

Nel caso in cui i risultati delle codifiche e/o delle decodifiche 
siano delle liste piuttosto lunghe, l’interprete Prolog 
mostra troncate tali liste. 
Se si desidera vedere le liste nella loro interezza, 
è possibile usare il predicato
set_prolog_flag(answer_write_options, [max_depth(0), max_list(0)]).
prima di effettuare la query, 
il quale elimina il limite della lunghezza nelle liste.

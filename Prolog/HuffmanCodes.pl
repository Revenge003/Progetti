% -*- Mode: Prolog -*-
% Compressione e decompressione via codifica di Huffman

% hucodec_decode/3
hucodec_decode([], Huffman_tree, []).
hucodec_decode(Bits, Huffman_tree, [Symbol|Message]) :-
    decode_symbol(Bits, Huffman_tree, Symbol, RestBits),
    hucodec_decode(RestBits, Huffman_tree, Message).

% hucodec_encode/3
hucodec_encode([], _, []):- !.
hucodec_encode(Message, Huffman_tree, Bits):-
    hucodec_generate_symbol_bits_table(Huffman_tree, Table),
    hucodec_encode_msg(Message, Table, Bits).

% hucodec_encode_file/3
hucodec_encode_file(FileName, Huffman_tree, Bits) :-
    open(FileName, read, Stream),
    read_stream_to_codes(Stream, Codes),
    close(Stream),
    atom_codes(Atom, Codes),
    atom_chars(Atom, Message),
    hucodec_encode(Message, Huffman_tree, Bits).

% hucodec_generate_huffman_tree/2
hucodec_generate_huffman_tree([], void).
hucodec_generate_huffman_tree(SwList, Huffman_tree):-
    SwList = [sw(_, _) | _],
    trasform_into_node(SwList, NewSwList),
    hucodec_generate_huffman_tree(NewSwList, Huffman_tree).
hucodec_generate_huffman_tree([Huffman_tree], Huffman_tree):- !.
hucodec_generate_huffman_tree(SwList, Huffman_tree):-
    two_min(SwList, Node1, Node2),
    Node1 = node(Key1, Weight1, _, _),
    Node2 = node(Key2, Weight2, _, _),
    Weight is Weight1 + Weight2,
    combine_keys(Key1, Key2, NewKey),
    NewNode = node(NewKey, Weight, Node1, Node2),
    remove(Node1, SwList, List1),
    remove(Node2, List1, NewSwList),
    NewList = [NewNode | NewSwList],
    hucodec_generate_huffman_tree(NewList, Huffman_tree).

% hucodec_generate_symbol_bits_table/2
hucodec_generate_symbol_bits_table(Tree, Table) :-
    hucodec_generate_symbol_bits_table_list(Tree, TableList),
    convert_codes(TableList, Table).

% hucodec_print_huffman_tree/1
hucodec_print_huffman_tree(Tree) :-
    print_tree(Tree, 0, 'Root').

% Predicati ausiliari  

% trasform_into_node/2
% Trasforma ogni coppia sw(Key, Weight) in nodi node(Key, Weight, void, void)
trasform_into_node([], []).
trasform_into_node([sw(Key, Weight) | Tail],
		   [node(Key, Weight, void, void) | New_tail]):-
    trasform_into_node(Tail, New_tail).

% two_min/2
% Trova i due elementi (foglia o nodo) con il peso minimo dalla lista SwList
two_min([], _, _):- fail.
two_min([_], _, _):- fail.
two_min([X, Y], Min1, Min2) :-
    X = node(_, Weight1, _, _),
    Y = node(_, Weight2, _, _),
    Weight1 =< Weight2,
    Min1 = X,
    Min2 = Y.
two_min([X, Y], Min1, Min2) :-
    X = node(_, Weight1, _, _),
    Y = node(_, Weight2, _, _),
    Weight1 > Weight2,
    Min1 = Y,
    Min2 = X.
two_min([X | Tail], Min1, Min2):-
    two_min(Tail, M1, M2),
    update(X, M1, M2, Min1, Min2).

% update/5
% Aggiorna i pesi minimi trovati, confrontando il peso 
% del primo argomento con quelli dei due argomenti correnti
update(X, M1, M2, Min1, Min2) :-
    X = node(_, Weight, _, _),
    M1 = node(_, Weight1, _, _),
    Weight < Weight1, !,
    Min1 = X,
    Min2 = M1.
update(X, M1, M2, Min1, Min2) :-
    X = node(_, Weight, _, _),
    M1 = node(_, Weight1, _, _),
    M2 = node(_, Weight2, _, _),
    Weight >= Weight1,
    Weight < Weight2, !,
    Min1 = M1,
    Min2 = X.
update(X, M1, M2, Min1, Min2) :-
    X = node(_, Weight, _, _),
    M1 = node(_, Weight1, _, _),
    M2 = node(_, Weight2, _, _),
    Weight >= Weight1,
    Weight >= Weight2,
    Min1 = M1,
    Min2 = M2.

% remove_node/3
% Rimuove il nodo passato come argomento dalla lista SwList
remove(_, [], []).
remove(Node, [Node | Tail], Tail):- !.
remove(NodeX, [NodeY | Tail], [NodeY | New_tail]):-
    remove(NodeX, Tail, New_tail).

% combine_keys/3
% Predicato che combina le chiavi dei due nodi, appiattendo eventuali tuple
% nidificate
combine_keys(Key1, Key2, NewKey) :-
    key_to_list(Key1, List1),
    key_to_list(Key2, List2),
    append(List1, List2, List),
    list_to_tuple(List, NewKey).

% key_to_list/2
% Predicato che controlla: se Key e' un atomo, restituisce [Key], invece se
% e' una tupla, la appiattisce in una lista.
key_to_list(Key, [Key]) :-
    atom(Key), !.
key_to_list((A, B), List) :-
    key_to_list(A, ListA),
    key_to_list(B, ListB),
    append(ListA, ListB, List).

% list_to_tuple/2
% Converte una lista di almeno un elemento in una tupla annidata.
list_to_tuple([X], X).
list_to_tuple([X|Xs], (X, RestTuple)) :-
    list_to_tuple(Xs, RestTuple).

% hucodec_generate_symbol_bits_table_list/2
% Predicato che processa ricorsivamente i sottoalberi destro e sinistro
% e aggiunge il bit prefisso in base a dove si sposta
% (sinistra = 0, destra = 1)
hucodec_generate_symbol_bits_table_list(void, []).
hucodec_generate_symbol_bits_table_list(node(Key, _, void, void), [(Key, [])]).
hucodec_generate_symbol_bits_table_list(node(_, _, Left, Right), TableList) :-
    hucodec_generate_symbol_bits_table_list(Left, TableLeft),
    hucodec_generate_symbol_bits_table_list(Right, TableRight),
    add_prefix_to_codes(0, TableLeft, PrefixedLeft),
    add_prefix_to_codes(1, TableRight, PrefixedRight),
    append(PrefixedLeft, PrefixedRight, TableList).

% add_prefix_to_code/3
% Aggiunge il Bit in testa al codice di ogni coppia (Key, Code) nella tabella.
add_prefix_to_codes(_, [], []).
add_prefix_to_codes(Bit, [(Key, Code)|Tail], [(Key, [Bit|Code])|NewTail]) :-
    add_prefix_to_codes(Bit, Tail, NewTail).

% convert_codes/2
% Converte ogni lista di bit in un atomo, ottenendo cosi la codifica compatta.
convert_codes([], []).
convert_codes([(Key, CodeList)|Rest], [sb(Key, CodeList)|RestAtoms]) :-
    convert_codes(Rest, RestAtoms).

% decode_symbol/3
% effettua la decodifica del simbolo, si sposta a sinistra nell'albero se trova
% uno 0 oppure si sposta a destra se trova un 1
decode_symbol([], node(_Key, _Weight, Left, Right), _Symbol, []) :-
    Left \= void , !,
    fail.
decode_symbol([], node(_Key, _Weight, Left, Right), _Symbol, []) :-
    Right \= void, !,
    fail.
decode_symbol(Bits, node(Key, Weight, void, void), Key, Bits).
decode_symbol([0|Rest], node(Key, Weight, Left, Right), Symbol, RestBits) :-
    decode_symbol(Rest, Left, Symbol, RestBits).
decode_symbol([1|Rest], node(Key, Weight, Left, Right), Symbol, RestBits) :-
    decode_symbol(Rest, Right, Symbol, RestBits).

% hucodec_encode_msg/3:
% Predicato che codifica in modo ricorsivo il messaggio usando la tabella
% completa.
hucodec_encode_msg([], Table, []):- !.
hucodec_encode_msg([X|Rest], Table, Bits):-
    findCode(X, Table, Code),
    hucodec_encode_msg(Rest, Table, RestBits),
    append(Code, RestBits, Bits).

% findCode/3:
% Predicato che cerca il codice associato al simbolo X nella tabella.
findCode(X, [sb(X, Code)|_], Code):- !.
findCode(X, [sb(Key, _) | Tail], Code):-
    X \= Key,
    findCode(X, Tail, Code).

% print_tree/3
% Stampa l'albero di Huffman in modo indentato.
% - node(Key, Weight, Left, Right): l'albero (o sottoalbero) da stampare.
% - Indent: numero di spazi da stampare prima della linea.
% - Label: etichetta per indicare se si tratta del nodo radice, del figlio
%          sinistro o destro.
print_tree(void, _, _) :- !.
print_tree(node(Key, Weight, void, void), Indent, Label) :-
    print_indent(Indent),
    format('~w: Leaf ~w (Weight: ~w)~n', [Label, Key, Weight]).
print_tree(node(Key, Weight, Left, Right), Indent, Label) :-
    print_indent(Indent),
    format('~w: Node ~w (Weight: ~w)~n', [Label, Key, Weight]),
    NewIndent is Indent + 4,
    print_tree(Left, NewIndent, 'Left'),
    print_tree(Right, NewIndent, 'Right').

% print_indent/1
% Stampa N spazi.
print_indent(0).
print_indent(N) :-
    N > 0,
    write(' '),
    N1 is N - 1,
    print_indent(N1).

% end of file huffman-codes.pl

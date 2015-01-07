(** Parser de partitions.*)

(** Variable de débuggage.*)
val _DEBUG_ : bool

(** Affiche la string donnée en paramètre sur la sortie standard si _DEBUG_ est vrai.*)
val message : string -> unit

(** Feuille de partition donnée par Mr Perin.*)
val row_sheet : string

(** Module de modification de liste et de liste de listes.*)
module MyList :
  sig
    (** Renvoie les n premiers éléments d'une liste. n donné en paramètre*)
    val first : int -> 't list -> 't list

    (** Renvoie une liste de listes crée à partir d'une liste l1, et d'une liste de listes l2. On prend l'élément n de l1 que l'on concatène à la liste n de l2 si elle existe, sinon à []. Quand il n'y a plus d'éléments dans l1, on concatène ce qu'il reste de l2 en queue.*)
    val safe_zipper : 't -> 't list -> 't list list -> 't list list

    (** Définit l'ensemble des fonctions qui à une liste et une liste de listes, associe une liste de liste.*)
    type 't zipper = 't list -> 't list list -> 't list list

    (** Crée une liste de liste à partir d'un zipper. Le zipper est une fonction qui prend en entrée une liste et une liste de liste et renvoie une liste de liste.*)
    val zip_with : 't zipper -> 't list list -> 't list list

    (** Crée une liste d'elements de type 'y à partir d'une liste d'éléments de type 'x, et d'une fonction de conversion transformant un x en une liste de 'y.*)
    val foreach : 'x list -> ('x -> 'y list) -> 'y list
  end

(** Module de modification de string.*)
module MyString :
  sig
    type line = char list
    type column = char list
    type lineStr = string list
    type columnStr = string list

    val fold : ('o -> char -> 'o) -> 'o -> string -> 'o
    val to_char_list : string -> char list

    (** Permet de lire les caractères "1o" et "1@" utilisés dans le parser du tempo (12/20).*)
    val to_string_list : char list -> string list
    val to_line_list : string -> line list
    val transpose : line list -> column list

    (** Transpose une liste de liste de string.*)
    val transposeStr : lineStr list -> columnStr list
    val char_list_to_string : char list -> string

    (** Transforme une chaine de caractères écrites sur plusieurs lignes en une nouvelle, telles que cette nouvelle chaine represente l'ancienne, mais lu à la verticale.*)
    val test_transpose : string -> string
  end

(** Variable de test pour test_transpose.*)
val test : unit -> unit

(** Définition du type pattern pour les transitions dans un automate.*)
type 'a pattern =
    ANY
  | KEY of 'a
  | BUT of 'a
  | IN of 'a list
  | OUT of 'a list

(** Module définissant des opérations utiles sur le type pattern.*)
module Pattern :
  sig
    (** Type ??? *)
    type 'a t = 'a pattern

    (** Renvoie true si le pattern donné en paramètre est de type KEY et que la composante de KEY vaut un paramètre de type 'a donné.*)
    val exactly : 'a pattern -> 'a -> bool

    (** Prend un pattern de type 'a et une variable de type 'a et renvoie :
    Si pattern satisfait "ANY" -> true. Si le pattern satisfait "KEY a" -> a = a'. Si le pattern satisfait "BUT a" -> a <> a'. Si le pattern satisfait "IN aS" -> aS contient a'. Si le pattern satisfait "OUT aS" -> aS ne contient pas a'.*)
    val matches : 'a pattern -> 'a -> bool

    (** Transforme un pattern en une chaine de caractere suivant sa composition. Prend en entrée une fonction permettant de convertir un élément de type 'a en une chaine de caractères.*)
    val pretty : ('a -> string) -> 'a pattern -> string

    (** Affiche un pattern sur la sortie standard, suivant une fonction de conversion d'élément de type 'a vers une chaine de caractères.*)
    val print : ('a -> string) -> 'a pattern -> unit
  end

(** Définition du type clock pour la valeur de tempo et de durée sur la partition.*)
type clock = float

(** Module définissant des opérations utiles sur le type clock.*)
module Clock :
  sig
    type date = float
    type duration = float

    (** Renvoie la valeur initial d'une variable date : 0.0*)
    val initial : date

    (** Incremente une variable date d'une durée définit par duration.*)
    val shift_by : duration -> date -> date
  end

(** Définition du type sound définissant un son dans la lecture de la partition.*)
type sound = string

(** Définition du type timed_sound, associant à un son, une date.*)
type timed_sound = clock * sound
type 't sequence = 't list

(** Définition du type soundtrack comme étant une liste de timed_sound.*)
type soundtrack = timed_sound sequence

(** Définition du type sic représentant un son en construction. Soit il est nul, soit c'est une liste de string associée à une date.*)
type sic = Nil | Sic of (clock * string list)

(** Module d'opérations sur le type sic.*)
module Sound :
  sig
    (** Crée une soundtrack à partir d'un son en construction. Si le son est nul, on renvoie [] sinon on renvoie une liste composée d'un timed_sound. Ce timed_sound est lui-même composé de la clock du SIC, et de la string résultante de la concaténation de la liste de string du SIC.*)
    val finalize : sic -> soundtrack

    (** Etend un son en construction avec une nouvelle string. S'il est nul, on crée un couple avec la clock et la string passées en paramètre, sinon on concatène la string en tête de la liste de string, du couple (clock * string list).*)
    val extend_with : string -> clock -> sic -> sic

    (** Même fonctionnalités que extend_with, mais l'ajout se fait ici en queue.*)
    val extend_with_tail : string -> clock -> sic -> sic

    (** Remplace toutes les occurences d'une string donnée en paramètre par une autre string, dans une liste de string.*)
    val modifyStringList : string -> string -> string list -> string list

    (** Modifie un son, en remplaçant un son donné en paramètre par un autre.*)
    val modifySound : string -> string -> sic -> sic
  end

(** Définition du type data comme étant composé d'une date, d'un son et d'une soundtrack. *)
type data = { clock : clock; sound : sic; soundtrack : soundtrack; }

(** Module d'opérations sur le type data.*)
module Data :
  sig
    (** Initialise une variable data, clock à 0.0, sic à Nil et soundtrack à [].*)
    val initial : data

    (** Finalise une variable data en ajoutant le son en construction à la soundtrack et en détruisant sic.*)
    val finalize : data -> data

    (** Récupère la clock.*)
    val get_clock : data -> clock

    (** Récupère la soundtrack.*)
    val get_soundtrack : data -> soundtrack

    (** Met à jour l'horloge en attribuant à l'horloge d'une variable data, la valeur d'une clock passée en paramètre.*)
    val update_clock : clock -> data -> data
  end


type symbol = string

(** Définition du type action, tel que action est l'ensemble des fonctions prennant en paramètre un triplet de (clock * data * symbol) et renvoyant une variable de type data.*)
type action = clock * data * symbol -> data

(** Module d'opération avec le type action.*)
module Action :
  sig
    (** Crée l'action d'incrémentation de l'horloge par rapport à une durée donnée.*)
    val increase_clock_by : Clock.duration -> action

    (** Crée l'action qui ajoute à un son une string donnée.*)
    val extend_sound_with : string -> action

    (** Crée l'action qui ajoute à un son le symbole lu par l'automate.*)
    val extend_sound_with_symbol : action

    (** Crée l'action qui finalise un objet data au sens de la fonction finalize du module Data.*)
    val finalize_sound : action

    (** Crée l'action qui finalize un objet data au sens de la fonction finalize du module Data. 
      On est ici dans le cas de l'automate "Drum" pour lequel chaque élément doit commencer par un ':' (utilisé lors de la reconnaissance des pistes dans le module de Karaoke). Dans le cas de "Poum", "Poumtchak" ou "Crack" l'ajout de ':' peut se faire directement dans l'automate. Cependant quand "tchak" est tout seul, on ne peut pas, on doit donc le faire ici.*)
    val finalize_sound_drum : action

    (** Crée l'action qui crée un son à partir d'une string.*)
    val make_sound : string -> action

    (** Crée l'action qui met à jour l'horloge avec une autre horloge donnée en paramètre.*)
    val update_clock : action

    (** Applique une liste d'actions en une seule.*)
    val apply_sequence_of : action sequence -> action
  end

(** Variable epsilon des automates à epsilon-transition.*)
val epsilon : string

(** Définition d'inputs, soit une liste de symbol (string).*)
type inputs = symbol sequence
type node = int

(** Définition du type transition, tel qu'une transition va d'un noeud vers un nouveau et, est définit par un label de type symbol pattern (un pattern de symbol (se référer aux fonctions sur les pattern)) et d'une séquence d'actions à faire.*)
type transition = node * label * action sequence * node
and label = symbol pattern

(** Définition d'un automate par son nom et une liste de transitions.*)
type automaton = { name : string; transitions : transition list; }

(** Module d'opérations sur les automates.*)
module Automaton :
  sig
    (** Noeud initial = 1*)
    val initial_node : node

    (** Crée un automate à partir d'une string (le nom de l'automate) et d'une liste de transitions.*)
    val make : string -> transition list -> automaton

    (** Récupère la transition qui part d'un noeud donné pour un autre noeud, et qui satisfait le symbol donné en paramètre. *)
    val get_transition_on : symbol -> automaton -> node -> transition option

    (** Transforme une liste d'automates en une liste de couples (string * automaton) représentant un automate associé à son nom.*)
    val install : automaton list -> (string * automaton) list

    (** Retourne l'automate associé à un nom donné en paramètre, en faisant la recherche dans une liste de couple (nom * automate). Pour plus d'informations, consulter la doc de List sur http://caml.inria.fr/pub/docs/manual-ocaml/libref/List.html et plus particulièrement la fonction assoc de ce module.*)
    val named : string -> (string * automaton) list -> automaton
  end

(** Liste des chiffres de 0 à 9 sous forme de caractères ('0'..'9').*)
val digit : string list

(** Liste des caractères valables pour la lecture de la piste "Lyrics".*)
val letter : string list

(** Automate par défaut. Automate à 1 état.*)
val adef : automaton

(** Automate de parsing des répétitions. Automate à 2 états.*)
val arepeat : automaton

(** Automate de parsing du tempo. Automate à 2 états.*)
val atempo : automaton

(** Automate de parsing des paroles. Automate à 2 états.*)
val averbose : automaton

(** Automate de parsing de la batterie. Automate à 1 état.*)
val adrum : automaton

(** Automate de parsing de la guitare. Automate à 1 état.*)
val aguitar : automaton

(** Liste des automates adef, atempo et adrum associés à leur noms respectifs.*)
val _AUTOMATA_ : (string * automaton) list

(** Définition du type state. Un état est définit par le noeud courrant et par la donnée du son en construction.*)
type state = { node : node; data : data; }

(** Module d'opérations sur le type State.*)
module State :
  sig
    (** Etat initial. On est sur le noeud initial (1) et on a une donnée en construction vide (utilisation de la fonction initial du module Data.*)
    val initial : state

    (** Récupère l'horloge de la donnée en construction.*)
    val get_clock : state -> clock

    (** Récupère la soundtrack de la donnée en construction.*)
    val get_soundtrack : state -> soundtrack

    (** Met à jour l'horloge de la donnée en construction.*)
    val update_clock : clock -> state -> state

    (** Met à jour un état, en mettant à jour le noeud courrant (le nouveau noeud courrant est donné dans les paramètres de la fonction) ainsi que la donnée en construction avec une sequence d'actions à faire.*)
    val update : clock * state -> symbol * action sequence * node -> state
  end

(** Définition du type process, tel qu'un process est composé du nom d'un automate et d'un état.*)
type process = { automaton : string; state : state; }

(** Module d'opérations sur le type process.*)
module Process :
  sig

    (** Récupère l'horloge de l'état.*)
    val get_clock : process -> clock

    (** Récupère la soundtrack de l'état.*)
    val get_soundtrack : process -> soundtrack

    (** Met à jour l'horloge du process (à travers la mise à jour de l'horloge de l'état).*)
    val update_clock : clock -> process -> process

    (** Initialise un process avec un automate. Le process prend comme nom le nom de l'automate, et prend comme état, l'état initial.*)
    val initialize : automaton -> process

    (** Avance d'un état dans un process.*)
    val one_step_on : symbol -> (clock * process) -> (clock * process)

    (** Avance d'un état dans un ensemble de process.*)
    val one_step_each_process : symbol list -> (clock * process list) -> (clock * process list)
  end

(** *)
type frame = string list
type sheet = frame list

(** Nouveau type utilisé dans le cas des sons joués en simultanés.*)
type newSoundtrack = clock * string list

(** Un sheet parser est une liste de processus. Chaque processus doit analyser une ligne de la partition. Tout les processus fonctionnent en même temps tout en étant synchronisé. Le type run est définit par une clock de référence pour tout les process, une liste de process, ce qu'il reste à lire de la partition et une liste de soundtrack. Quand on arrive à la fin de la partition, la liste de soundtracks est rempli par l'ensemble des soundtracks de chaque process.*)
type run = {
  clock : clock;
  processus : process list;
  sheet : sheet;
  soundtracks : newSoundtrack list;
}

(** Module d'opérations sur le type newSoundtrack.*)
module SyncSound :
  sig

    (** Convertit une liste de soundtrack basique en une liste de newSoundtrack.*)
    val to_new_soundtrack : ('a * 'b) list -> ('a * 'b list) list

    (** Combine un couple (clock*string list) à un autre élément d'une liste donnée si ceux-ci ont la même clock.*)
    val bind : newSoundtrack -> newSoundtrack list -> newSoundtrack list

    (** Combine l'ensemble d'une newSoundtrack list, permettant de créer le format de donné demandé pour le 14/20*)
    val combineSub : newSoundtrack list -> newSoundtrack list

    (** Transforme une liste de soundtrack basique en une newSoundtrack list, et combine l'ensemble de ses éléments.*)
    val combine : (clock * string) list list -> newSoundtrack list

    (** Fonction de comparaison permettant de trier une newSoundtrack list à l'aide de List.sort*)
    val compare : newSoundtrack -> newSoundtrack -> int
  end

(** Type représentant répétition. Celui-ci est composé du temps de début de la répétition, du nombre de répétition et du temps de fin.*)
type repeat = float * int * float

(** Module d'utilisation des répétitions.*)
module Repeat :
  sig

    (** Cherche si une liste de string contient la chaine "start".*)
    val containStart : string list -> bool

    (** Cherche si une liste de string contient la chaine "stop".*)
    val containStop : string list -> bool

    (** Cherche si une liste de string contient la chaine "start" ou la chaine "stop".*)
    val containStartOrStop : string list -> bool

    (** Cherche si une liste de string contient la chaine "start" et la chaine "stop".*)
    val containStartAndStop : string list -> bool

    (** Supprimer une string donnée d'une liste de string.*)
    val deleteString : ('a * 'b list) list -> 'b -> ('a * 'b list) list

    (** Sépare les éléments qui contiennent une parole, un son joué à la batterie ou à la guitare, des données de répétitions.
      Ces différents sons, sont identifié par des marqueur : ':' ; '/' ; '!'.*)
    val splitStartOrStop : clock * string list -> newSoundtrack list * newSoundtrack list

    (** Extrait d'une liste de newSoundrtack l'ensemble des données de répétitions. On obtient deux listes, une contenant les données de la forme [(8., ["4", "start"]); (16., ["stop"])] par exemple et l'autre contenant les sons à jouer.*)
    val extractStartAndStop : (clock * string list) list -> newSoundtrack list * newSoundtrack list

    (** Récupère le nombre de répétitions à partir d'une liste de string. Cette liste de string doit être du même format que celui donén dans l'exemple de la fonction extractStartOrStop.*)
    val getRepeatNumb : string list -> int

    (** Extrait un ensemble de répétitions à partir liste de newSoundtrack représentant les données de répétitions.*)
    val extractRepeat : (clock * string list) list -> (clock * int * clock) list

    (** Extrait une partie d'une newSoundtrack en se basant sur un temps de départ et un temps de fin. Le résultat est un couple de trois nouvelles newSoundtrack list réprésentant les éléments avant l'intervalle donné, dans l'intervalle et après l'intervalle.*)
    val extractFromTo : ('a * 'b) list -> 'a -> 'a -> ('a * 'b) list * ('a * 'b) list * ('a * 'b) list

    (** Augmente le temps d'une durée donné pour chaque élément d'une liste de newSoundtrack.*)
    val addTime : (float * 'a) list -> float -> (float * 'a) list

    (** Repète n fois une partie d'une newSoundtrack list.*)
    val repeatFromTo : (float * 'a) list -> float -> float -> int -> (float * 'a) list

    (** Applique un ensemble de répétitions.*)
    val applyRepeat : (float * int * float) list -> (float * 'a) list -> (float * 'a) list

    (** Extrait les données de répétitions d'une newSoundtrack list et les applique. Retourne la nouvelle liste de newSoundtrack.*)
    val makeRepeat : (clock * string list) list -> newSoundtrack list

  end

(** Module d'utilisation du Parser de Partitions.*)
module SheetParser : 
  sig

    (** Initialise une variable de type run, en initialisant la clock à son état initial, la liste de processus est créée en utilisant la fonction initialize du module Process permettant d'initialiser un process à partir d'un automate, appliqué à la liste d'automates. La liste de soundtrack est initialisée à [].*)
    val initialize : automaton list -> sheet -> run

    (** Avance d'une étape dans chaque process si la sheet de la variable run passée en paramètre n'est pas vide. Si elle est vide, on finalise la liste de soundtracks (on rempli la liste de soundtracks).*)
    val one_step : run -> run
  end

(** Module implémentant les fonctions utilisées pour l'affichage de la partition sous forme graphique avec gestion des temps.*)
module KaraokeMod :
  sig

    (** Fonctions permettant d'arrêter l'exécution d'un code pendant une durée donnée en seconde (sous forme de float).*)
    val mysleep : float -> unit

    (** Imprime dans une fenêtre graphique une string de façon centrée horizontalement et verticalement. La taille de la fenêtre doit être donéne, et on peut ajouter des décalages verticales et horizontaux au centrage.*)
    val printCenterizedString : string -> int -> int -> int -> int -> unit

    (** Découpe une newSoundtrack list en trois sous listes représentant les paroles, la batterie et la guitare (ceci est fait grâce aux identificateurs).*)
    val splitTimedSound : 'a * string list -> string list * string list * string list

    (** Fonction d'impression de la légende dans la fenêtre graphique.*)
    val printLegend : float -> int -> int -> unit

    (** Fonction de "karaoke" qui lis une newsoundtrack list et l'affiche dans une fenêtre graphique avec la gestion du temps donné par le tempo.*)
    val karaoke : (float * string list) list -> unit
  end

(** Utilisation de l'impératif pour la lecture de la partition.*)
val _RUN : run ref

(** <b>Impératif : </b>Initialise le parser en utilisant la fonction initialise du module SheetParser.*)
val initialize : automaton list -> sheet -> run

(** <b>Impératif : </b>Avance d'un pas dans la lecture de la partition.*)
val one_step : unit -> run

(** <b>Impératif : </b>Lis l'ensemble d'une partition et lance l'exécution du karaoke.*)
val do_all : unit -> unit

(** Crée une variable de type run à partir d'une partition, tel que cette variable combine 6 processus correspondants a chaque lignes de la partition.*)
val sheetparser : sheet -> run

(** Transposé de la partition row_sheet. On lis la partition à la verticale.*)
val full_sheet : MyString.column list

(** Renvoie les 8 premiers éléments de la liste représentative de la partition lu à la verticale.*)
val sheet : MyString.column list

(** Programme de parsing de partitions.*)

(** Variable de debuggage.*)
val _DEBUG_ : bool

(** Affiche la string donnee en parametre sur la sortie standard si _DEBUG_ est vrai.*)
val message : string -> unit

(** Feuille de partition donnee par Mr Perin.*)
val row_sheet : string

(** Module de modification de liste et de liste de listes.*)
module MyList :
  sig
    (** Renvoie les n premiers elements d'une liste. n donne en parametre*)
    val first : int -> 't list -> 't list

    (** Renvoie une liste de listes cree a partir d'une liste l1, et d'une liste de listes l2. On prend l'element n de l1 que l'on concatene a la liste n de l2 si elle existe, sinon a []. Quand il n'y a plus d'elements dans l1, on concatene ce qu'il reste de l2 en queue.*)
    val safe_zipper : 't -> 't list -> 't list list -> 't list list

    (** Definit l'ensemble des fonctions qui a une liste et une liste de listes, associe une liste de liste.*)
    type 't zipper = 't list -> 't list list -> 't list list

    (** Cree une liste de liste a partir d'un zipper. Le zipper est une fonction qui prend en entree une liste et une liste de liste et renvoie une liste de liste.*)
    val zip_with : 't zipper -> 't list list -> 't list list

    (** Cree une liste d'elements de type 'y a partir d'une liste d'elements de type 'x, et d'une fonction de conversion transformant un x en une liste de 'y.*)
    val foreach : 'x list -> ('x -> 'y list) -> 'y list
  end

(** Module de modification de string.*)
module MyString :
  sig
    type line = char list
    type column = char list

    val fold : ('o -> char -> 'o) -> 'o -> string -> 'o
    val to_char_list : string -> char list
    val to_line_list : string -> line list
    val transpose : line list -> column list
    val char_list_to_string : char list -> string

    (** Transforme une chaine de caracteres ecrites sur plusieurs lignes en une nouvelle, telles que cette nouvelle chaine represente l'ancienne, mais lu a la verticale.*)
    val test_transpose : string -> string
  end

(** Variable de test pour test_transpose.*)
val test : unit -> unit

(** Definition du type pattern pour les transitions dans un automate.*)
type 'a pattern =
    ANY
  | KEY of 'a
  | BUT of 'a
  | IN of 'a list
  | OUT of 'a list

(** Module definissant des operations utiles sur le type pattern.*)
module Pattern :
  sig
    (** type inutile*)
    type 'a t = 'a pattern

    (** Renvoie true si le pattern donne en parametre est de type KEY et que la composante de KEY vaut un parametre de type 'a donne.*)
    val exactly : 'a pattern -> 'a -> bool

    (** Prend un pattern de type 'a et une variable de type 'a et renvoie :
    Si pattern satisfait "ANY" -> true.Si le pattern satisfait "KEY a" -> a = a'. Si le pattern satisfait "BUT a" -> a <> a'. Si le pattern satisfait "IN aS" -> aS contient a'. Si le pattern satisfait "OUT aS" -> aS ne contient pas a'.*)
    val matches : 'a pattern -> 'a -> bool

    (** Transforme un pattern en une chaine de caractere suivant sa composition. Prend en entree une fonction permettant de convertir un element de type 'a en une chaine de caractere.*)
    val pretty : ('a -> string) -> 'a pattern -> string

    (** Affiche un pattern sur la sortie standard, suivant une fonction de conversion d'element de type 'a vers une chaine de caracteres.*)
    val print : ('a -> string) -> 'a pattern -> unit
  end

(** Definition du type clock pour la valeur de tempo et de duree sur la partition.*)
type clock = float

(** Module definissant des operations utiles sur le type clock.*)
module Clock :
  sig
    type date = float
    type duration = float

    (** Renvoie la valeur initial d'une variable date : 0.0*)
    val initial : date

    (** Incremente une variable date d'une duree definit par duration.*)
    val shift_by : duration -> date -> date
  end

(** Definition du type sound definissant un son dans la lecture de la partition.*)
type sound = string

(** Definition du type timed_sound, associant a un son, une date.*)
type timed_sound = clock * sound
type 't sequence = 't list

(** Definition du type soundtrack comme etant une liste de timed_sound.*)
type soundtrack = timed_sound sequence

(** Definition du type sic representant un son en construction. Soit il est nul, soit c'est une liste de string associee a une date.*)
type sic = Nil | Sic of (clock * string list)

(** Module d'operations sur le type sic.*)
module Sound :
  sig
    (** Cree une soundtrack a partir d'un son en construction. Si le son est nul, on renvoie [] sinon on renvoie une liste composee d'un timed_sound. Ce timed_sound est lui-meme compose de la clock du SIC, et de la string resultante de la concatenation de la liste de string du SIC.*)
    val finalize : sic -> soundtrack

    (** Etend un son en construction avec une nouvelle string. S'il est nul, on cree un couple avec la clock et la string passees en parametre, sinon on concatene la string en tete de la liste de string, du couple (clock * string list).*)
    val extend_with : string -> clock -> sic -> sic
  end

(** Definition du type data comme etant compose d'une date, d'un son et d'une soundtrack. *)
type data = { clock : clock; sound : sic; soundtrack : soundtrack; }

(** Module d'operations sur le type data.*)
module Data :
  sig
    (** Initialise une variable data, clock a 0.0, sic a Nil et soundtrack a [].*)
    val initial : data

    (** Finalise une variable data en ajoutant le son en construction a la soundtrack et en detruisant sic.*)
    val finalize : data -> data

    (** Recupere la clock.*)
    val get_clock : data -> clock

    (** Recupere la soundtrack.*)
    val get_soundtrack : data -> soundtrack

    (** Met a jour l'horloge en attribuant a l'horloge d'une variable data, la valeur d'une clock passee en parametre.*)
    val update_clock : clock -> data -> data
  end


type symbol = string

(** Definition du type action, tel que action est l'ensemble des fonctions prennant en parametre un triplet de (clock * data * symbol) et renvoyant une variable de type data.*)
type action = clock * data * symbol -> data

(** Module d'operation avec le type action.*)
module Action :
  sig
    (** Cree l'action d'incrementation de l'horloge par rapport a une duree donnee.*)
    val increase_clock_by : Clock.duration -> action

    (** Cree l'action qui ajoute a un son une string donnee.*)
    val extend_sound_with : string -> action

    (** Cree l'action qui finalise un objet data au sens de la fonction finalize du module Data.*)
    val finalize_sound : action

    (** Cree l'action qui cree un son a partir d'une string.*)
    val make_sound : string -> action

    (** Cree l'action qui met a jour l'horloge avec une autre horloge donnee en parametre.*)
    val update_clock : action

    (** Applique une liste d'actions en une seule.*)
    val apply_sequence_of : action sequence -> action
  end

(** Variable epsilon des automates a epsilon-transition.*)
val epsilon : string

(** Definition d'inputs, soit une liste de symbol (string).*)
type inputs = symbol sequence
type node = int

(** Definition du type transition, tel qu'une transition va d'un noeud vers un nouveau et, est definit par un label de type symbol pattern (une pattern de symbol (se referer aux fonctions sur les pattern)) et d'une sequence d'actions a faire.*)
type transition = node * label * action sequence * node
and label = symbol pattern

(** Definition d'un automate par son nom et une liste de transitions.*)
type automaton = { name : string; transitions : transition list; }

(** Module d'operations sur les automates.*)
module Automaton :
  sig
    val initial_node : node
    val make : string -> transition list -> automaton
    val install : automaton list -> (string * automaton) list
    val named : string -> (string * automaton) list -> automaton
  end
val adef : automaton
val digit : string list
val atempo : automaton
val adrum : automaton
val _AUTOMATA_ : (string * automaton) list
type state = { node : node; data : data; }
module State :
  sig
    val initial : state
    val get_clock : state -> clock
    val get_soundtrack : state -> soundtrack
    val update_clock : clock -> state -> state
    val update : clock * state -> symbol * action sequence * node -> state
  end
type process = { automaton : string; state : state; }
module Process :
  sig
    val get_clock : process -> clock
    val get_soundtrack : process -> soundtrack
    val update_clock : clock -> process -> process
    val initialize : automaton -> process
  end
type frame = char list
type sheet = frame list
type run = {
  clock : clock;
  processus : process list;
  sheet : sheet;
  soundtracks : soundtrack list;
}
module SheetParser : sig val initialize : automaton list -> sheet -> run end
val _RUN : run ref
val initialize : automaton list -> sheet -> run
val sheetparser : sheet -> run
val full_sheet : MyString.column list
val sheet : MyString.column list

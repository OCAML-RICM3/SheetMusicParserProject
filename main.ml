(* 
  PROJET : parser de partitions 

  Le projet est incrémental : on propose plusieurs objectifs de plus en plus technique et difficile.
  C'est un guide d'évaluation mais il vous est possible de sauter certain objectif pour s'attaquer aux suivants.

  - 10/20 : transformation de partition en colonne vers une liste triée de sons datés

  - 12/20 : précédent + gestion des fractions de tempo 
             (noire "1" = 1 temps, blanche "1o"=2 temps, ronde "1@" = 4 temps,  croche "."=1/2 temps, double croche ":" = 1/4 de temps, triolet "^" = 1/3 de temps)

  - 14/20 : précédent + transformation de la liste triée de sons datés en une liste d'accords datés
             au lieu de  [ (1.0,"poum") ; (1.0, "wizz") ; (1.2, "crack") ] on regoupe les sons qui doivent être joués simultanément.
             On retourne [ (1.0, ["poum";"wizz"]) ; (1.2, ["crack"]) ]

  - 16/20 : précédent + gestion des données longues entre accolades {}

  - 18/20 : précédent + gestion des répétitions  * nombre [ mesures entre crochets ]

  - 20/20 : précédent + player (graphique) après parsing de la liste triées des accords (façon karaoké)
*)


(* DEBUGGING *)

let _DEBUG_ = true ;;

let (message: string -> unit) = fun string -> if _DEBUG_ then print_string string else () ;;


(* PART 1 -GIVEN- Example of sheet *)

let row_sheet = "R:                                                                                                                                                                                                                                                                                                                                      *4                                                                    \nT:|12345678|12345678|12345678|12345678|12345678|12345678|12345678|12345678|12 .  3         4            5          6       7               8    |12.  3          4        5             6    7         8         |12.     3        4          5           6         7        8        |1      23      45      6          7        8      [123456          7        8      ]12345  6          7        8      |\nV:|        |        |        |        |        |        |        |        |   {I}{know you}{don't get a}{chance to}{take a}{break this of-}{ten}|  {I}{know your}{life is}{speeding and}{any}{thing is}{stopping}|  {here}{take my}{shirt and}{just go a-}{head and}{wipe up}{all the}|{sweat} {sweat} {sweat}{Lose your}{self to}{dance}[     {Lose your}{self to}{dance}]       {Lose your}{self to}{dance}|\nD:|bBbBbBbB|bBbBbBbB|bBbBbBbB|bBbBbBbB|bBbBbBbB|bBbBbBbB|bBbBbBbB|bBbBbBbB|bB    b         B            b          B       b               B    |bB   b          B        b             B    b         B         |bB      b        B          b           B         b        B        |c      Bc      Bc      B          b        B      [bBbBbB          b        B      ]cBcBc  B          b        B      |\nG:|        |        |gggggggg|gggggggg|gggggggg|gggggggg|gggggggg|gggggggg|gg                                                                   |                                                                |                                                                    |                                                  [                                ]                                  |\nJ:|        |        |        |        |        |        |        |        |                                                                     |                                                                |                                                                    |                                                  [                                ]                                  |" ;;

(* PART 2 -GIVEN- Auxilliary functions on list and string *)

(** 2.1 OPERATIONS on LIST **)

module MyList = 
struct

  let (first: int -> 't list -> 't list) = 
    let rec (first_rec: int -> 't list -> 't list) = fun n ts ->
      match ts with
      | [] -> []
      | t::ts -> if n>0 then t::(first_rec (n-1) ts) else []
    in 
    fun n ts -> first_rec n ts

  let rec (safe_zipper: 't -> 't list -> ('t list) list -> ('t list) list) = fun default ts ls ->
    match ts,ls with
    | [],[] -> []
    | [], l::ls -> l::ls  (* (default::l) :: (safe_zipper default [] ls) *)
    | t::ts, [] -> (t::[]) :: (safe_zipper default ts [])
    | t::ts, l::ls -> (t::l) :: (safe_zipper default ts ls)
      
  type 't zipper = 't list -> ('t list) list -> ('t list) list 
    
  let rec (zip_with: 't zipper -> ('t list) list -> ('t list) list) = fun zipper ->
    function
    | [] -> []
    | ts::others -> zipper ts (zip_with zipper others)
  
  let rec (foreach: 'x list -> ('x -> 'y list) -> 'y list) = fun xs f -> 
    match xs with 
    | [] -> []
    | x::others -> (f x) @ (foreach others f)
end

   (** TEST **)
(*
  first 2 [1;2;3;4;5;6] ;;
  MyList.zip_with (MyList.safe_zipper 0) [[1;2;3;4];[5;6;7;8]] ;;
  MyList.zip_with (MyList.safe_zipper 0) [[];[1;2;3;4];[];[5;6;7;8];[];[]] ;;
  MyList.safe_zipper 0 [1] [[1;2;3];[2;3;4];[3;4;5;6]] ;;
*)

(** 2.2 OPERATIONS on STRING: transposition from lines to columns **)

module MyString = 
struct
    
  type line = char list
  type column = char list
    
  let (fold: ('o -> char -> 'o) -> 'o -> string -> 'o) = fun update default string ->
    let rec (fold_rec: int -> 'o -> 'o) = fun i output ->
      try 
        let char = String.get string i in 
          let updated_output = update output char in
            fold_rec (i+1) updated_output 
      with _ -> output
    in fold_rec 0 default
    
  let (to_char_list: string -> char list) = fun string ->
    fold (fun list char -> char::list) [] string
      
  let (to_line_list: string -> line list) = fun string ->
    let lines = 
      match fold (fun (line,lines) char -> if (char = '\n') then ([],(List.rev line)::lines) else (char::line,lines)) ([],[]) string with
      | ([],[]) -> []
      | ([],lines) -> lines
      | (line,lines) -> line::lines
    in (List.rev lines)
    
  let (transpose: line list -> column list) = fun lines ->
    MyList.zip_with (MyList.safe_zipper '%') lines
      
  let (char_list_to_string: char list -> string) = fun chars ->
    let string = String.create (List.length chars) in 
      let rec (char_list_to_string_rec: int -> char list -> string) = fun i ->
        function
        | [] -> string
        | c::cs -> begin String.set string i c ; char_list_to_string_rec (i+1) cs end
      in char_list_to_string_rec 0 chars
       
  let (test_transpose: string -> string) = fun string ->
    let lines = to_line_list string in 
      let columns = transpose lines in 
        String.concat "\n" (List.map char_list_to_string columns)
end

let test = fun () -> print_string (MyString.test_transpose row_sheet) ;;

(* MyString.to_line_list row_sheet ;;
MyString.test_transpose row_sheet ;;
row_sheet ;; *)

(* PART 3 -GIVEN- Labelling of automata transitions *)

(** 3.1 PATTERN instead of SYMBOL on transition **)

type 'a pattern = 
| ANY
| KEY of 'a
| BUT of 'a 
| IN  of 'a list
| OUT of 'a list
    
module Pattern = 
struct 
  type 'a t = 'a pattern
    
  let (exactly: 'a pattern -> 'a -> bool) = fun pattern a -> 
    pattern = KEY a

  let (matches: 'a pattern -> 'a -> bool) = fun pattern a' ->
    match pattern with 
    | ANY -> true
    | KEY a -> a = a'
    | BUT a -> a <> a'
    | IN  aS -> List.mem a' aS
    | OUT aS -> not (List.mem a' aS)
      
  let (pretty: ('a -> string) -> 'a pattern -> string) = fun pp pattern ->
    match pattern with
    | ANY -> "_"
    | KEY a -> pp a
    | BUT a -> "~" ^ (pp a)
    | IN  aS -> "{" ^ (String.concat "," (List.map pp aS)) ^ "}"
    | OUT aS -> "~{" ^ (String.concat "," (List.map pp aS)) ^ "}"
      
  let (print: ('a -> string) -> 'a pattern -> unit) = fun pp pattern -> 
    print_string (pretty pp pattern)
end



(* PART 4 -GIVEN- The output of a parser is a SoundTrack = sequence of timed sound *)

(** 3.1 Clock **)

type clock = float 

module Clock = 
struct
  type date     = float
  type duration = float
  let (initial: date) = 0.0
  let (shift_by: duration -> date -> date) = fun du da -> da +. du
end


(** 3.2 Sound, SoundTrack, Sound In Construction **)

type sound = string
type timed_sound = clock * sound
  
type 't sequence = 't list
type soundtrack = timed_sound sequence 
  
  
type sic = (* Sound In Construction *)
| Nil
| Sic of (clock * string list)
    
module Sound = 
struct

  let (finalize: sic -> soundtrack) = fun sic ->
    match sic with
    | Sic (clock,strings) -> [ (clock, String.concat "" strings) ]
    | Nil                 -> [ ]
      
  let (extend_with: string -> clock -> sic -> sic) = fun string current_clock sic ->
    match sic with
    | Sic (clock,strings) -> Sic (clock, string::strings) 
    | Nil                 -> Sic (current_clock, [string]) 
      
end


(** 3.3 Data stored by each parsing process **)

type data = { clock:clock ; sound: sic ; soundtrack: soundtrack }

module Data = 
struct 

  let (initial: data) = { clock = Clock.initial ; sound = Nil ; soundtrack = [] }

  let (finalize: data -> data) = 
    fun data ->
      { data with
        sound = Nil ; 
        soundtrack = (Sound.finalize data.sound) @ data.soundtrack
      } 
	
  let (get_clock: data -> clock) = fun data -> data.clock

  let (get_soundtrack: data -> soundtrack) = fun data -> ( finalize data ).soundtrack
    
  let (update_clock: clock -> data -> data) = fun clock data ->
    { data with clock = clock }
end


(** 3.4 Symbol: The automata read a sequence of symbol where **)

type symbol = string 


(** 3.5 Actions on data **)

type action = (clock * data * symbol) -> data

module Action = 
struct

    (* USAGE: (increase_clock_by 1.0)  or (increase_clock_by 0.5)  *)

  let (increase_clock_by: Clock.duration -> action) = fun duration -> 
    fun (clock,data,symbol) -> 
      { data with clock = Clock.shift_by duration clock }
	
    (* USAGE: (extend_sound_with "poum" ) *)
	
  let (extend_sound_with: string -> action) = fun string ->
    fun (clock,data,symbol) ->
      { data with sound = Sound.extend_with string clock data.sound }
	
    (* USAGE: finalize_sound *)
	
  let (finalize_sound: action) = 
    fun (clock,data,symbol) ->
      Data.finalize data 
	
    (* USAGE: (make_sound "tchak" ) *)
  (* A vérifier **********************************************)
  let (make_sound: string -> action) = fun string ->
    fun (clock,data,symbol) -> 
      { data with sound = Sic (clock, [string] }
      (*............................................................*)
	
    (* DEFAULT ACTION: update_clock *)
  (* A vérifier **********************************************)
  let (update_clock: action) = 
    fun (clock,data,symbol) -> 
      Data.update_clock clock data
	
  let rec (apply_sequence_of: action sequence -> action) = fun actions ->
    fun (clock,data,symbol) ->
      let data = update_clock (clock,data,symbol) in (* /!\ Il faut commencer par mettre à jour la clock *)
        match actions with
        | [] -> data
        | action::other_actions -> 
          let data'= action (clock,data,symbol) in 
            let clock' = Data.get_clock data' in 
              apply_sequence_of other_actions (clock',data',symbol)
	   
end



(* PART 4 -TODO- Automaton engine *)

(* The automata read a sequence of symbol where: type symbol = string *)

let epsilon = ""

(* type 't sequence = 't list *)

type inputs = symbol sequence

(* A automaton is a graph of transition between nodes where *)

type node = int 

(* A transition between nodes bears a sequence of commands that is controlled by a pattern matching some symbols *)

type transition = node * label * action sequence * node

(* The label of a transition is a pattern that recognizes one or many symbols *)

and label = symbol pattern

(* The graph of the automaton is represented as a collection of transitions *)

type automaton = { name: string ; transitions: transition list }

module Automaton =
struct

  let (initial_node: node) = 1
    
  let (make: string -> transition list -> automaton) = fun name transitions -> 
    { name = name ; transitions = transitions }
      
    (* TODO: get_transition_on *)
      
  (*let (get_transition_on: symbol -> automaton -> node -> transition option) = fun symbol automaton current_node ->
    let enabled_transitions = 
      ............
	...........................................................................................
	.....................
	...
	................................
      |............. -> None 
      |............. -> Some transition*)


  let (install: automaton list -> (string * automaton) list) = fun automata -> List.map (fun aut -> (aut.name,aut)) automata
    
  let (named: string -> (string * automaton) list -> automaton) = fun name automata ->
    List.assoc name automata
end


(* PART 5 -TODO- The automata *)

(** 5.1 the default automaton **)

let adef = Automaton.make "Default" 
  [ (1, ANY , [ Action.update_clock ], 1) ] ;;
 
(** 5.2 Line [T] the tempo parser **)

let digit = List.map string_of_int [0;1;2;3;4;5;6;7;8;9] ;;

let atempo = Automaton.make "Tempo" 
  [ (1, IN digit             , [ Action.increase_clock_by 1.0 ] , 1) 
  ; (1, KEY "."              , [ Action.increase_clock_by 0.5 ] , 1)
  ; (1, IN ["T";":";"|";" "] , [                              ] , 1)
  ] 
;;

(** 5.3 Line [D] the drum parser **)

let adrum = Automaton.make "Drum"
  [ (1, KEY "b"      , [ Action.extend_sound_with "tchak" ], 1) 
  ; (1, KEY "B"      , [ Action.make_sound "Poum"         ], 1) 
  ; (1, OUT ["b";"B"], [ Action.finalize_sound            ], 1)
  ] 
;;

(** 5.4 The repository of automata **)

let _AUTOMATA_ = Automaton.install [ adef ; atempo ; adrum ] ;



(* PART 6 -TODO- The sheet parser *)

(** 6.1 STATE: a state of the execution of an automaton is defined by the current node and the data under construction **)

type state = { node: node ; data: data }

module State = 
struct

    (* initialize *)
  
  let (initial: state) = { node = Automaton.initial_node ; data = Data.initial }
    
    (* get / update *)
    
  let (get_clock: state -> clock)   = fun state -> Data.get_clock state.data
    
  let (get_soundtrack: state -> soundtrack) = fun state -> Data.get_soundtrack state.data
    
  let (update_clock: clock -> state -> state) = fun clock state ->
    { state with data = Data.update_clock clock state.data }

  let (update: (clock * state) -> (symbol * action sequence * node) -> state) = fun (clock,state) (symbol,actions,target_node) ->
    { state with 
      node = target_node ; 
      data = Action.apply_sequence_of actions (clock,state.data,symbol)
    }
end


(** 6.2 Process : a process is a running automatond with a current state **)

type process = { automaton: string ; state: state  }

module Process = 
struct

    (* get / update *)
  
  let (get_clock: process -> clock)   = fun process -> State.get_clock process.state 
    
  let (get_soundtrack: process -> soundtrack) = fun process -> State.get_soundtrack process.state 
    
  let (update_clock: clock -> process -> process) = fun clock process ->
    { process with state = State.update_clock clock process.state }
      
    (* initialize *)
      
  let (initialize: automaton -> process) = fun automaton -> { automaton = automaton.name ; state = State.initial }
    
    (* TODO: one step *)
    
  (*let (one_step_on: symbol -> (clock * process) -> (clock * process)) = fun symbol (clock,process) ->
    .....................................
      ...
      .........................................................................................................
    |........................
    |...................................
  let state' = ...............................................................
  in let clock' = State.get_clock state'
  and process' = .................................
     in (clock', process')*)
     
    (* GIVEN: one step each in parallel *)
     
  (*let (one_step_each_process: symbol list -> (clock * process list) -> (clock * process list)) = 
    
    let rec (one_step_each_tailrec: (clock * process list) -> (symbol list * process list) -> (clock * process list)) = fun (clock, moved_process) (more_symbols,more_process) ->
      match (more_symbols, more_process) with
      | [], [] -> (clock , List.rev (List.map (update_clock clock) moved_process))
      | symbol::other_symbols, process::other_process ->
	let  (clock', process') = one_step_on symbol (clock,process)
	in  one_step_each_tailrec (clock' , process' :: moved_process) (other_symbols,other_process)
    in 
    fun  symbols (clock,processus) -> one_step_each_tailrec (clock,[]) (symbols,processus)*)
      
end


(** 6.3 SheetParser:
   - a sheet parser is a list of processus. Each process is specialized to analyse one line of the sheet. All processus run simultaneously and in synchronization. 
   - a run is defined by the reference clock for all process, the list of process, the remainder of the sheet to read
     when the sheet comes to its end, the soundtracks is filled with the soundtrack of each processus
**)

type frame = char list
type sheet = frame list

type run = { clock: clock ; processus: process list ; sheet: sheet ; soundtracks: soundtrack list }

module SheetParser = 
struct

    (* initialize *)
  
  let (initialize: automaton list -> sheet -> run) = fun automata sheet ->
    { clock = Clock.initial ; 
      processus = List.map Process.initialize automata ; 
      sheet = sheet ; 
      soundtracks = [] 
    } 
      
    (* TO BE COMPLETED: one step*)
      
  (*let (one_step: run -> run) = fun run ->
    match run.sheet with
    | [] -> { run with soundtracks = ............................................. }
    | frame::sheet' -> 
      let symbols = List.map (String.make 1) frame
      in let (clock',processus') = Process.one_step_each_process symbols (run.clock,run.processus)
	 in { run with clock = clock' ; processus = processus' ; sheet = sheet' }*)
end


(* PART 7 -TODO- Demo *)

(** 7.1 Using imperative feature to run the parser STEP BY STEP **)

let _RUN = ref { clock = Clock.initial ; processus = [] ; sheet = [] ; soundtracks = [] } ;;

let (initialize: automaton list -> sheet -> run) = fun automata sheet ->
  begin
    _RUN := SheetParser.initialize automata sheet ;
    !(_RUN)
  end
    
(*let (one_step: unit -> run) = fun () ->
  begin
    _RUN := SheetParser.one_step !(_RUN) ; 
    !(_RUN)
  end*)
    
	  
(** 7.2 The sheet parser is a list of processes that run some automata **)

let sheetparser = initialize [ adef ; atempo ; adef ; adrum ; adef ; adef ] ;;

(** 7.3 Example of sheet in frame  **)

let full_sheet = MyString.transpose (MyString.to_line_list row_sheet) ;;

let sheet = MyList.first 8 full_sheet ;;


(** 7.4 Demo **)

sheetparser sheet ;; (* pour lancer le parser sur la partition *)

(* puis répéter *)

(*one_step () ;;*)  (* lecture d'une frame à la fois *)


(** 7.8 Trace 

Regardez trace.txt pour voir une trace d'exécution du sheetparser.

Notez que l'utilisation dans l'interpréteur caml permet de se passer de fonctions d'impressions.
C'est l'inteprète qui fait l'affichage.

**)


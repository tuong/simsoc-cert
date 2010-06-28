(**
SimSoC-Cert, a library on processor architectures for embedded systems.
See the COPYRIGHTS and LICENSE files.

Formalization of the ARM architecture version 6 following the:

ARM Architecture Reference Manual, Issue I, July 2005.

Page numbers refer to ARMv6.pdf.

Generator of the instruction decoder for Coq.

We must generate 6 decoder functions:
- one decoder for each addressing mode
- one decoder for the instruction

The main function is "decode". Other functions should not be called
directly from outside this file.
*)

open Ast;;
open Printf;;
open Util;;     (* for the "list" function *)
open Codetype;; (* from the directory "refARMparsing" *)


(*****************************************************************************)
(** generate the comment above the pattern *)
(*****************************************************************************)

let comment b (lh: lightheader) =
  let lightheader b (p: lightheader) =
    match p with LH (is, s)
	-> bprintf b "%a - %s" (list "." int) is s
  in
    bprintf b "(*%a*)" lightheader lh;;

(*****************************************************************************)
(** rearrange the name *)
(*****************************************************************************)

(* In the input, each lightheader is named with one long string containing
 * special characters
 * First, we split this string in a list of words.
 * Next:
 * - for addressing modes, the function name is built by concatenating the
 *    words seperated by underscores
 * - for instructions, the function name is built by concatenating the words
 *   directly.
 *)

(*convert the name string to list*)
let str_to_lst s =
  Str.split (Str.regexp "[-:<>() \t]+") s;;

(*organise the input data with different types*)
type kind =
  | Addr_mode of int
  | Inst
  | Encoding;;

(* the string list 'ss' must have been preprocessed by 'name' *)
let add_mode ss =
  match ss with
    | "M1" :: _ -> Addr_mode 1
    | "M2" :: _ -> Addr_mode 2
    | "M3" :: _ -> Addr_mode 3
    | "M4" :: _ -> Addr_mode 4
    | "M5" :: _ -> Addr_mode 5
    | "Encoding" :: _ -> Encoding
    | _ -> Inst;;

(*catch the number of an instruction or of an addressing mode case*)
let num (lh, _) =
  match lh with LH (is, _) -> List.nth is 1;;


(* This function is used by the "params" function *)
(* rename addressing modes*)
let name (ps: maplist_element) =
  (*rename the special cases B,BL and MSR*)
  let name_lst (lh,_) =
    match lh with
      | LH (_, "B, BL") -> ["B"]
      | LH (_, "MSR  Immediate operand:") -> ["MSR"]
      | LH (_, "MSR  Register operand:") -> ["MSR"]
      | LH (_, s) ->
	  str_to_lst s
  in
  let ss = name_lst ps in
    match ss with
      | "Data" :: "processing" :: "operands" :: s -> "M1"::s
      | "Load" :: "and" :: "Store" :: "Word" :: "or" :: "Unsigned" :: "Byte" :: s -> "M2"::s
      | "Miscellaneous" :: "Loads" :: "and" :: "Stores" :: s -> "M3"::s
      | "Load" :: "and" :: "Store" :: "Multiple" :: s -> "M4"::s
      | "Load" :: "and" :: "Store" :: "Coprocessor" :: s -> "M5"::s
      | _ -> ss;; 

(* function used to generate the Coq function name for an addressing mode*)
let id_addr_mode (ps: maplist_element) =
  let rec concatenate = function
    | [] -> ""
    | [s] -> s
    | s :: ss -> s ^ "_" ^ concatenate ss
  in
    concatenate (name ps);;

(* function used to generate the Coq function name for an instruction*)
let id_inst (ps: maplist_element) =
  let rec concatenate = function
    | [] -> ""
    | [s] -> s
    | s :: ss -> s ^ concatenate ss
  in 
    concatenate (name ps);;

(*****************************************************************************)
(** binary list *)
(*****************************************************************************)

(*add the position of element in the array*)
let pos_info (pc: pos_contents array) =
  let ar = Array.create (Array.length pc) (Nothing, 0) in
    for i = 0 to Array.length pc - 1 do
      ar.(i) <- (pc.(i), i)
    done;
    ar;;

(*translate array content to binary and variable.
 * That is to say, we generate the "pattern"
(* The bits are separated by ' *)
 *)
let gen_pattern x =
  let dec b pc =
    match pc with
      | (Value s, _) -> 
	  begin match s with
	    | true -> string b "1"
	    | false -> string b "0"
	  end 
      | (Shouldbe s, i) -> 
	  begin match s with
	    | true -> bprintf b "SBO%d" i 
	    | false -> bprintf b "SBZ%d" i
	  end
      | (Param1 c, _) -> bprintf b "%c_" c (*REMOVE: (Char.escaped c)*)
      | (Param1s s, _) -> bprintf b "%s" s
      | (Range _, _) -> string b "_"
      | (Nothing, _) -> ()
  in
  let aux b =
    let lst = Array.to_list x in
      (list " '" dec) b (List.rev lst)
  in aux;;

(*****************************************************************************)
(** add addressing mode parameter to instructions *)
(*****************************************************************************)

(* return the addressing mode used by the instruction 'm' according to its name and parameters*)
(* m is the name of the instruction *)
(* The fisrt element of an lst element is a parameter name *)
let mode_of_inst (m: string list) (lst: (string*int*int) list) =
  let parameter_names = List.map (fun (s,_,_) -> s) lst in
  let inst_basename = List.hd m in
  let mode3 = ["LDRD";"LDRH";"LDRSB";"LDRSH";"STRD";"STRH"] in
  let mode4 = ["RFE";"SRS"] in
  let mode5 = ["LDC";"STC"] in
    if (List.mem "shifter_operand" parameter_names) then 1
    else if (List.mem "register_list" parameter_names) then 4
    else if (List.mem "addr_mode" parameter_names) then 
      if (List.mem inst_basename mode3) then 3 else 2
    else if (List.mem inst_basename mode4) then 4
    else if (List.mem inst_basename mode5) then 5
    else 0;;

(* add address mode variable in the parameter list*)
(* 'n' is the name of an instruction, represented by a string list *) 
let add_mode_param n lst =
  let md = add_mode n in
  match md with
    | Inst ->
	if (mode_of_inst n lst != 0) then
	  List.append [("add_mode", 0, 0)] lst
	else lst
    | Addr_mode _ | Encoding -> lst;;

(*****************************************************************************)
(** remove unused parameters from instructions and addressing mode cases *)
(*****************************************************************************)

(* Some parameters appears in the encoding but not in the AST.
 * We must remove them.
 *)

(*remove the unused one from the parameter list
 according to addressing mode 'i'*)
let not_param_add_mode i =
  match i with
    | 1 -> ["S_"; "cond"; "d"; "n"; "opcode"]
    | 2 -> ["B_"; "L_"; "d"; "H_"; "S_"]
    | 3 -> ["B_"; "L_"; "d"; "H_"; "S_"]
    | 4 -> ["L_"; "S_"; "CRd"; "N_"; "option"; "i"]
    | 5 -> ["L_"; "S_" ; "CRd"; "N_"; "option"]
    | _ -> [];;

let not_param_inst i =
  match i with
    | 1 -> ["shifter_operand"; "I_"]
    | 2 -> ["P_"; "U_"; "W_"; "addr_mode"; "I_"]
    | 3 -> ["I_"; "P_"; "W_"; "U_"; "n"; "addr_mode"]
    | 4 -> ["P_"; "U_"; "W_"; "n"; "mode"]
    | 5 -> ["8_bit_word_offset"; "CRd"; "P_"; "U_"; "W_"; "N_"; "n"]
    | _ -> [];;

let is_not_param_add_mode i =
  fun (s, _, _) -> List.mem s (not_param_add_mode i);;

let is_not_param_inst i =
  fun (s, _, _) -> List.mem s (not_param_inst i);;

(* 'n' is the instruction or addressing mode case name *)
(* 'lst' is the list of parameters *)
(* This function returns a new parameter list without unused parameters *)
let remove_params n lst = 
  (* We do that in two steps *)
  let remove_params_step1 lst = 
    let md = add_mode n in
      List.map (fun s -> if (
		  match md with
		    | Addr_mode i -> is_not_param_add_mode i s
		    | Inst ->
			let im = mode_of_inst n lst in
			  is_not_param_inst im s
		    | Encoding -> false) then
		  ("",0,0) else s) lst
  in
    (*remove variable in other cases*)
  let remove_params_step2 lst =
    match n with
      (* some addressing mode cases use 'cond' in the AST, and others does not *)
      | ("M2" ::_ :: "offset" :: _ |"M2" ::_ :: _ :: "offset" :: _ | "M3" :: _ :: "offset" :: _) ->
	  List.map (fun (s, i1, i2) -> 
		      if (s = "cond") then ("",0,0) else (s, i1, i2)) lst

      | ("MRC"|"MCR"|"MCRR"|"CDP"|"MRRC")::_ ->
	  List.map (fun (s, i1, i2) -> 
		      if (s = "opcode_1")||(s = "opcode_2")||(s ="CRd")||(s = "CRm")||(s = "CRn")||(s = "opcode") then ("",0,0) else (s, i1, i2)) lst

      | "M5" :: "Unindexed" :: _ ->
	  List.map (fun (s, i1, i2) -> if (s = "U_") then ("",0,0) else (s, i1, i2)) lst

      | "MSR" :: _ -> List.map (fun (s, i1, i2) -> if (s = "field_mask")||(s = "cond")||(s = "m")||(s = "8_bit_immediate")||(s = "rotate_imm")||(s = "R_") then 
				  ("",0,0) else (s, i1, i2)) lst

      | "SWI" :: _ -> List.map (fun (s, i1, i2) -> if (s = "immed_24") then ("",0,0) else (s, i1, i2)) lst

      | ("LDRB"|"STRB"|"LDR"|"STR"|"STRBT"|"LDRT"|"STRT") :: _ -> List.map (fun (s, i1, i2) -> if (s = "n") then ("",0,0) else (s, i1, i2)) lst
      (* PLD is a mode 2 instruction but the AST does not used the mode, so we remove 'add_mode' *)
      | ("PLD") :: _ -> List.map (fun (s, i1, i2) -> if (s = "add_mode")|| (s = "I_")||(s = "U_")||(s = "n")||(s = "addr_mode") then ("",0,0) else (s, i1, i2)) lst

      | _ -> lst
  in
    remove_params_step2 (remove_params_step1 lst);;

(* translate parameters in order to call the defined functions
 to get the required parameter *)
let inst_param ls =
  match ls with
    | (("s" | "m" | "n" | "d" | "dHi" | "dLo"), i, _) ->
	Printf.sprintf "(regnum_from_bit %d w)" i
    | ("cond", _, _) ->	"condition" (*REMOVE:"(condition w)"*)
    | (s, p, l) -> 
	if l > 1 then 
	  Printf.sprintf "w[%d#%d]" (p+l-1) p
	else
	  Printf.sprintf "%s" s
;;

(*keep only one of the same elements in a range*)
(*rerange the data type of instruction parameters with name, position and length*)
let param_m ar =
  let res = Array.create (Array.length ar) ("", 0, 0) in
    for i = 0 to (Array.length ar -1) do
      match ar.(i) with
	| Range (s, len, _) ->
	    if s.[0] = 'R' then
	      res.(i) <- ((String.sub s 1 (String.length s -1)), i, len)
	    else
	      if s = "ImmedL" then
		res.(i) <- ("immedL", i, len)
	      else
		res.(i) <- (s, i, len)
	| (Nothing | Value _ | Shouldbe _) -> 
	    res.(i) <- ("", 0, 0)
	| Param1 c -> 
	    res.(i) <-  ((Printf.sprintf "%s_" (Char.escaped c)), i, 1)
	| Param1s s -> 
	    res.(i) <- (s, i, 1)
    done;
    for i = 0 to (Array.length ar -1) do
    match res.(i) with
      | ("immed", _, _) ->      
	  res.(i) <- ("", 0, 0)
      | ("I", 25, _) -> 
	  res.(i) <- ("", 0, 0)
      | (_, _, len) ->
	  if len > 0 then
	  for j = 1 to len -1 do
	    res.(i + j) <- ("", 0, 0)
	  done;
	  done;
    res;;

(*get the final well typed parameters list*)
let params f (lh, ls) =
  let dname = name (lh,ls) in
  let aux b =
    let lst =
      (List.filter ((<>) "")
	 (List.map inst_param
	    (remove_params dname
	       (add_mode_param dname
		  (List.sort (fun (s1, _, _) (s2, _, _) -> 
				Pervasives.compare s1 s2)
		     (Array.to_list (param_m ls)))))))
    in
      (list " " f) b lst
  in aux;;

(*****************************************************************************)
(** should be one/zero test *)
(*****************************************************************************)

(* FIXME: Actually, the code in this section does nothing *)

(*return SBO with its position*)
let sbo_tst ls =
  match ls with
    | (Shouldbe true, i) -> Printf.sprintf "SBO%d" i
    | ((Nothing | Value _ | Param1 _ | Param1s _ | Range _ | Shouldbe false), _)
      -> "";;

(*return SBZ with its position*)
let sbz_tst ls =
  match ls with
    | (Shouldbe false, i) -> Printf.sprintf "SBZ%d" i
    | ((Nothing | Value _ | Param1 _ | Param1s _ | Range _ | Shouldbe true), _)
      -> "";;

(*insert a test of should be one/zero in decoding*)
let shouldbe_test (lh, ls) =
  (*let lst = Array.to_list ls in
  let ps = Array.to_list (pos_info ls) in
  let sbo = List.filter ((<>) "") (List.map sbo_tst ps) in
  let sbz = List.filter ((<>) "") (List.map sbz_tst ps) in*)
  let aux b =
    (*if ((List.mem (Shouldbe true) lst) && (not (List.mem (Shouldbe false) lst))) then
      bprintf b "if (%a) then\n      DecInst (%s %t)\n      else DecUnpredictable"
	(list "&& " string) sbo (id_inst (lh,ls)) (params string (lh, ls))
    else 
      if (List.mem (Shouldbe false) lst && (not (List.mem (Shouldbe true) lst))) then
	bprintf b "if (not (%a)) then \n      DecInst (%s %t)\n      else DecUnpredictable"
	  (list "&& " string) sbz (id_inst (lh,ls)) (params string (lh, ls))
      else 
	if (List.mem (Shouldbe false) lst && (List.mem (Shouldbe true) lst)) then
	  bprintf b "if ((%a) && (not (%a))) then \n      DecInst (%s %t)\n      else DecUnpredictable"
	 (list "&& " string) sbo (list "&& " string) sbz (id_inst (lh,ls)) (params string (lh, ls))
	else*)
	  bprintf b "%s %t" (id_inst (lh,ls)) (params string (lh, ls))
  in aux;;

(*****************************************************************************)
(** call addressing mode decoder in instruction*)
(*****************************************************************************)

(*call the decode mode function according to the addressing mode*)
let mode_tst (lh, ls) =
  let aux b =
  let lst = Array.to_list (param_m ls) in
  let md = mode_of_inst (name (lh, ls)) lst in
  match md with
    | (1|2|3|4|5 as i) -> bprintf b "decode_cond_mode decode_addr_mode%d w (fun add_mode condition => %t)" i (shouldbe_test (lh, ls))
    | _ -> bprintf b "decode_cond w (fun condition => %t)" (shouldbe_test (lh, ls))
  in aux;;

(*****************************************************************************)
(** constructor for instructions and addressing mode *)
(*****************************************************************************)

let dec_inst b (lh, ls) =
  let dbits = pos_info ls in
    let md = add_mode (name (lh,ls)) in
      match md with
	| Inst -> 
	    bprintf b "    %a\n    | %t =>\n      %t\n"
	      comment lh (gen_pattern dbits) (mode_tst (lh, ls))
	| Encoding -> ()
	| Addr_mode i ->
	    (*FIXME*)
	    if i = 1 || (i = 2 && false) || (i = 3 && false) then
	      bprintf b "    %a\n    | %t =>\n      DecInst (%s %t)\n"
		comment lh (gen_pattern dbits)
		(id_addr_mode (lh, ls)) (params string (lh, ls))
	    else
	      bprintf b "    %a\n    | %t =>\n      decode_cond w (fun condition => %s %t)\n"
		comment lh (gen_pattern dbits)
		(id_addr_mode (lh, ls)) (params string (lh, ls))
;;

(*****************************************************************************)
(** ordering *)
(*****************************************************************************)

(*ordering the instruction and addressing mode for decoder in order to avoid the
 matching reduntancy*)

let sort_add_mode_cases i lst = 
  match i with
    | 1 ->
        (* "Rotate Right with extend" (RRX) must be before "Rotate right by immediate" *)
	let order_ad p =
	  match num p with
	    | 13 -> 0
	    | _ -> 1
	in
	  List.sort (fun a b -> order_ad a - order_ad b) lst
    | _ -> lst;;

(* Numbers in pattern refers to instruction number, i.e.,
 * the subsection in which the instruction is defined *)
let order_inst p =
  match num p with
    | 45|8|59|67|16|90 -> -6 (* instruction without condition *)
    | 84|85|86|87|88|89|129|113|114|115|146|147|148 -> -1 (* instructions without accumulator *)
    | 38|9|10|11|13|39|40 -> 1 (* v5 instructions with SBO or SBZ can hide other v6 instructions *)
    | 25|105|31|101 -> 2 (* loadstore instructions with a 'T' *)
    | 19|20|21|22|26|28|29|30|96|97|98|102|104|35|106|116|117|99|100|23|24|41
        |42|65|18|60|61|2|3|4|6|14|15 -> 3 (* other instuctions with a mode*)
    | _ -> 0;;

(*separate the instruction and address mode data*)
let is_inst l =
  if ((add_mode (name l)) = Inst) then true else false;;

let is_addr_mode i l =
  if ((add_mode (name l)) = Addr_mode i) then true else false;;

(*****************************************************************************)
(** main decoder functions: addressing mode decoder and instruction decoder *)
(*****************************************************************************)

let decode b ps =
  (*print the import require and notations*)
  string b "Require Import Bitvec List Util Functions Config Arm State Semantics ZArith arm6inst Simul Message.\n\nOpen Scope string_scope.\n\nLocal Notation \"0\" := false.\nLocal Notation \"1\" := true.\nLocal Infix \"\'\" := cons (at level 60, right associativity).";

  (*print the decoder of addrss mode 1 - 5*)
  for i = 1 to 5 do
    bprintf b "\n\nDefinition decode_addr_mode%d (w : word) : decoder_result mode%d:=\n match bools_of_word w with\n" i i;
    (list "" dec_inst) b (sort_add_mode_cases i (List.filter (is_addr_mode i) ps));
    bprintf b "    | _ => DecError mode%d NotAnAddressingMode%d\n  end." i i
  done;

  (*print the instruction decoder*)
  bprintf b "\n\nDefinition decode (w : word) : decoder_result inst :=\n  match bools_of_word w with\n";
  (list "" dec_inst) b (List.sort (fun a b -> order_inst a - order_inst b) (List.filter (is_inst) ps));
  bprintf b "    | _ => DecUndefined inst\n  end."
;;

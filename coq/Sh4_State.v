(**
SimSoC-Cert, a Coq library on processor architectures for embedded systems.
See the COPYRIGHTS and LICENSE files.

Formalization of the SH4 architecture following the:

SH-4, Software Manual, Renesas 32-Bit RISC, Rev.6.00 2006.09

Page numbers refer to Renesas_SH4_2006.pdf.

Global state. *)

Set Implicit Arguments.

Require Import Sh4_Proc Sh4 Bitvec List.

Record state : Type := mk_state {
  (* Processor *)
  proc : Sh4_Proc.state
}.

(****************************************************************************)
(** Processor access/update functions *)
(****************************************************************************)


Definition cpsr (s : state) : word := cpsr (proc s).

Definition set_cpsr (s : state) (w : word) : state :=
  mk_state (set_cpsr (proc s) w).

Definition set_cpsr_bit (s : state) (n : nat) (w : word) : state :=
  mk_state (set_cpsr_bit (proc s) n w).

Definition reg_content (s : state) (k : regnum) : word :=
  reg_content (proc s) k.

Definition set_reg (s : state) (k : regnum) (w : word) : state :=
  mk_state (set_reg (proc s) k w).

Definition read (s : state) (a : word) (n : size) : word :=
  repr 0.

Definition address_of_current_instruction (s : state) : word
  := address_of_current_instruction (proc s).
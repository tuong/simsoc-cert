#include "elf_loader.hpp"
#include <iostream>
#include <fstream>

using namespace std;

class MyElfFile : public ElfFile {
  ofstream &ofs;
public:
  MyElfFile(const char* elf_file, ofstream &os): ElfFile(elf_file), ofs(os) {}

  void write_to_memory(const char *data, size_t start, size_t size) {
    for (uint32_t j = 0; j<size; j+=4)
      ofs <<"    | " <<(start+j)/4 <<" => "
          <<reinterpret_cast<const uint32_t*>(data)[j/4] <<'\n';
  }
};

int main(int argc, const char *argv[]) {
  if (argc !=3 ) {
    cerr <<"Convert ELF file (ARM little-endian) to Coq.\n"
         <<"Usage:\n"
         <<argv[0] <<" <elf file> <coq file>\n";
    return 1;
  }
  ofstream ofs(argv[2]);
  MyElfFile elf_file(argv[1],ofs);
  uint32_t initial_pc = elf_file.get_initial_pc();
  const bool thumb = initial_pc&1;
  initial_pc &=~ 1;
  ofs <<dec <<
    "(* Generated by testgen *)\n"
    "\n"
    "Set Implicit Arguments.\n"
    "Require Import ZArith Bitvec Arm_State Arm Util.\n"
    "\n"
    "(* Initial CPSR: " <<(thumb ? "Thumb" : "ARM32") <<" instruction set,"
    " FIQ and IRQ disabled, System mode *)\n"
    "Definition initial_cpsr : word := "
    "repr (Zpos 1~1~1~" <<(thumb ? 1 : 0) <<"~1~1~1~1~1).\n"
    "\n"
    "Definition initial_spsr (m : exn_mode) : word := w0.\n"
    "\n"
    "(* Initial registers: only PC value is significant *)\n"
    "Definition initial_reg (r : register) : word :=\n"
    "  match r with\n"
    "    | R p => if zeq p 15 then repr "
      <<(thumb ? initial_pc+4 : initial_pc+8) <<" else w0\n"
    "    | _ => w0\n"
    "  end.\n"
    "\n";

  ofs <<dec <<"Definition initial_mem_aux (i : Z) : Z :=\n"
      <<"  match i with\n";
  elf_file.load_sections();
  ofs <<"    | _ => 0\n"
      <<"  end.\n"
      <<"Definition initial_mem (a : address) : word := repr (initial_mem_aux (Address.intval a)).\n";

  ofs <<
    "\n"
    "Definition initial_scc_reg (r : regnum) : word := w0.\n"
    "\n"
    "Definition proc_initial_state : Arm_Proc.state :=\n"
    "  Arm_Proc.mk_state initial_cpsr initial_spsr initial_reg nil sys.\n"
    "\n"
    "Definition scc_initial_state : Arm_SCC.state :=\n"
    "  Arm_SCC.mk_state initial_scc_reg initial_mem.\n"
    "\n"
    "Definition initial_state : state :=\n"
    "  mk_state proc_initial_state scc_initial_state.\n";
  ofs.close();
  return 0;
}
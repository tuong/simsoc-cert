// SimSoC-Cert, a library on processor architectures for embedded systems.
// See the COPYRIGHTS and LICENSE files.

// ISS for ARM processors implementing ARM architecture version 6.

// Code for the instructions is generated automatically based on the
// formalization produced by:
// - ../refARMparsing/Makefile
// - ../pseudocode/bin/main -cxx

#ifndef ARM_ISS_BASE_HPP
#define ARM_ISS_BASE_HPP

#include <inttypes.h>
#include <cstdlib>
#include <cassert>

struct ARM_MMU {
  uint8_t read_byte(uint32_t addr);
  uint16_t read_half(uint32_t addr);
  uint32_t read_word(uint32_t addr);
  void write_byte(uint32_t addr, uint8_t data);
  void write_half(uint32_t addr, uint16_t data);
  void write_word(uint32_t addr, uint32_t data);
};

struct ARM_Coprocessor {
  virtual void dependent_operation();
  virtual void load(uint32_t);
  virtual void send(uint32_t);
  virtual bool NotFinished() const;
  virtual uint32_t first_value();
  virtual uint32_t second_value();
  virtual uint32_t value();
};

struct ARM_SystemCoprocessor: ARM_Coprocessor {
  bool get_reg1_EEbit() const;
  bool get_reg1_Ubit() const;
};

struct ARM_Processor {
  // types
  typedef enum {EQ,NE} Condition;
  typedef enum {fiq, irq, svc, abt, und, sys, usr} Mode;

  struct StatusRegister {
    bool N_flag;
    bool Z_flag;
    bool C_flag;
    bool V_flag;
    bool Q_flag;
    bool J_flag;
    bool GE0; // bit 16
    bool GE1;
    bool GE2;
    bool GE3; // bit 19
    bool E_flag;
    bool A_flag;
    bool I_flag;
    bool F_flag;
    bool T_flag;
    Mode mode;
    uint32_t background;
    operator uint32_t ();
    StatusRegister &operator = (uint32_t value);
    void set_GE_32(uint8_t n) {GE2 = n&1; GE3 = n>>1;}
    void set_GE_10(uint8_t n) {GE0 = n&1; GE1 = n>>1;}
  };

  // constants
  static const uint8_t PC = 15;
  static const uint8_t LR = 14;
  static const uint8_t SP = 13;

  // members
  ARM_MMU mmu;
  StatusRegister cpsr;
  ARM_SystemCoprocessor cp15;
  size_t id;

  // methods
  uint32_t &reg(uint8_t reg_id);
  const uint32_t &reg(uint8_t reg_id) const;
  uint32_t &reg(uint8_t reg_id, Mode);
  const uint32_t &reg(uint8_t reg_id, Mode) const;
  bool condition_passed(Condition cond) const;
  void set_pc(uint32_t new_pc); // may set thumb/arm32 mode
  void set_pc_raw(uint32_t new_pc); // never set thumb/arm32 mode
  bool current_mode_has_spsr() const;
  StatusRegister &spsr();
  StatusRegister &spsr(Mode);
  ARM_Coprocessor *coproc(uint8_t cp_num);

  // static methods
  static uint32_t msr_UnallocMask();
  static uint32_t msr_StateMask();
  static uint32_t msr_UserMask();
  static uint32_t msr_PrivMask();
};

struct ARM_ISS_Base {
  ARM_Processor proc;

  bool ConditionPassed(ARM_Processor::Condition cond) const {
    return proc.condition_passed(cond);}
  bool CurrentModeHasSPSR() const {return proc.current_mode_has_spsr();}
  static void unpredictable() {exit(1);}
  uint32_t address_of_next_instruction() const {return proc.reg(ARM_Processor::PC)-4;}
  uint32_t address_of_current_instruction() const {return proc.reg(ARM_Processor::PC)-8;}

  bool InAPrivilegedMode() const {return proc.cpsr.mode!=ARM_Processor::usr;}
  uint32_t TLB(uint32_t virtual_address) const {return virtual_address;}
  bool Shared(uint32_t) const {return false;}
  bool high_vectors_configured();
  size_t ExecutingProcessor() {return proc.id;}
  void MarkExclusiveGlobal(uint32_t, size_t, uint32_t) {}
  void MarkExclusiveLocal(uint32_t, size_t, uint32_t) {}
  void ClearExclusiveByAddress(uint32_t, size_t, uint32_t) {}
  void ClearExclusiveLocal(size_t) {}
  bool IsExclusiveLocal(uint32_t, size_t, uint32_t) const {return true;}
  bool IsExclusiveGlobal(uint32_t, size_t, uint32_t) const {return true;}

  bool not_overridden_by_debug_hardware() {return true;}
  bool JE_bit_of_Main_Configuration_register() {return false;}
  uint32_t jpc_SUB_ARCHITECTURE_DEFINED_value() {return 0;}
  uint32_t invalidhandler_SUB_ARCHITECTURE_DEFINED_value() {return 0;}
  bool Jazelle_Extension_accepts_opcode_at(uint32_t) {return false;}
  bool CV_bit_of_Jazelle_OS_Control_register() {return false;}
  void Start_opcode_execution_at(uint32_t) {}
  bool IMPLEMENTATION_DEFINED_CONDITION() {return false;}

  static void See_Rotate_right_with_extend() {
    assert(false && "Decoding error: ROR instead of RRX");}

  static uint32_t bit_position_of_most_significant_1(uint32_t);
  static bool is_even(uint8_t x) {return !(x&1);}
  static uint32_t Number_Of_Set_Bits_In(uint16_t x);

  static bool CarryFrom8_add2(uint8_t, uint8_t);
  static bool CarryFrom16_add2(uint16_t, uint16_t);
  static bool CarryFrom_add2(uint32_t, uint32_t);
  static bool CarryFrom_add3(uint32_t, uint32_t, bool);
  static bool OverflowFrom_add2(uint32_t, uint32_t);
  static bool OverflowFrom_add3(uint32_t a, uint32_t b, bool) {
    return OverflowFrom_add2(a,b);}
  static bool BorrowFrom_sub2(uint8_t, uint8_t);
  static bool BorrowFrom_sub2(uint16_t, uint16_t);
  static bool BorrowFrom_sub2(uint32_t, uint32_t);
  static bool BorrowFrom_sub3(uint32_t, uint32_t, bool);
  static bool OverflowFrom_sub2(uint32_t, uint32_t);
  static bool OverflowFrom_sub3(uint32_t a, uint32_t b, bool) {
    return OverflowFrom_sub2(a,b);}

  static uint32_t SignExtend_30(uint32_t x) {return x&(1<<23) ? 0x7f000000|x : x;}
  static uint32_t SignExtend16(uint16_t x) {
    return static_cast<uint32_t>(static_cast<int32_t>(static_cast<int16_t>(x)));}
  static uint32_t SignExtend8(uint8_t x) {
    return static_cast<uint32_t>(static_cast<int32_t>(static_cast<int8_t>(x)));}
  static uint32_t ZeroExtend(uint32_t x) {return x;}
  static uint32_t NOT(uint32_t x) {return ~x;}
  static uint32_t NOT(bool x) {return !x;}
  static uint32_t rotate_right(uint32_t x, uint32_t n) {
    return (x<<(32-n)) | (x>>n);}
  static uint32_t asr(uint32_t x, uint32_t n) {
    return static_cast<uint32_t>(static_cast<int32_t>(x)>>n);}
  static uint16_t get_half_0(uint32_t x) {return x;}
  static uint16_t get_half_1(uint32_t x) {return x>>16;}
  static uint8_t get_byte_0(uint32_t x) {return x;}
  static uint8_t get_byte_1(uint32_t x) {return x>>8;}
  static uint8_t get_byte_2(uint32_t x) {return x>>16;}
  static uint8_t get_byte_3(uint32_t x) {return x>>24;}
  static uint32_t get_bits(uint32_t x, uint32_t a, uint32_t b) { // return x[a:b]
    return (x>>b) & ((1<<(a-b))-1);}
  static void set_bit(uint32_t &dst, uint32_t num, bool src) {
    if (src) dst |= (1<<num);
    else dst &=~ (1<<num);
  }
  static void set_bit(uint8_t &dst, uint8_t num, bool src) {
    if (src) dst |= (1<<num);
    else dst &=~ (1<<num);
  }
  static void set_field(uint64_t &dst, size_t num1, size_t num, uint64_t src);
  static void set_field(uint32_t &dst, uint32_t num1, uint32_t num, uint32_t src);
  static void set_field(uint8_t &dst, uint8_t num1, uint8_t num, uint8_t src);

  static uint32_t SignedSat_add32(uint32_t a, uint32_t b);
  static uint32_t SignedSat_sub32(uint32_t a, uint32_t b);
  static uint32_t SignedSat_double32(uint32_t a);
  static bool SignedDoesSat_add32(uint32_t a, uint32_t b);
  static bool SignedDoesSat_sub32(uint32_t a, uint32_t b);
  static bool SignedDoesSat_double32(uint32_t a);

  static uint16_t SignedSat_add16(uint16_t a, uint16_t b);
  static uint16_t SignedSat_sub16(uint16_t a, uint16_t b);
  static uint16_t UnsignedSat_add16(uint16_t a, uint16_t b);
  static uint16_t UnsignedSat_sub16(uint16_t a, uint16_t b);

  static uint8_t SignedSat_add8(uint8_t a, uint8_t b);
  static uint8_t SignedSat_sub8(uint8_t a, uint8_t b);
  static uint8_t UnsignedSat_add8(uint8_t a, uint8_t b);
  static uint8_t UnsignedSat_sub8(uint8_t a, uint8_t b);

  static uint32_t SignedSat(uint32_t a, uint8_t imm);
  static uint32_t UnsignedSat(uint32_t a, uint8_t imm);
  static bool SignedDoesSat(uint32_t a, uint8_t imm);
  static bool UnsignedDoesSat(uint32_t a, uint8_t imm);
};

#endif // ARM_ISS_BASE_HPP

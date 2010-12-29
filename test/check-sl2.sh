#!/bin/bash
SIMLIGHT="../simlight2/simlight -d -i -r0"
set -e # exit on error
set -x # verbose

$SIMLIGHT arm_v6_a.elf -r0=1022
$SIMLIGHT sum_iterative_a.elf -r0=903
$SIMLIGHT sum_recursive_a.elf -r0=903
$SIMLIGHT sum_direct_a.elf -r0=903
$SIMLIGHT arm_blx2_a.elf -r0=0x3
$SIMLIGHT arm_cflag_a.elf -r0=0xf
$SIMLIGHT arm_dpi_a.elf -r0=0x7ffff
$SIMLIGHT arm_edsp_a.elf -r0=0x7fffff
$SIMLIGHT arm_ldmstm_a.elf -r0=0x7
$SIMLIGHT arm_ldrd_strd_a.elf -r0=0xff
$SIMLIGHT arm_ldrstr_a.elf -r0=0x7ffffff
$SIMLIGHT arm_mrs_a.elf -r0=0x7ffff
$SIMLIGHT arm_msr_a.elf -r0=0x1ffff
$SIMLIGHT arm_multiple_a.elf -r0=0x1ff
$SIMLIGHT arm_swi_a.elf -r0=0x3
$SIMLIGHT endian_a.elf -r0=0x7
$SIMLIGHT multiply_a.elf -r0=0xf
$SIMLIGHT simsoc_new1_a.elf -r0=0xff
$SIMLIGHT test_mem_a.elf -r0=0x3
$SIMLIGHT sorting_a.elf -r0=0x3f
$SIMLIGHT sum_iterative_t.elf -r0=903
$SIMLIGHT sum_recursive_t.elf -r0=903
$SIMLIGHT sum_direct_t.elf -r0=903
$SIMLIGHT endian_t.elf -r0=0x7
$SIMLIGHT multiply_t.elf -r0=0xf
$SIMLIGHT simsoc_new1_t.elf -r0=0xff
$SIMLIGHT test_mem_t.elf -r0=0x3
$SIMLIGHT sorting_t.elf -r0=0x3f
$SIMLIGHT thumb_test_t.elf -r0=0x7f
<<<<<<< .mine
$SIMLIGHT test_v6news_a.elf -r0=1023
=======

>>>>>>> .r935

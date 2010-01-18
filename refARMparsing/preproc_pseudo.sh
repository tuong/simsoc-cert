#!/bin/sh

# REMARK: do not remove the last strange -e command !
# due to a strange dash character

sed \
    -e '/^ *[a-zA-Z][a-zA-Z0-9 _(\+)]* = /s|$|;|' \
    -e '/^ *[a-zA-Z][a-zA-Z0-9 _(\+)]*\[[:0-9a-zA-Z_ ,+]*] *= /s|$|;|' \
    -e '/^ *if [a-zA-Z][a-zA-Z0-9 _]* == [a-zA-Z0-9][a-zA-Z0-9 _]*  *then  *[a-zA-Z][]\[a-zA-Z0-9 _]* *= /s|$|;|' \
    -e '/^ *MemoryAccess *(/s|$|;|' \
    -e '/^ *MarkExclusiveLocal *(/s|$|;|' \
    -e '/^ *MarkExclusiveGlobal *(/s|$|;|' \
    -e '/^ *ClearExclusiveByAddress *(/s|$|;|' \
    -e '/^ *ClearExclusiveLocal *(/s|$|;|' \
    -e '/^ *send /s|$|;|' \
    -e '/^ *load /s|$|;|' \
    -e '/^ *Start /s|$|;|' \
    -e '/^ *UNPREDICTABLE/s|$|;|' \
    -e '/^ *Coprocessor/s|$|;|' \
    -e '/^ *assert /s|$|;|' \
    -e 's|\( *//.*\);$|;\1|' \
    -e 's|\( */\*.*\*/\);|;\1|' \
    -e 's|if (\(.*\))$|if (\1) then|' \
    -e 's|^\( *\)if \(.*\)\([0-9)]\)$|\1if \2\3 then|' \
    -e 's|^\( *\)while \(.*\)|\1while \2 do|' \
    -e 's|^\( *\)for \(.*\);|\1for \2 do|' \
    -e 's|-\([A-Za-z]\)| \1|g' \
    -e 's|_usr||g' \
    -e 's|address of|address_of|' \
    -e 's|(\(.*\) is even numbered)|(is_even(\1))|' \
    -e 's|is not R|!= |' \
    -e 's|is R|== |' \
    -e 's|== R|== |' \
    -e 's|value to|to|' \
    -e 's|v5 and above|v5_and_above|' \
    -e 's|architecture version 5 or above|v5_and_above|' \
    -e 's|ARMv5 or above|v5_and_above|' \
    -e 's|v4 and earlier|v4_and_earlier|' \
    -e 's|first value|first_value|' \
    -e 's|second value|second_value|' \
    -e 's|CPSR with|CPSR_with|' \
    -e 's|dependent operation|dependent_operation|' \
    -e 's|SUB ARCHITECTURE|SUBARCHITECTURE|' \
    -e "s|bit position of most significant'1' in Rm|bit_position_of_most_significant_1(Rm)|" \
    -e 's|Start opcode execution at \(.*\);|Start_opcode_execution_at(\1);|' \
    -e 's|coprocessor\[|Coprocessor[|' \
    -e 's|8_bit_immediate|immed_8|' \
    -e 's|^\( *\)If |\1if |' \
    -e 's|Artihmetic|Arithmetic|' \
    -e 's|(diff4]|(diff4)|' \
    -e 's|memory\[|Memory\[|' \
    -e 's|–|-|'

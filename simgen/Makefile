# SimSoC-Cert, a toolkit for generating certified processor simulators
# See the COPYRIGHTS and LICENSE files.

DIR := ..

COQ_INCLUDES := -I $(DIR)/coq

include $(DIR)/Makefile.common

TARGETS := main

default: patch-extraction extraction-libcoq $(TARGETS)

FILES := util ast flatten norm \
	dec gencoqdec genmldec \
	validity gendectest \
	genpc gencoq gencxx_arm6 gencxx_sh4 gencxx \
	codetype lightheadertype syntaxtype \
	c2pc pc2Csyntax Csyntax2coq \
	CompCert_Driver \
	simlight2 sl2_decoder sl2_patch sl2_print sl2_semantics \
	main

$(TARGETS): $(FILES:%=%.ml) lexer.mll parser.mly RawCoq_Csyntax.v # instead of FORCE to call ocamlbuild only when necessary because ocamlbuild is too slow here
	$(SHOW) ocamlbuild simgen/$@
	$(HIDE) $(OCAMLBUILD) simgen/$@.d.byte simgen/$@.native

.PHONY: patch-extraction

patch-extraction: extraction
	$(SHOW) patch extraction/RawCoq_Csyntax.ml
	$(HIDE) awk '/let v_to_list =$$/{printf$$0;getline;printf$$0;getline}{print}' extraction/RawCoq_Csyntax.ml | sed -e 's|let v_to_list =[ ]*Vector.to_list[ ]*n|let v_to_list v = Vector.to_list n v|' > extraction/tmp.ml && mv -f extraction/tmp.ml extraction/RawCoq_Csyntax.ml

extraction.v: libcoq RawCoq_Csyntax.vo

clean::
	rm -f $(TARGETS) RawCoq_Csyntax.glob RawCoq_Csyntax.vo

html: RawCoq_Csyntax.v
	mkdir -p html
	$(COQDOC) RawCoq_Csyntax.v

clean::
	rm -rf html

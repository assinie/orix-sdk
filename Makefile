
all: lib examples


.PHONY: configure lib examples tests docs clean mrproper

configure:
	@$(MAKE) -C asm $@
	@$(MAKE) -C tests $@

lib:
	@$(MAKE) -C asm

examples:
	@$(MAKE) -C examples

docs:
	@$(MAKE) -C docs

tests:
	@$(MAKE) -C asm $@
	@$(MAKE) -C tests $@

clean:
	@$(MAKE) -C asm $@
	@$(MAKE) -C examples $@


mrproper: clean
	@$(MAKE) -C asm $@
	@$(MAKE) -C examples $@


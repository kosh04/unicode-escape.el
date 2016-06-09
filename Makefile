default: clean compile test

include emacs.mk

SRCS := unicode-escape.el

compile: $(SRCS:%.el=%.elc)

test:
	$(CASK) exec $(EMACS_BATCH) \
	-l unicode-escape-test.el \
	-f ert-run-tests-batch-and-exit

clean:
	$(RM) *.elc

.PHONY: compile test clean

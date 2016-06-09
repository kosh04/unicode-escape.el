EMACS ?= emacs
EMACSFLAGS ?= -L .

CASK ?= cask
#CASK := EMACS=$(EMACS) $(CASK)

PACKAGE_DIR := $(shell $(CASK) package-directory)

EMACS_BATCH = $(EMACS) -batch -no-site-file $(EMACSFLAGS)
COMPILE.el = $(CASK) exec $(EMACS_BATCH) -f batch-byte-compile

%.elc: %.el $(PACKAGE_DIR)
	$(COMPILE.el) $<

$(PACKAGE_DIR): Cask
	$(CASK) install
	touch $@

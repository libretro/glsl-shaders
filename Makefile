PREFIX := /usr
INSTALLDIR := $(PREFIX)/share/libretro/shaders/shaders_glsl

all:
	@echo "Nothing to make for glsl-shaders."

install:
	mkdir -p $(DESTDIR)$(INSTALLDIR)
	cp -r ./. $(DESTDIR)$(INSTALLDIR)
	rm -f $(DESTDIR)$(INSTALLDIR)/Makefile
	rm -f $(DESTDIR)$(INSTALLDIR)/configure
	rm -f $(DESTDIR)$(INSTALLDIR)/.gitlab-ci.yml
	rm -rf $(DESTDIR)$(INSTALLDIR)/.git

test-install: all
	DESTDIR=/tmp/build $(MAKE) install

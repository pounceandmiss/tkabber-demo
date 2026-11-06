# Tkabber Makefile

PREFIX = /usr/local
TKABBERDIR = $(PREFIX)/share/tkabber
DOCDIR = $(PREFIX)/share/doc/tkabber
BINDIR = $(PREFIX)/bin

SUBDIRS = emoticons \
	  ifacetk   \
	  msgs      \
	  pixmaps   \
	  plugins   \
	  sounds    \
	  tclxmpp   \
	  tk        \
	  trans     \
	  ttk

all: doc

doc: README doc/tkabber.html

README: doc/tkabber.xml
	DISPLAY= xml2rfc $< -o $@ --text

doc/tkabber.html: doc/tkabber.xml
	DISPLAY= xml2rfc $< -o $@ --html

install: install-bin install-doc install-examples

install-bin:
	install -d $(DESTDIR)$(TKABBERDIR)
	cp -dr --no-preserve=ownership *.tcl $(SUBDIRS) $(DESTDIR)$(TKABBERDIR)
	chmod 755 $(DESTDIR)$(TKABBERDIR)/tkabber.tcl
	chmod 755 $(DESTDIR)$(TKABBERDIR)/tkabber-remote.tcl
	install -d $(DESTDIR)$(BINDIR)
	echo "#!/bin/sh" >$(DESTDIR)$(BINDIR)/tkabber
	echo "exec $(TKABBERDIR)/tkabber.tcl \"\$$@\"" >>$(DESTDIR)$(BINDIR)/tkabber
	echo "#!/bin/sh" >$(DESTDIR)$(BINDIR)/tkabber-remote
	echo "exec $(TKABBERDIR)/tkabber-remote.tcl \"\$$@\"" >>$(DESTDIR)$(BINDIR)/tkabber-remote
	chmod 755 $(DESTDIR)$(BINDIR)/tkabber
	chmod 755 $(DESTDIR)$(BINDIR)/tkabber-remote

install-doc: doc
	install -d $(DESTDIR)$(DOCDIR)
	install -m 644 AUTHORS COPYING ChangeLog README doc/tkabber.html $(DESTDIR)$(DOCDIR)

install-examples:
	install -d $(DESTDIR)$(DOCDIR)
	cp -dr --no-preserve=ownership examples $(DESTDIR)$(DOCDIR)

# Update Tkabber from Fossil repository
up:
	test -f .fslckout -o -f _FOSSIL_ && fossil pull && fossil update
	test -d tclxmpp && cd tclxmpp && \
	    test -f .fslckout -o -f _FOSSIL_ && fossil pull && fossil update

.PHONY: all doc install install-bin install-doc install-examples up

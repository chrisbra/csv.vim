SCRIPT=ftplugin/csv.vim
DOC=doc/ft-csv.txt
PLUGIN=csv
VERSION=$(shell sed -n '/Version:/{s/^.*\(\S\.\S\+\)$$/\1/;p}' $(SCRIPT))
.PHONY : csv.vmb csv


all: vimball

release: $(PLUGIN) $(PLUGIN).vmb

clean:
	find . -type f \( -name "*.vba" -o -name "*.vmb" -o -name "*.orig" \
	-o -name "*.~*" -o -name ".VimballRecord" -o -name ".*.un~" \
	-o -name "*.sw*" -o -name tags \) -delete

dist-clean: clean

vimball: $(PLUGIN).vmb install

install:
	vim -N -u NONE -i NONE -c 'ru! plugin/vimballPlugin.vim' -c 'ru! vimballPlugin.vim' -c':so %' -c':q!' ${PLUGIN}.vmb

uninstall:
	vim -N -u NONE -i NONE -c 'ru! plugin/vimballPlugin.vim' -c 'ru! vimballPlugin.vim' -c':RmVimball ${PLUGIN}.vmb'

undo:
	for i in */*.orig; do mv -f "$$i" "$${i%.*}"; done

csv.vmb:
	vim -N -u NONE -i NONE -c 'ru! plugin/vimballPlugin.vim' -c ':let g:vimball_home=getcwd()'  -c ':call append("0", ["ftplugin/csv.vim", "doc/ft-csv.txt", "syntax/csv.vim", "ftdetect/csv.vim", "plugin/csv.vim"])' -c '$$d' -c ':%MkVimball! ${PLUGIN}' -c':q!'
	ln -f $(PLUGIN).vmb $(PLUGIN)-$(VERSION).vmb

csv:
	rm -f ${PLUGIN}.vmb
	perl -i.orig -pne 'if (/Version:/) {s/\.(\d+)*/sprintf(".%d", 1+$$1)/e}' ${SCRIPT}
	perl -i -pne 'if (/GetLatestVimScripts:/) {s/(\d+)\s+:AutoInstall:/sprintf("%d :AutoInstall:", 1+$$1)/e}' ${SCRIPT}
	perl -i -pne 'if (/Last Change:/) {s/(:\s+).*\n$$/sprintf(": %s", `date -R`)/e}' ${SCRIPT}
	perl -i -pne 'if (/Last Change:/) {s/(:\s+).*\n$$/sprintf(": %s", `LC_TIME=C date +"%a, %d %b %Y"`)/e}' ${DOC}
	perl -i.orig -pne 'if (/Version:/) {s/\.(\d+).*/sprintf(".%d", 1+$$1)/e}' ${DOC}
	cp -f $(DOC) README

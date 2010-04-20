SCRIPT=ftplugin/csv.vim
DOC=doc/ft_csv.txt
PLUGIN=csv


all: $(PLUGIN) $(PLUGIN).vba

clean:
	rm -rf *.vba */*.orig *.~* .VimballRecord doc/tags

dist-clean: clean

vimball: $(PLUGIN).vba

install:
	vim -u NONE -N -c':so' -c':q!' ${PLUGIN}.vba

uninstall:
	vim -u NONE -N -c':RmVimball ${PLUGIN}.vba'

undo:
	for i in */*.orig; do mv -f "$$i" "$${i%.*}"; done

csv.vba:
	vim -N -c 'ru! vimballPlugin.vim' -c ':let g:vimball_home=getcwd()'  -c ':call append("0", ["ftplugin/csv.vim", "doc/ft_csv.txt"])' -c '$$d' -c ':%MkVimball ${PLUGIN}' -c':q!'

csv:
	rm -f ${PLUGIN}.vba
	perl -i.orig -pne 'if (/Version:/) {s/\.(\d)*/sprintf(".%d", 1+$$1)/e}' ${SCRIPT}
	perl -i -pne 'if (/GetLatestVimScripts:/) {s/(\d+)\s+:AutoInstall:/sprintf("%d :AutoInstall:", 1+$$1)/e}' ${SCRIPT}
	perl -i -pne 'if (/Last Change:/) {s/(:\s+).*$$/sprintf(": %s", `date -R`)/e}' ${SCRIPT}
	perl -i.orig -pne 'if (/Version:/) {s/\.(\d)+.*\n/sprintf(".%d %s", 1+$$1, `date -R`)/e}' ${DOC}

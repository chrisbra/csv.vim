" A simple syntax highlighting, simply alternate colors between two
" adjacent columns
if version < 600
    syn clear
elseif exists("b:current_syntax")
    finish
endif

syn spell toplevel

" Not really needed
syn case ignore

hi CSVColumnOdd	ctermfg=0 ctermbg=6 guibg=grey80 guifg=black
hi CSVColumnEven ctermfg=0 ctermbg=8 guibg=grey50 guifg=black
exe 'synt match CSVColumnOdd nextgroup=CSVColumnEven excludenl /'
	    \ . b:col . '/'
exe 'synt match CSVColumnEven nextgroup=CSVColumnOdd excludenl /'
	    \ . b:col . '/'


let b:current_syntax="csv"

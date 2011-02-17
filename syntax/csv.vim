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

hi CSVColumnOdd	ctermfg=0 ctermbg=6 guibg=grey80 guifg=black term=underline cterm=underline gui=underline
hi CSVColumnEven ctermfg=0 ctermbg=8 guibg=grey50 guifg=black term=underline cterm=underline gui=underline
hi CSVColumnHeaderOdd ctermfg=0 ctermbg=6 guibg=grey80 guifg=black cterm=underline gui=bold,underline
hi CSVColumnHeaderEven ctermfg=0 ctermbg=8 guibg=grey50 guifg=black cterm=underline gui=bold,underline

if has("conceal")
    exe "syn match CSVDelimiter /" . b:delimiter . "/ contained conceal cchar=│"
    hi def link CSVDelimiter Conceal
else
    exe "syn match CSVDelimiter /" . b:delimiter . "/ contained"
    hi def link CSVDelimiter Ignore
endif
" Last match is prefered.
exe 'syn match CSVColumnEven nextgroup=CSVColumnOdd excludenl /'
	    \ . b:col . '/ contains=CSVDelimiter'
exe 'syn match CSVColumnOdd nextgroup=CSVColumnEven excludenl /'
	    \ . b:col . '/ contains=CSVDelimiter'

exe 'syn match CSVColumnHeaderEven nextgroup=CSVColumnHeaderOdd excludenl /\%1l' . b:col . '/ contains=CSVDelimiter'

exe 'syn match CSVColumnHeaderOdd nextgroup=CSVColumnHeaderEven excludenl /\%1l' . b:col . '/ contains=CSVDelimiter'



let b:current_syntax="csv"

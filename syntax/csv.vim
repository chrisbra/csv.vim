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

" Check for filetype plugin. This syntax script relies on the filetype plugin,
" else, it won't work properly.
redir => a |sil filetype | redir end
let a=split(a, "\n")[0]
if match(a, '\cplugin:off') > 0
    echohl WarningMsg
    echomsg "CSV Syntax: No filetype support, only simple highlighting!" 
    echomsg "See :h csv-installation"
    echohl Normal
    " Try a simple highlighting and use the comma as separator
    let del = ','
    let col='\%([^,]*,\|$\)'
    let col='\%([^' . del . ']*' . del . '\|$\)'
else
    let col = b:col
    let del = b:delimiter
endif

if has("conceal")
    exe "syn match CSVDelimiter /" . del . "/ contained conceal cchar=│"
    hi def link CSVDelimiter Conceal
else
    exe "syn match CSVDelimiter /" . del . "/ contained"
    hi def link CSVDelimiter Ignore
endif


" Last match is prefered.
exe 'syn match CSVColumnEven nextgroup=CSVColumnOdd excludenl /'
	    \ . col . '/ contains=CSVDelimiter'
exe 'syn match CSVColumnOdd nextgroup=CSVColumnEven excludenl /'
	    \ . col . '/ contains=CSVDelimiter'

exe 'syn match CSVColumnHeaderEven nextgroup=CSVColumnHeaderOdd excludenl /\%1l'
	    \. col . '/ contains=CSVDelimiter'

exe 'syn match CSVColumnHeaderOdd nextgroup=CSVColumnHeaderEven excludenl /\%1l'
	    \. col . '/ contains=CSVDelimiter'



let b:current_syntax="csv"

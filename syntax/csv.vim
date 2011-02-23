" A simple syntax highlighting, simply alternate colors between two
" adjacent columns
scriptencoding utf8
if version < 600
    syn clear
elseif exists("b:current_syntax")
    finish
endif

syn spell toplevel

" Not really needed
syn case ignore

hi CSVColumnOdd  ctermfg=0 ctermbg=6 guibg=grey80 guifg=black 
\ term=underline cterm=underline gui=underline
hi CSVColumnEven ctermfg=0 ctermbg=8 guibg=grey50 guifg=black
\ term=underline cterm=underline gui=underline
hi CSVColumnHeaderOdd ctermfg=0 ctermbg=6 guibg=grey80 guifg=black
\ cterm=underline gui=bold,underline
hi CSVColumnHeaderEven ctermfg=0 ctermbg=8 guibg=grey50 guifg=black
\ cterm=underline gui=bold,underline

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

if has("conceal") && !exists("g:csv_noconceal")
    exe "syn match CSVDelimiter /" . col . 
    \ '\%(.\)\@=/ms=e,me=e contained conceal cchar=' .
    \ (&enc == "utf-8" ? "│" : '|')
    exe "syn match CSVDelimiterEOL /" . del . 
    \ '$/ contained conceal cchar=' .
    \ (&enc == "utf-8" ? "│" : '|')
    hi def link CSVDelimiter Conceal
    hi def link CSVDelimiterEOL Conceal
else
    " The \%(.\)\@= make sure, the last char won't be concealed,
    " if it isn't a delimiter
    exe "syn match CSVDelimiter /" . col . '\%(.\)\@=/ms=e,me=e contained'
    exe "syn match CSVDelimiterEOL /" . del . 
    \ '$/ contained'
    hi def link CSVDelimiter Ignore
endif


" Last match is prefered.

exe 'syn match CSVColumnEven nextgroup=CSVColumnOdd /'
	    \ . col . '/ contains=CSVDelimiter,CSVDelimiterEOL'
exe 'syn match CSVColumnOdd nextgroup=CSVColumnEven /'
	    \ . col . '/ contains=CSVDelimiter,CSVDelimiterEOL'

exe 'syn match CSVColumnHeaderEven nextgroup=CSVColumnHeaderOdd /\%1l'
	    \. col . '/ contains=CSVDelimiter,CSVDelimiterEOL'
exe 'syn match CSVColumnHeaderOdd nextgroup=CSVColumnHeaderEven /\%1l'
	    \. col . '/ contains=CSVDelimiter,CSVDelimiterEOL'

let b:current_syntax="csv"

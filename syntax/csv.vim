" A simple syntax highlighting, simply alternate colors between two
" adjacent columns
" Init {{{2
scriptencoding utf8
if version < 600
    syn clear
elseif exists("b:current_syntax")
    finish
endif

" Helper functions "{{{2
fu! <sid>Warning(msg) "{{{3
    redraw!
    echohl WarningMsg
    echomsg "CSV Syntax:" . a:msg
    echohl Normal
endfu

fu! <sid>CheckSaneSearchPattern() "{{{3
    " Sane defaults ?
    let s:del_def = ','
    let s:col_def = '\%([^' . s:del_def . ']*' . s:del_def . '\|$\)'

    " Try a simple highlighting, if the defaults from the ftplugin
    " don't exist
    let s:col = exists("b:col") && !empty("b:col") ? b:col
		\ : s:col_def
    let s:del = exists("b:delimiter") && !empty("b:delimiter") ? b:delimiter
		\ : s:del_def
    try
	let _p = getpos('.')
	let _s = @/ 
	exe "sil norm! /" . b:col . "\<CR>"
    catch
	" check for invalid pattern, for simplicity,
	" we catch every exception
	let s:col = s:col_def
	let s:del = s:del_def
	call <sid>Warning("Invalid column pattern, using default pattern " .
		    \ s:col_def)
    finally
	let @/ = _s
	call setpos('.', _p)
    endtry
endfu

" Syntax rules {{{2
syn spell toplevel

" Not really needed
syn case ignore

if &t_Co < 88
    hi CSVColumnHeaderOdd ctermfg=DarkRed ctermbg=15 guibg=grey80 guifg=black term=underline cterm=standout,bold gui=bold,underline 
    hi CSVColumnOdd	  ctermfg=DarkRed ctermbg=15 guibg=grey80 guifg=black term=underline cterm=bold gui=underline
else
    hi CSVColumnHeaderOdd ctermfg=darkblue ctermbg=white guibg=grey80 guifg=black cterm=standout,underline gui=bold,underline
    hi CSVColumnOdd       ctermfg=darkblue ctermbg=white guibg=grey80 guifg=black cterm=reverse,underline gui=underline
endif
    
" ctermbg=8 should be safe, even in 8 color terms
hi CSVColumnHeaderEven    ctermfg=white ctermbg=darkgrey guibg=grey50 guifg=black term=bold cterm=standout,underline gui=bold,underline 
hi CSVColumnEven	  ctermfg=white ctermbg=darkgrey guibg=grey50 guifg=black term=bold cterm=underline gui=bold,underline 

" Make sure, we are using a sane, valid pattern for syntax
" highlighting
call <sid>CheckSaneSearchPattern()

" Check for filetype plugin. This syntax script relies on the filetype plugin,
" else, it won't work properly.
redir => s:a |sil filetype | redir end
let s:a=split(s:a, "\n")[0]
if match(s:a, '\cplugin:off') > 0
    call <sid>Warning("No filetype support, only simple highlighting using\n" .
		\ s:del_def . " as delimiter! See :h csv-installation")
endif

if has("conceal") && !exists("g:csv_no_conceal")
    exe "syn match CSVDelimiter /" . s:col . 
	\ '\%(.\)\@=/ms=e,me=e contained conceal cchar=' .
	\ (&enc == "utf-8" ? "│" : '|')
    exe "syn match CSVDelimiterEOL /" . s:del . 
	\ '$/ contained conceal cchar=' .
	\ (&enc == "utf-8" ? "│" : '|')
    hi def link CSVDelimiter Conceal
    hi def link CSVDelimiterEOL Conceal
else
    " The \%(.\)\@= makes sure, the last char won't be concealed,
    " if it isn't a delimiter
    exe "syn match CSVDelimiter /" . s:col . '\%(.\)\@=/ms=e,me=e contained'
    exe "syn match CSVDelimiterEOL /" . s:del . '$/ contained'
    hi def link CSVDelimiter Ignore
    hi def link CSVDelimiterEOL Ignore
endif

" Last match is prefered.

exe 'syn match CSVColumnEven nextgroup=CSVColumnOdd /'
	    \ . s:col . '/ contains=CSVDelimiter,CSVDelimiterEOL'
exe 'syn match CSVColumnOdd nextgroup=CSVColumnEven /'
	    \ . s:col . '/ contains=CSVDelimiter,CSVDelimiterEOL'

exe 'syn match CSVColumnHeaderEven nextgroup=CSVColumnHeaderOdd /\%1l'
	    \. s:col . '/ contains=CSVDelimiter,CSVDelimiterEOL'
exe 'syn match CSVColumnHeaderOdd nextgroup=CSVColumnHeaderEven /\%1l'
	    \. s:col . '/ contains=CSVDelimiter,CSVDelimiterEOL'

let b:current_syntax="csv"

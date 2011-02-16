" Filetype plugin for editing CSV files. "{{{1
" Author:  Christian Brabandt <cb@256bit.org>
" Version: 0.7
" Script:  http://www.vim.org/scripts/script.php?script_id=2830
" License: VIM License
" Last Change: Wed, 16 Feb 2011 23:24:37 +0100
" Documentation: see :help ft_csv.txt
" GetLatestVimScripts: 2830 6 :AutoInstall: csv.vim
"
" Some ideas are take from the wiki http://vim.wikia.com/wiki/VimTip667
" though, implementation differs.

" Plugin folclore "{{{2
if v:version < 700 || exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

" Function definitions: "{{{2
fu! <SID>Warn(mess) "{{{3
    echohl WarningMsg
    echomsg "CSV: " . a:mess
    echohl Normal
endfu

fu! <SID>Init() "{{{3
    " Hilight Group for Columns
    if exists("g:csv_hiGroup")
	let s:hiGroup = g:csv_hiGroup
    else
	let s:hiGroup="WildMenu"
    endif
    " Determine default Delimiter
    if !exists("g:csv_delim")
	let b:delimiter=<SID>GetDelimiter()
    else
	let b:delimiter=g:csv_delim
    endif
    if empty(b:delimiter)
	call <SID>Warn("No delimiter found. See :h csv-delimiter to set it manually!")
    endif
    
    " Pattern for matching a single column
    let b:col='\%(\%([^' . b:delimiter . ']*"[^"]*"[^' . 
		\ b:delimiter . ']*' . b:delimiter . '\)\|\%([^' . 
		\ b:delimiter . ']*\%(' . b:delimiter . '\|$\)\)\)'

    " define buffer-local commands
    call <SID>CommandDefinitions()
    " CSV specific mappings
    call <SID>CSVMappings()

    " force reloading CSV Syntax Highlighting
    if exists("b:current_syntax")
	unlet b:current_syntax
	" Force reloading syntax file
	exe "silent do Syntax" expand("%")
    endif

    " undo when setting a new filetype
    let b:undo_ftplugin = "setlocal sol< tw< wrap<"
	\ . "| unlet b:delimiter b:col"
    " CSV local settings
    setl nostartofline tw=0 nowrap
endfu 

fu! <SID>SearchColumn(arg) "{{{3
    let arglist=split(a:arg)
    let colnr=arglist[0]
    let pat=substitute(arglist[1], '^\(.\)\(.*\)\1$', '\2', '')
    let maxcolnr = <SID>MaxColumns()
    if colnr > maxcolnr
	call <SID>Warn("There exists no column " . colnr)
	return 1
    endif
    "let @/=<SID>GetColPat(colnr) . '*\zs' . pat . '\ze\([^' . b:delimiter . ']*' . b:delimiter .'\)\?' . <SID>GetColPat(maxcolnr-colnr-1)
    " GetColPat(nr) returns a pattern containing '\zs' if nr > 1,
    " therefore, we need to clear that flag again ;(
    " TODO:
    " Is there a better way, than running a substitute command on '\zs', may be using a flag
    " with GetColPat(zsflag, colnr)?
    if colnr > 1
	"let @/=<SID>GetColPat(colnr-1,0) . '*\zs' . pat . '\ze\([^' . b:delimiter . ']*' . b:delimiter .'\)\?' . <SID>GetColPat(maxcolnr-colnr-1,0)
	"let @/= '^' . <SID>GetColPat(colnr-1,0) . '[^' . b:delimiter . ']*\zs' . pat . '\ze[^' . b:delimiter . ']*'.b:delimiter . <SID>GetColPat(maxcolnr-colnr,0) . '$'
	"let @/= '^' . <SID>GetColPat(colnr-1,0) . b:col1 . '\?\zs' . pat . '\ze' . b:col1 .'\?' . <SID>GetColPat(maxcolnr-colnr,0) " . '$'
	let @/= '^' . <SID>GetColPat(colnr-1,0) . '\%([^' . b:delimiter .']*\)\?\zs' . pat . '\ze' . '\%([^' . b:delimiter .']*\)\?' . b:delimiter . <SID>GetColPat(maxcolnr-colnr,0)  . '$'
    else
	"let @/= '^\zs' . pat . '\ze' . substitute((<SID>GetColPat(maxcolnr - colnr)), '\\zs', '', 'g')
	"let @/= '^\zs' . b:col1 . '\?' . pat . '\ze' . b:col1 . '\?' .  <SID>GetColPat(maxcolnr,0) . '$'
	let @/= '^' . '\%([^' . b:delimiter . ']*\)\?\zs' . pat . '\ze\%([^' . b:delimiter . ']*\)\?' . b:delimiter .  <SID>GetColPat(maxcolnr-1,0) . '$'
    endif
    norm! n
endfu

fu! <SID>DelColumn(colnr) "{{{3
    let maxcolnr = <SID>MaxColumns()
    if a:colnr > maxcolnr
	call <SID>Warn("There exists no column " . a:colnr)
	return 
    endif

    if empty(a:colnr)
       let colnr=<SID>WColumn()
    else
       let colnr=a:colnr
    endif

    if a:colnr != '1'
	let pat= '^' . <SID>GetColPat(a:colnr-1,1) . b:col
    else
	let pat= '^' . <SID>GetColPat(a:colnr,0) 
    endif
    exe ':%s/' . escape(pat, '/') . '//'
endfu

fu! <SID>HiCol(colnr) "{{{3
    if a:colnr > <SID>MaxColumns()
	call <SID>Warn("There exists no column " . a:colnr)
	return
    endif
    if empty(a:colnr)
       let colnr=<SID>WColumn()
    else
       let colnr=a:colnr
    endif

    if colnr==1
	let pat='^'. <SID>GetColPat(colnr,0)
    else
	let pat='^'. <SID>GetColPat(colnr-1,1) . b:col
    endif

    if exists("*matchadd")
	if exists("s:matchid")
	   " ignore errors, that come from already deleted matches
	   sil! call matchdelete(s:matchid)
	endif
	" Additionally, filter all matches, that could have been used earlier
	let matchlist=getmatches()
	call filter(matchlist, 'v:val["group"] !~ s:hiGroup')
	call setmatches(matchlist)
	let s:matchid=matchadd(s:hiGroup, pat, 0)
    else
        exe ":2match " . s:hiGroup . ' /' . pat . '/'
    endif
endfu

fu! <SID>GetDelimiter() "{{{3
    let _cur = getpos('.')
    let Delim={0: ';', 1:  ','}
    let temp={}
    for i in  values(Delim)
	redir => temp[i]
	    exe "silent! %s/" . i . "/&/nge"
	redir END
    endfor
    let Delim = map(temp, 'matchstr(substitute(v:val, "\n", "", ""), "^\\d\\+")')

    let result=[]
    for [key, value] in items(Delim)
	if get(result,0) < value
	    call add(result, key)
	    call add(result, value)
	endif
    endfor
    call setpos('.', _cur)
    if !empty(result)
	return result[0]
    else
	return ''
    endif
endfu

fu! <SID>WColumn() "{{{3
    " Return on which column the cursor is
    let _cur = getpos('.')
    let line=getline('.')
    " move cursor to end of field
    call search(b:col, 'ec', line('.'))
    let end=col('.')-1
    let fields=(split(line[0:end],b:col.'\zs'))
    call setpos('.',_cur)
    return len(fields)
endfu 

fu! <SID>MaxColumns() "{{{3
    "return maximum number of columns in first 10 lines
    let l=getline(1,10)
    let fields=[]
    let result=0
    for item in l
	let temp=len(split(item, b:col.'\zs'))
	let result=(temp>result ? temp : result)
    endfor
    return result
endfu

fu! <SID>ColWidth(colnr) "{{{3
    " Return the width of a column
    let list=getline(1,'$')
    let width=20 "Fallback (wild guess)
    try
	" we have a list of the first 10 rows
	" Now transform it to a list of field a:colnr
	" and then return the maximum strlen
	" That could be done in 1 line, but that would look ugly
	call map(list, 'split(v:val, b:col."\\zs")[a:colnr-1]')
	call map(list, 'substitute(v:val, ".", "x", "g")')
	call map(list, 'strlen(v:val)')
	return max(list)
    catch
        return  width
    endtry
endfu

fu! <SID>ArrangeCol() range "{{{3
    let _cur=getpos('.')
    " Force recalculation of Column width
    if exists("b:col_width")
      unlet b:col_width
    endif

   exe ':%s/' . (b:col) . '/\=<SID>Columnize(submatch(0))/g'
   call setpos('.', _cur)
endfu

fu! <SID>Columnize(field) "{{{3
   if !exists("b:col_width")
	let b:col_width=[]
	let max_cols=<SID>MaxColumns()
	for i in range(1,max_cols)
	    call add(b:col_width, <SID>ColWidth(i))
	endfor
   endif
   " convert zero based indexed list to 1 based indexed list,
   " Default: 20 width, in case that column width isn't defined
   let width=get(b:col_width,<SID>WColumn()-1,20)
   let a = split(a:field, '\zs')
   let add = eval(join(map(a, 'len(v:val)'), '+'))
   let add -= len(a)
   
   " Add one for the frame
   " plus additional width for multibyte chars,
   " since printf(%*s..) uses byte width!
   let width = width + add  + 1

   return printf("%*s", width ,  a:field)
endfun

fu! <SID>GetColPat(colnr, zs_flag) "{{{3
    if a:colnr > 1
	let pat=b:col . '\{' . (a:colnr) . '\}' 
    else
        let pat=b:col 
    endif
    return pat . (a:zs_flag ? '\zs' : '')
endfu

fu! <SID>SplitHeaderLine(lines, bang) "{{{3
    if !a:bang && !exists("b:CSV_SplitWindow")
	" Split Window
	let _stl = &l:stl
	let _sbo = &sbo
	setl scrollopt=hor scrollbind
	let lines = empty(a:lines) ? 1 : a:lines
	noa sp
	1
	exe "resize" . lines
	setl scrollopt=hor scrollbind winfixheight
	"let &l:stl=repeat(' ', winwidth(0))
	let &l:stl="%#Normal#".repeat(' ',winwidth(0))
	" Highlight first row
	call matchadd("Type", b:col)
	let b:CSV_SplitWindow = winnr()
	exe "noa wincmd p"
    else
	" Close split window
	if !exists("b:CSV_SplitWindow")
	    return
	endif
	exe "noa" b:CSV_SplitWindow "wincmd w"
	unlet b:CSV_SplitWindow
	if exists("_stl")
	    let &l_stl = _stl
	endif
	if exists("_sbo")
	    let &sbo = _sbo
	endif
	setl noscrollbind
	wincmd c
    endif
endfu

fu! <SID>MoveCol(forward, line) "{{{3
    let colnr=<SID>WColumn()
    let maxcol=<SID>MaxColumns()

    " Check for valid column
    " a:forward == 1 : search next col
    " a:forward == -1: search prev col
    " a:forward == 0 : stay in col
    if colnr - v:count1 >= 1 && a:forward == -1
	let colnr -= v:count1
    elseif colnr - v:count1 < 1 && a:forward == -1
	let colnr = 0
    elseif colnr + v:count1 <= <SID>MaxColumns() && a:forward == 1
	let colnr += v:count1
    elseif colnr + v:count1 > <SID>MaxColumns() && a:forward == 1
	let colnr = maxcol + 1
    endif

    let line=a:line
    if line < 1
	let line=1
    elseif line > line('$')
	let line=line('$')
    endif

    " Generate search pattern
    if colnr == 1
	let pat = '^' . <SID>GetColPat(colnr-1,0) 
	let pat = pat . '\%' . line . 'l'
    elseif colnr == 0
	let pat = '^' . '\%' . line . 'l'
    elseif colnr == maxcol + 1
	let pat='\%' . line . 'l$'
    else
	let pat='^'. <SID>GetColPat(colnr-1,1) . b:col
	let pat = pat . '\%' . line . 'l'
    endif

    " Search
    if a:forward > 0
	call search(pat, 'cW')
    elseif a:forward < 0
	call search(pat, 'bWe')
    else
	call search(pat, 'c')
    endif
endfun

fu! <SID>SortComplete(A,L,P) "{{{3
    return join(range(1,<sid>MaxColumns()),"\n")
endfun 

fu! <SID>Sort(bang, colnr) range "{{{3
    if a:colnr != '1'
	let pat= '^' . <SID>GetColPat(a:colnr-1,1) . b:col
    else
	let pat= '^' . <SID>GetColPat(a:colnr,0) 
    endif
    exe ":sort" . (a:bang ? '!' : '') . ' r /' . pat . '/'
endfun

fu! CSV_WCol() "{{{3
    return printf(" %d/%d", <SID>WColumn(), <SID>MaxColumns())
endfun

fu! <SID>CommandDefinitions() "{{{3
    if !exists(":WhatColumn")
	command! -buffer WhatColumn :echo <SID>WColumn()
    endif
    if exists(":NrColumns")
	command! -buffer NrColumns :echo <SID>MaxColumns()
    endif
    if !exists(":HiColumn")
	command! -buffer -nargs=? HiColumn :call <SID>HiCol(<q-args>)
    endif
    if !exists(":SearchInColumn")
	command! -buffer -nargs=* SearchInColumn :call <SID>SearchColumn(<q-args>)
    endif
    if !exists(":DeleteColumn")
	command! -buffer -nargs=? DeleteColumn :call <SID>DelColumn(<args>)
    endif
    if !exists(":ArrangeColumn")
	command! -buffer ArrangeColumn :call <SID>ArrangeCol()
    endif
    if !exists(":InitCSV")
	command! -buffer InitCSV :call <SID>Init()
    endif
    if !exists(":Header")
	command! -buffer -bang -nargs=? Header :call <SID>SplitHeaderLine(<q-args>,<bang>0)
    endif
    if !exists(":Sort")
	command! -buffer -nargs=1 -bang -range=% -complete=custom,<SID>SortComplete Sort :<line1>,<line2>call <SID>Sort(<bang>0,<args>)
    endif
endfu

fu! <SID>CSVMappings() "{{{3
    nnoremap <silent> <buffer> W :<C-U>call <SID>MoveCol(1, line('.'))<CR>
    nnoremap <silent> <buffer> E :<C-U>call <SID>MoveCol(-1, line('.'))<CR>
    nnoremap <silent> <buffer> K :<C-U>call <SID>MoveCol(0, line('.')-v:count1)<CR>
    nnoremap <silent> <buffer> J :<C-U>call <SID>MoveCol(0, line('.')+v:count1)<CR>
    " Map C-Right and C-Left as alternative to W and E
    nmap <silent> <buffer> <C-Right> W
    nmap <silent> <buffer> <C-Left>  E
    nmap <silent> <buffer> H E
    nmap <silent> <buffer> L W
endfu


" end function definition "}}}2
" Initialize Plugin "{{{2
:call <SID>Init()

" Vim Modeline " {{{2
" vim: set foldmethod=marker: 

" Filetype plugin for editing CSV files. "{{{1
" Author:  Christian Brabandt <cb@256bit.org>
" Version: 0.17
" Script:  http://www.vim.org/scripts/script.php?script_id=2830
" License: VIM License
" Last Change: Tue, 16 Aug 2011 08:39:52 +0200
" Documentation: see :help ft_csv.txt
" GetLatestVimScripts: 2830 17 :AutoInstall: csv.vim
"
" Some ideas are take from the wiki http://vim.wikia.com/wiki/VimTip667
" though, implementation differs.

" Plugin folklore "{{{2
if v:version < 700 || exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

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
    if !exists("g:csv_hiHeader")
	let s:hiHeader = "Title"
    else
	let s:hiHeader = g:csv_hiHeader
    endif
    exe "hi link CSVHeaderLine" s:hiHeader
    
    " Determine default Delimiter
    if !exists("g:csv_delim")
	let b:delimiter=<SID>GetDelimiter()
    else
	let b:delimiter=g:csv_delim
    endif

    if empty(b:delimiter) && !exists("b:csv_fixed_width")
	call <SID>Warn("No delimiter found. See :h csv-delimiter to set it manually!")
    endif
    
    let s:del='\%(' . b:delimiter . '\|$\)'
    " Pattern for matching a single column
    if !exists("g:csv_strict_columns") && !exists("g:csv_col") 
		\ && !exists("b:csv_fixed_width")
	" - Allow double quotes as escaped quotes only insides double quotes
	" - Allow linebreaks only, if g:csv_nl isn't set (this is
	"   only allowed in double quoted strings see RFC4180), though this
	"   does not work with :WhatColumn and might mess up syntax
	"   highlighting.
	" - optionally allow whitespace in front of the fields (to make it 
	"   work with :ArrangeCol (that is actually not RFC4180 valid))
	" - Should work with most ugly solutions that are available
	let b:col='\%(\%(\%(' . (b:delimiter !~ '\s' ? '\s*' : '') . 
		    \ '"\%(' . (exists("g:csv_nl") ? '\_' : '' ) . 
		    \ '[^"]\|""\)*"\)' . s:del . 
		    \	'\)\|\%(' . 
		    \  '[^' .  b:delimiter . ']*' . s:del . '\)\)'
    elseif !exists("g:csv_col") && exists("g:csv_strict_columns")
	" strict columns
	let b:col='\%([^' . b:delimiter . ']*' . s:del . '\)'
    elseif exists("b:csv_fixed_width")
	" Fixed width column
	let b:col=''
	" Check for sane default
	if b:csv_fixed_width =~? '[^0-9,]'
	    call <sid>Warn("Please specify the list of character columns" .
			\ "like this: '1,3,5'. See also :h csv-fixedwidth")
	    return
	endif
	let b:csv_fixed_width_cols=split(b:csv_fixed_width, ',')
	" Force evaluating as numbers
	call map(b:csv_fixed_width_cols, 'v:val+0')
    else
	" User given column definition
	let b:col = g:csv_col
    endif
    

    " define buffer-local commands
    call <SID>CommandDefinitions()
    " CSV specific mappings
    call <SID>CSVMappings()

    " Highlight column, on which the cursor is?
    if exists("g:csv_highlight_column") && g:csv_highlight_column =~? 'y' &&
		\ !exists("#CSV_HI#CursorMoved")
	aug CSV_HI
	    au!
	    au CursorMoved <buffer> HiColumn
	aug end
	" Set highlighting for column, on which the cursor is currently
	HiColumn
    elseif exists("#CSV_HI#CursorMoved")
	aug CSV_HI
	    au! CursorMoved <buffer>
	aug end
	aug! CSV_HI
	" Remove any existing highlighting
	HiColumn!
    endif

    " force reloading CSV Syntax Highlighting
    if exists("b:current_syntax")
	unlet b:current_syntax
	" Force reloading syntax file
    endif
    if !exists("#CSV#ColorScheme")
	" Make sure, syntax highlighting is applied
	" after changing the colorscheme
	augroup CSV
	    au!
	    au ColorScheme *.csv,*.dat do Syntax
	augroup end
    endif
    silent do Syntax

    " undo when setting a new filetype
    let b:undo_ftplugin = "setlocal sol< tw< wrap<"
	\ . "| unlet! b:delimiter b:col b:csv_fixed_width_cols"

    " CSV local settings
    setl nostartofline tw=0 nowrap
    if has("conceal")
	setl cole=2 cocu=nc
	let b:undo_ftplugin .= '|setl cole< cocu<'
    endif
endfu 

fu! <SID>SearchColumn(arg) "{{{3
    try 
	let arglist=split(a:arg)
	if len(arglist) == 1
	   let colnr=<SID>WColumn()
	   let pat=substitute(arglist[0], '^\(.\)\(.*\)\1$', '\2', '')
	   if pat == arglist[0]
	       throw "E684"
	    endif
	else
	    let colnr=arglist[0]
	    let pat=substitute(arglist[1], '^\(.\)\(.*\)\1$', '\2', '')
	   if pat == arglist[1]
	       throw "E684"
	    endif
	endif
    "catch /^Vim\%((\a\+)\)\=:E684/	
    catch /E684/	" catch error index out of bounds
	call <SID>Warn("Error! Usage :SearchInColumn [<colnr>] /pattern/")
	return 1
    endtry
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
    if colnr > 1 && colnr < maxcolnr
	"let @/=<SID>GetColPat(colnr-1,0) . '*\zs' . pat . '\ze\([^' . b:delimiter . ']*' . b:delimiter .'\)\?' . <SID>GetColPat(maxcolnr-colnr-1,0)
	"let @/= '^' . <SID>GetColPat(colnr-1,0) . '[^' . b:delimiter . ']*\zs' . pat . '\ze[^' . b:delimiter . ']*'.b:delimiter . <SID>GetColPat(maxcolnr-colnr,0) . '$'
	"let @/= '^' . <SID>GetColPat(colnr-1,0) . b:col1 . '\?\zs' . pat . '\ze' . b:col1 .'\?' . <SID>GetColPat(maxcolnr-colnr,0) " . '$'
	if !exists("b:csv_fixed_width_cols")
	    let @/= '^' . <SID>GetColPat(colnr-1,0) . '\%([^' . b:delimiter .
		    \ ']*\)\?\zs' . pat . '\ze' . '\%([^' . b:delimiter .']*\)\?' . 
		    \ b:delimiter . <SID>GetColPat(maxcolnr-colnr,0)  . '$'
	else
	    let @/ = '\%' . b:csv_fixed_width_cols[(colnr-1)] . 'c\zs' . pat
	            \ . '.\{-}\ze\%' . (b:csv_fixed_width_cols[colnr]) . 'c\ze'
	endif
    elseif colnr == maxcolnr
	if !exists("b:csv_fixed_width_cols")
	    let @/= '^' . <SID>GetColPat(colnr-1,0) . '\%([^' . b:delimiter .
		\ ']*\)\?\zs' . pat . '\ze' 
	else
	    let @/= '\%' . b:csv_fixed_width_cols[-1] . 'c\zs' . pat . '\ze'
	endif
    else " colnr = 1
	"let @/= '^\zs' . pat . '\ze' . substitute((<SID>GetColPat(maxcolnr - colnr)), '\\zs', '', 'g')
	"let @/= '^\zs' . b:col1 . '\?' . pat . '\ze' . b:col1 . '\?' .  <SID>GetColPat(maxcolnr,0) . '$'
	if !exists("b:csv_fixed_width_cols")
	    let @/= '^' . '\%([^' . b:delimiter . ']*\)\?\zs' . pat .
		\ '\ze\%([^' . b:delimiter . ']*\)\?' . b:delimiter .
		\ <SID>GetColPat(maxcolnr-1,0) . '$'
	else
	    let @/= pat . '\ze.\{-}\%' . b:csv_fixed_width_cols[1] . 'c'
	endif
    endif
    try
	norm! n
    catch /^Vim\%((\a\+)\)\=:E486/
        " Pattern not found
	echohl Error
	echomsg "E486: Pattern not found in column " . colnr . ": " . pat 
	if &vbs > 0
	    echomsg substitute(v:exception, '^[^:]*:', '','')
	endif
	echohl Normal
    endtry
endfu


fu! <SID>DelColumn(colnr) "{{{3
    let maxcolnr = <SID>MaxColumns()
    let _p = getpos('.')

    if empty(a:colnr)
       let colnr=<SID>WColumn()
    else
       let colnr=a:colnr
    endif

    if colnr > maxcolnr
	call <SID>Warn("There exists no column " . colnr)
	return 
    endif

    if colnr != '1'
	if !exists("b:csv_fixed_width_cols")
	    let pat= '^' . <SID>GetColPat(colnr-1,1) . b:col
	else
	    let pat= <SID>GetColPat(colnr,0) 
	endif
    else
	" distinction between csv and fixed width does not matter here
	let pat= '^' . <SID>GetColPat(colnr,0) 
    endif
    if &ro
       setl noro
    endif
    exe ':%s/' . escape(pat, '/') . '//'
    call setpos('.', _p)
endfu

fu! <SID>HiCol(colnr) "{{{3
    if a:colnr > <SID>MaxColumns() && a:colnr[-1:] != '!'
	call <SID>Warn("There exists no column " . a:colnr)
	return
    endif
    if a:colnr[-1:] != '!'
	if empty(a:colnr)
	   let colnr=<SID>WColumn()
	else
	   let colnr=a:colnr
	endif

	if colnr==1
	    let pat='^'. <SID>GetColPat(colnr,0)
	else
	    if !exists("b:csv_fixed_width_cols")
		let pat='^'. <SID>GetColPat(colnr-1,1) . b:col
	    else
		let pat=<SID>GetColPat(colnr,0)
	    endif
	endif
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
	if a:colnr[-1:] == '!'
	    return
	endif
	let s:matchid=matchadd(s:hiGroup, pat, 0)
    else
	if a:colnr[-1:] != '!'
	    exe ":2match " . s:hiGroup . ' /' . pat . '/'
	endif
    endif
endfu

fu! <SID>GetDelimiter() "{{{3
    if !exists("b:csv_fixed_width_cols")
	let _cur = getpos('.')
	let Delim={0: ';', 1:  ',', 2: '|', 3: '	'}
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
    else
	" There is no delimiter for fixedwidth files
	return ''
    endif
endfu

fu! <SID>WColumn(...) "{{{3
    " Return on which column the cursor is
    let _cur = getpos('.')
    if !exists("b:csv_fixed_width_cols")
	let line=getline('.')
	" move cursor to end of field
	"call search(b:col, 'ec', line('.'))
	call search(b:col, 'ec')
	let end=col('.')-1
	let fields=(split(line[0:end],b:col.'\zs'))
	let ret=len(fields)
	if exists("a:1") && a:1 > 0
	    " bang attribute
	    let head  = split(getline(1),b:col.'\zs')
	    " remove preceeding whitespace
	    let ret   = substitute(head[ret-1], '^\s\+', '', '')
	    " remove delimiter
	    let ret   = substitute(ret, b:delimiter. '$', '', '')
	endif
    else
	let temp=getpos('.')[2]
	let j=1
	let ret = 1
	for i in sort(b:csv_fixed_width_cols, "<sid>SortList")
	    if temp >= i
		let ret = j
	    endif
	    let j += 1
	endfor
    endif
    call setpos('.',_cur)
    return ret
endfu 

fu! <SID>MaxColumns() "{{{3
    "return maximum number of columns in first 10 lines
    if !exists("b:csv_fixed_width_cols")
	let l=getline(1,10)
	let fields=[]
	let result=0
	for item in l
	    let temp=len(split(item, b:col.'\zs'))
	    let result=(temp>result ? temp : result)
	endfor
	return result
    else
	return len(b:csv_fixed_width_cols)
    endif
endfu

fu! <SID>ColWidth(colnr) "{{{3
    " Return the width of a column
    " Internal function, not called from extern,
    " does not work with fixed width columns
    let width=20 "Fallback (wild guess)

    if !exists("b:csv_fixed_width_cols")
	if !exists("b:buffer_content")
	    let b:csv_list=getline(1,'$')
	    let b:buffer_content=1
	endif
	let list=copy(b:csv_list)
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
	    return width
	endtry
    else
	if a:colnr > 0
	    return b:csv_fixed_width_cols[a:colnr] - b:csv_fixed_width_cols[(a:colnr - 1)]
	endif
    endif
endfu

fu! <SID>ArrangeCol(first, last) range "{{{3
    "TODO: Why doesn't that work?
    " is this because of the range flag?
    " It's because of the way, Vim works with
    " a:firstline and a:lastline parameter, therefore
    " explicitly give the range as argument to the function
    if exists("b:csv_fixed_width_cols")
	" Nothing to do
	call <sid>Warn("ArrangeColumn does not work with fixed width column!")
	return
    endif
    let cur=winsaveview()
    " Force recalculation of Column width
    if exists("b:col_width")
      unlet b:col_width
    endif
    " Force recalculation of column width
    if exists("b:buffer_content")
      unlet b:buffer_content
    endif

   if &ro
       " Just in case, to prevent the Warning 
       " Warning: W10: Changing read-only file
       setl noro
   endif
   exe a:first . ',' . a:last .'s/' . (b:col) .
  \ '/\=<SID>Columnize(submatch(0))/' . (&gd ? '' : 'g')
   setl ro
   call winrestview(cur)
endfu

fu! <SID>Columnize(field) "{{{3
   " Internal function, not called from external,
   " does not work with fixed width columns
   if !exists("b:col_width")
	let b:col_width=[]
	let max_cols=<SID>MaxColumns()
	for i in range(1,max_cols)
	    call add(b:col_width, <SID>ColWidth(i))
	endfor
	if exists("b:csv_list")
	    " delete buffer content in variable b:csv_list,
	    " this was only necessary for calculating the max width
	    unlet b:csv_list
	endif
   endif
   " convert zero based indexed list to 1 based indexed list,
   " Default: 20 width, in case that column width isn't defined
   let width=get(b:col_width,<SID>WColumn()-1,20)
   if !exists("g:csv_no_multibyte")
       let a = split(a:field, '\zs')
       let add = eval(join(map(a, 'len(v:val)'), '+'))
       let add -= len(a)
   else
       let add = 0
   endif
   
   " Add one for the frame
   " plus additional width for multibyte chars,
   " since printf(%*s..) uses byte width!
   let width = width + add  + 1

   return printf("%*s", width ,  a:field)
endfun

fu! <SID>GetColPat(colnr, zs_flag) "{{{3
    " Return Pattern for given column
    if a:colnr > 1
	if !exists("b:csv_fixed_width_cols")
	    let pat=b:col . '\{' . (a:colnr) . '\}' 
	else
	    if a:colnr >= len(b:csv_fixed_width_cols)
		" Get last column
	        let pat='\%' . b:csv_fixed_width_cols[-1] . 'c.*'
	    else
		let pat='\%' . b:csv_fixed_width_cols[(a:colnr - 1)] .
		\ 'c.\{-}\%' .   b:csv_fixed_width_cols[a:colnr] . 'c'
	    endif
	endif
    else
	if !exists("b:csv_fixed_width_cols")
	    let pat=b:col 
	else
	    let pat='\%' . b:csv_fixed_width_cols[0] . 'c.\{-}\%' .
	    \ b:csv_fixed_width_cols[1] . 'c'
	endif
    endif
    return pat . (a:zs_flag ? '\zs' : '')
endfu

fu! <SID>SplitHeaderLine(lines, bang, hor) "{{{3
    if exists("b:csv_fixed_width_cols")
	call <sid>Warn("Header does not work with fixed width column!")
	return
    endif
    if !a:bang 
	" A Split Header Window already exists, 
	" first close the already existing Window
	if exists("b:CSV_SplitWindow")
	    call <sid>SplitHeaderLine(a:lines, 1, a:hor)
	endif
	" Split Window
	let _stl = &l:stl
	let _sbo = &sbo
	if a:hor
	    setl scrollopt=hor scrollbind
	    let lines = empty(a:lines) ? 1 : a:lines
	    abo sp
	    1
	    exe "resize" . lines
	    setl scrollopt=hor scrollbind winfixheight
	    "let &l:stl=repeat(' ', winwidth(0))
	    let &l:stl="%#Normal#".repeat(' ',winwidth(0))
	    " Highlight first row
	    let win = winnr()
	else
	    setl scrollopt=ver scrollbind
	    0
	    let b=b:col
	    let a=[]
	    let a=<sid>CopyCol('',1)
	    " Force recalculating columns width
	    unlet! b:buffer_content
	    let width = <sid>ColWidth(1)
	    let b=b:col
	    abo vsp +enew
	    let b:col=b
	    call append(0, a)
	    $d _
	    sil %s/.*/\=printf("%.*s", width, submatch(0))/eg
	    0
	    exe "vert res" width
	    setl scrollopt=ver scrollbind winfixwidth 
	    setl buftype=nowrite bufhidden=hide noswapfile nobuflisted
	    let win = winnr()
	endif
	call matchadd("CSVHeaderLine", b:col)
	exe "wincmd p"
	let b:CSV_SplitWindow = win
    else
	" Close split window
	if !exists("b:CSV_SplitWindow")
	    return
	endif
	exe b:CSV_SplitWindow . "wincmd w"
	if exists("_stl")
	    let &l_stl = _stl
	endif
	if exists("_sbo")
	    let &sbo = _sbo
	endif
	setl noscrollbind
	wincmd c
	unlet! b:CSV_SplitWindow
    endif
endfu

fu! <SID>SplitHeaderToggle(hor) "{{{3
    if !exists("b:CSV_SplitWindow")
	:call <sid>SplitHeaderLine(1,0,a:hor)
    else
	:call <sid>SplitHeaderLine(1,1,a:hor)
    endif
endfu

" TODO: from here on add logic for fixed-width csv files!
fu! <SID>MoveCol(forward, line) "{{{3
    " Move cursor position upwards/downwards left/right
    let colnr=<SID>WColumn()
    let maxcol=<SID>MaxColumns()
    let cpos=getpos('.')[2]
    if !exists("b:csv_fixed_width_cols")
	call search(b:col, 'bc', line('.'))
    endif
    let spos=getpos('.')[2]

    " Check for valid column
    " a:forward == 1 : search next col
    " a:forward == -1: search prev col
    " a:forward == 0 : stay in col
    if colnr - v:count1 >= 1 && a:forward == -1
	let colnr -= v:count1
    elseif colnr - v:count1 < 1 && a:forward == -1
	let colnr = 0
    elseif colnr + v:count1 <= maxcol && a:forward == 1
	let colnr += v:count1
    elseif colnr + v:count1 > maxcol && a:forward == 1
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
	"let pat = pat . '\%' . line . 'l'
    elseif (colnr == 0) || (colnr == maxcol + 1)
	if !exists("b:csv_fixed_width_cols")
	    let pat=b:col
	else
	    if a:forward > 0
		" Move forwards
		let pat=<sid>GetColPat(1, 0)
	    else
		" Move backwards
		let pat=<sid>GetColPat(maxcol, 0)
	    endif
	endif
    else
	if !exists("b:csv_fixed_width_cols")
	    let pat='^'. <SID>GetColPat(colnr-1,1) . b:col
	else
	    let pat=<SID>GetColPat(colnr,0)
	endif
	"let pat = pat . '\%' . line . 'l'
    endif

    " Search
    " move left/right
    if a:forward > 0
	call search(pat, 'W')
    elseif a:forward < 0
	call search(pat, 'bWe')
    " Moving upwards/downwards
    elseif line >= line('.')
	call search(pat . '\%' . line . 'l', '', line)
	" Move to the correct screen column
	" This is a best effort approach, we might still 
	" leave the column (if the next column is shorter)
	if !exists("b:csv_fixed_width_cols")
	    let a    = getpos('.')
	    let a[2]+= cpos-spos
	else
	    let a    = getpos('.')
	    let a[2] = cpos
	endif
	call setpos('.', a)
    elseif line < line('.')
	call search(pat . '\%' . line . 'l', 'b', line)
	" Move to the correct screen column
	if !exists("b:csv_fixed_width_cols")
	    let a    = getpos('.')
	    let a[2]+= cpos-spos
	else
	    let a    = getpos('.')
	    let a[2] = cpos
	endif
	call setpos('.', a)
    endif
endfun

fu! <SID>SortComplete(A,L,P) "{{{3
    return join(range(1,<sid>MaxColumns()),"\n")
endfun 

fu! <SID>SortList(a1, a2) "{{{3
    return a:a1 == a:a2 ? 0 : a:a1 > a:a2 ? 1 : -1
endfu

fu! <SID>Sort(bang, line1, line2, colnr) range "{{{3
    let wsv=winsaveview()
    if a:colnr =~? 'n'
	let numeric = 1
    else
	let numeric = 0
    endif
    let col = (empty(a:colnr) || a:colnr !~? '\d\+') ? <sid>WColumn() : a:colnr+0
    if col != 1
	if !exists("b:csv_fixed_width_cols")
	    let pat= '^' . <SID>GetColPat(col-1,1) . b:col
	else
	    let pat= '^' . <SID>GetColPat(col,0)
	endif
    else
	let pat= '^' . <SID>GetColPat(col,0) 
    endif
    exe a:line1 ',' a:line2 . "sort" . (a:bang ? '!' : '') .
		\' r ' . (numeric ? 'n' : '') . ' /' . pat . '/'
    call winrestview(wsv)
endfun

fu! CSV_WCol() "{{{3
    return printf(" %d/%d", <SID>WColumn(), <SID>MaxColumns())
endfun

fu! <sid>CopyCol(reg, col) "{{{3
    " Return Specified Column into register reg
    let col = a:col == "0" ? <sid>WColumn() : a:col+0
    let mcol = <sid>MaxColumns()
    if col == '$' || col > mcol
	let col = mcol
    endif
    let a=getline(1, '$')
    if !exists("b:csv_fixed_width_cols")
	call map(a, 'split(v:val, ''^'' . b:col . ''\zs'')[col-1]')
    else
	call map(a, 'matchstr(v:val, <sid>GetColPat(col, 0))')
    endif
    if a:reg =~ '[-"0-9a-zA-Z*+]'
	"exe  ':let @' . a:reg . ' = "' . join(a, "\n") . '"'
	" set the register to blockwise mode
	call setreg(a:reg, join(a, "\n"), 'b')
    else
	return a
    endif
endfu

fu! <sid>MoveColumn(start, stop, ...) range "{{{3
    " Move column behind dest
    " Explicitly give the range as argument,
    " cause otherwise, Vim would move the cursor
    let wsv = winsaveview()

    let col = <sid>WColumn()
    let max = <sid>MaxColumns()

    " If no argument is given, move current column after last column
    let source=(exists("a:1") && a:1 > 0 && a:1 <= max ? a:1 : col)
    let dest  =(exists("a:2") && a:2 > 0 && a:2 <= max ? a:2 : max)

    " translate 1 based columns into zero based list index
    let source -= 1
    let dest   -= 1

    if source >= dest
	call <sid>Warn("Destination column before source column, aborting!")
        return
    endif

    " Swap line by line, instead of reading the whole range into memory

    for i in range(a:start, a:stop)
	if !exists("b:csv_fixed_width_cols")
	    let fields=split(getline(i), b:col . '\zs')
	else
	    let fields=[]
	    for j in range(1, max, 1)
		call add(fields, matchstr(getline(i), <sid>GetColPat(j,0)))
	    endfor
	endif

	" Add delimiter to destination column, in case there was none,
	" remove delimiter from source, in case destination did not have one
	if matchstr(fields[dest], '.$') !~? b:delimiter
	    let fields[dest] = fields[dest] . b:delimiter
	    if matchstr(fields[source], '.$') =~? b:delimiter
		let fields[source] = substitute(fields[source],
		    \ '^\(.*\).$', '\1', '')
	    endif
	endif

	let fields= (source == 0 ? [] : fields[0 : (source-1)])
		    \ + fields[ (source+1) : dest ]
		    \ + [ fields[source] ] + fields[(dest+1):]

	call setline(i, join(fields, ''))
    endfor

    call winrestview(wsv)
    
endfu

fu! <sid>SumColumn(list) "{{{3
    return eval(join(a:list, '+'))
endfu

fu! csv#EvalColumn(nr, func, first, last) range "{{{3
    let save = winsaveview()
    let col = (empty(a:nr) ? <sid>WColumn() : a:nr)
    let start = a:first - 1
    let stop  = a:last  - 1

    let column = <sid>CopyCol('', col)[start : stop]
    " Delete delimiter
    call map(column, 'substitute(v:val, b:delimiter, "", "g")')
    try
	let result=call(function(a:func), [column])
	return result
    catch
	" Evaluation of expression failed
	echohl Title
	echomsg "Evaluating" matchstr(a:func, '[a-zA-Z]\+$') 
	\ "failed for column" col . "!"
	echohl Normal
	return ''
    finally
	call winrestview(save)
    endtry
endfu


fu! <sid>DoForEachColumn(start, stop, bang) range "{{{3
    " Do something for each column,
    " e.g. generate SQL-Statements, convert to HTML,
    " something like this
    " TODO: Define the function
    " needs a csv_pre_convert variable
    "         csv_post_convert variable
    "         csv_convert variable
    "         result contains converted buffer content
    let result = []

    if !exists("g:csv_convert")
	call <sid>Warn("You need to define how to convert your data using" .
		    \ "the g:csv_convert variable, see :h csv-convert")
	return
    endif

    if exists("g:csv_pre_convert") && !empty(g:csv_pre_convert)
	call add(result, g:csv_pre_convert)
    endif

    for item in range(a:start, a:stop, 1)
	let t = g:csv_convert
	let line = getline(item)
	let context = split(g:csv_convert, '%s')
	let columns = len(context)
	if columns > <sid>MaxColumns()
	    let columns = <sid>MaxColumns()
	elseif columns == 1
	    call <sid>Warn("No Columns defined in your g:csv_convert variable, Aborting")
	    return
	endif

	if !exists("b:csv_fixed_width_cols")
	    let fields=split(line, b:col . '\zs')
	    if a:bang
		call map(fields, 'substitute(v:val, b:delimiter .
		    \ ''\?$'' , "", "")')
	    endif
	else
	    let fields=[]
	    for j in range(1, columns, 1)
		call add(fields, matchstr(line, <sid>GetColPat(j,0)))
	    endfor
	endif
	for j in range(1, columns, 1)
	    let t=substitute(t, '%s', fields[j-1], '')
	endfor
	call add(result, t)
    endfor

    if exists("g:csv_post_convert") && !empty(g:csv_post_convert)
	call add(result, g:csv_post_convert)
    endif

    new
    call append('$', result)
    1d _

endfun

fu! <sid>PrepareDoForEachColumn(start, stop, bang) range"{{{3
    let pre = exists("g:csv_pre_convert") ? g:csv_pre_convert : ''
    let g:csv_pre_convert=input('Pre convert text: ', pre)
    let post = exists("g:csv_post_convert") ? g:csv_post_convert : ''
    let g:csv_post_convert=input('Post convert text: ', post)
    let convert = exists("g:csv_convert") ? g:csv_convert : ''
    let g:csv_convert=input("Converted text, use %s for column input:\n", convert)
    call <sid>DoForEachColumn(a:start, a:stop, a:bang)
endfun
fu! <SID>CommandDefinitions() "{{{3
    if !exists(":WhatColumn") "{{{4
	command! -buffer -bang WhatColumn :echo <SID>WColumn(<bang>0)
    endif
    if !exists(":NrColumns") "{{{4
	command! -buffer NrColumns :echo <SID>MaxColumns()
    endif
    if !exists(":HiColumn") "{{{4
	command! -buffer -bang -nargs=? HiColumn :call <SID>HiCol(<q-args>.<q-bang>)
    endif
    if !exists(":SearchInColumn") "{{{4
	command! -buffer -nargs=* SearchInColumn :call <SID>SearchColumn(<q-args>)
    endif
    if !exists(":DeleteColumn") "{{{4
	command! -buffer -nargs=? -complete=custom,
	    \<SID>SortComplete DeleteColumn :call <SID>DelColumn(<q-args>)
    endif
    if !exists(":ArrangeColumn") "{{{4
	command! -buffer -range ArrangeColumn
		\ :call <SID>ArrangeCol(<line1>,<line2>)
    endif
    if !exists(":InitCSV") "{{{4
	command! -buffer InitCSV :call <SID>Init()
    endif
    if !exists(":Header") "{{{4
	command! -buffer -bang -nargs=? Header :call <SID>SplitHeaderLine(<q-args>,<bang>0,1)
    endif
    if !exists(":VHeader") "{{{4
	command! -buffer -bang -nargs=? VHeader :call <SID>SplitHeaderLine(<q-args>,<bang>0,0)
    endif
    if !exists(":HeaderToggle") "{{{4
	command! -buffer HeaderToggle :call <SID>SplitHeaderToggle(1)
    endif
    if !exists(":VHeaderToggle") "{{{4
	command! -buffer VHeaderToggle :call <SID>SplitHeaderToggle(0)
    endif
    if !exists(":Sort") "{{{4
	command! -buffer -nargs=* -bang -range=% -complete=custom,
	    \<SID>SortComplete Sort :call
	    \<SID>Sort(<bang>0,<line1>,<line2>,<q-args>)
    endif
    if !exists(":Column") "{{{4
	command! -buffer -count -register Column :call <SID>CopyCol(
		    \ empty(<q-reg>) ? '"' : <q-reg>,<q-count>)
    endif
    if !exists(":MoveColumn") "{{{4
	command! -buffer -range=% -nargs=* -complete=custom,<SID>SortComplete
		    \ MoveColumn :call <SID>MoveColumn(<line1>,<line2>,<f-args>)
    endif
    if !exists(":SumCol") "{{{4
	command! -buffer -nargs=? -range=% -complete=custom,<SID>SortComplete
		    \ SumCol :echo csv#EvalColumn(<q-args>, "<sid>SumColumn", <line1>,<line2>)
    endif
    if !exists(":ConvertData") "{{{4
	command! -buffer -bang -nargs=? -range=%
	    \ -complete=custom,<SID>SortComplete ConvertData
	    \ :call <sid>PrepareDoForEachColumn(<line1>,<line2>, <bang>0)
    endif
endfu

fu! <SID>CSVMappings() "{{{3
    noremap <silent> <buffer> W :<C-U>call <SID>MoveCol(1, line('.'))<CR>
    noremap <silent> <buffer> E :<C-U>call <SID>MoveCol(-1, line('.'))<CR>
    noremap <silent> <buffer> K :<C-U>call <SID>MoveCol(0, line('.')-v:count1)<CR>
    noremap <silent> <buffer> J :<C-U>call <SID>MoveCol(0, line('.')+v:count1)<CR>
    " Remap J and K to a sane backup
    noremap <silent> <buffer> <LocalLeader>J J
    noremap <silent> <buffer> <LocalLeader>K K
    " Map C-Right and C-Left as alternative to W and E
    map <silent> <buffer> <C-Right> W
    map <silent> <buffer> <C-Left>  E
    map <silent> <buffer> H E
    map <silent> <buffer> L W
    map <silent> <buffer> <Up> K
    map <silent> <buffer> <Down> J
endfu


" end function definition "}}}2
" Initialize Plugin "{{{2
call <SID>Init()
let &cpo = s:cpo_save
unlet s:cpo_save

" Vim Modeline " {{{2
" vim: set foldmethod=marker: 

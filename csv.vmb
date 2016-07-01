" Vimball Archiver by Charles E. Campbell
UseVimball
finish
ftplugin/csv.vim	[[[1
2857
" Filetype plugin for editing CSV files. "{{{1
" Author:  Christian Brabandt <cb@256bit.org>
" Version: 0.31
" Script:  http://www.vim.org/scripts/script.php?script_id=2830
" License: VIM License
" Last Change: Thu, 15 Jan 2015 21:05:10 +0100
" Documentation: see :help ft-csv.txt
" GetLatestVimScripts: 2830 30 :AutoInstall: csv.vim
"
" Some ideas are taken from the wiki http://vim.wikia.com/wiki/VimTip667
" though, implementation differs.

" Plugin folklore "{{{1
if v:version < 700 || exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim
fu! <sid>DetermineSID()
    let s:SID = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_DetermineSID$')
endfu
call s:DetermineSID()
delf s:DetermineSID
let s:csv_numeric_sort = v:version > 704 || v:version == 704 && has("patch341")
if !s:csv_numeric_sort "{{{2
  fu! <sid>CSVSortValues(i1, i2) "{{{3
    return (a:i1+0) == (a:i2+0) ? 0 : (a:i1+0) > (a:i2+0) ? 1 : -1
  endfu
endif
" Function definitions: "{{{1
fu! CSVArrangeCol(first, last, bang, limit) range "{{{2
    if &ft =~? 'csv'
        call <sid>ArrangeCol(a:first, a:last, a:bang, a:limit)
    else
        finish
    endif
endfu

" Script specific functions "{{{2
fu! <sid>Warn(mess) "{{{3
    echohl WarningMsg
    echomsg "CSV: " . a:mess
    echohl Normal
endfu

fu! <sid>Init(startline, endline, ...) "{{{3
    " if a:1 is set, keep the b:delimiter
    let keep = exists("a:1") && a:1
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
    if !keep
        if !exists("g:csv_delim")
            let b:delimiter=<SID>GetDelimiter(a:startline, a:endline)
        else
            let b:delimiter=g:csv_delim
        endif
    endif

    " Define custom commentstring
    if !exists("g:csv_comment")
        let b:csv_cmt = split(&cms, '%s')
    else
        let b:csv_cmt = split(g:csv_comment, '%s')
    endif

    if empty(b:delimiter) && !exists("b:csv_fixed_width")
        call <SID>Warn("No delimiter found. See :h csv-delimiter to set it manually!")
        " Use a sane default as delimiter:
        let b:delimiter = ','
    endif

    let s:del='\%(' . b:delimiter . '\|$\)'
    let s:del_noend='\%(' . b:delimiter . '\)'
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
                \ '[^"]\|""\)*"\s*\)' . s:del . '\)\|\%(' .
                \  '[^' .  b:delimiter . ']*' . s:del . '\)\)'
        let b:col_end='\%(\%(\%(' . (b:delimiter !~ '\s' ? '\s*' : '') .
                \ '"\%(' . (exists("g:csv_nl") ? '\_' : '' ) .
                \ '[^"]\|""\)*"\)' . s:del_noend . '\)\|\%(' .
                \  '[^' .  b:delimiter . ']*' . s:del_noend . '\)\)'
    elseif !exists("g:csv_col") && exists("g:csv_strict_columns")
        " strict columns
        let b:col='\%([^' . b:delimiter . ']*' . s:del . '\)'
        let b:col_end='\%([^' . b:delimiter . ']*' . s:del_noend . '\)'
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
        let b:col_noend = g:csv_col
    endif

    " set filetype specific options
    call <sid>LocalSettings('all')

    " define buffer-local commands
    call <SID>CommandDefinitions()

    " Check Header line
    " Defines which line is considered to be a header line
    call <sid>CheckHeaderLine()

    " CSV specific mappings
    call <SID>CSVMappings()

    " force reloading CSV Syntax Highlighting
    if exists("b:current_syntax")
        unlet b:current_syntax
        " Force reloading syntax file
    endif
    call <sid>DoAutoCommands()
    " enable CSV Menu
    call <sid>Menu(1)
    call <sid>DisableFolding()
    if !exists("b:current_syntax")
      silent do Syntax
    endif
    unlet! b:csv_start b:csv_end

    " Remove configuration variables
    let b:undo_ftplugin .=  "| unlet! b:delimiter b:col"
        \ . "| unlet! b:csv_fixed_width_cols b:csv_filter"
        \ . "| unlet! b:csv_fixed_width b:csv_list b:col_width"
        \ . "| unlet! b:csv_SplitWindow b:csv_headerline b:csv_cmt"
        \ . "| unlet! b:csv_thousands_sep b:csv_decimal_sep"
        \. " | unlet! b:browsefilter b:csv_cmt"
        \. " | unlet! b:csv_arrange_leftalign"

 " Delete all functions
 " disabled currently, because otherwise when switching ft
 "          I think, all functions need to be read in again and this
 "          costs time.
endfu

fu! <sid>LocalSettings(type) "{{{3
    if a:type == 'all'
        " CSV local settings
        setl nostartofline tw=0 nowrap

        " undo when setting a new filetype
        let b:undo_ftplugin = "setlocal sol& tw< wrap<"

        " Set browsefilter
        let b:browsefilter="CSV Files (*.csv, *.dat)\t*.csv;*.dat\n".
                 \ "All Files\t*.*\n"

        if has("conceal")
            setl cole=2 cocu=nc
            let b:undo_ftplugin .= '| setl cole< cocu< '
        endif

    elseif a:type == 'fold'
        let s:fdt = &l:fdt
        let s:fcs = &l:fcs

        if a:type == 'fold'
            " Be sure to also fold away single screen lines
            setl fen fdm=expr
            setl fdl=0 fml=0 fdc=2
            if !get(g:, 'csv_disable_fdt',0)
                let &l:foldtext=strlen(v:folddashes) . ' lines hidden'
                let &fcs=substitute(&fcs, 'fold:.,', '', '')
                if !exists("b:csv_did_foldsettings")
                    let b:undo_ftplugin .= printf("|set fdt<|setl fcs=%s", escape(s:fcs, '\\| '))
                endif
            endif
            if !exists("b:csv_did_foldsettings")
                let b:undo_ftplugin .=
                \ "| setl fen< fdm< fdl< fdc< fml< fde<"
                let b:csv_did_foldsettings = 1
                let b:undo_ftplugin .= "| unlet! b:csv_did_foldsettings"
            endif
        endif
    endif
endfu

fu! <sid>DoAutoCommands() "{{{3
    " Highlight column, on which the cursor is
    if exists("g:csv_highlight_column") && g:csv_highlight_column =~? 'y'
        exe "aug CSV_HI".bufnr('')
            au!
            exe "au CursorMoved <buffer=".bufnr('')."> HiColumn"
            exe "au BufWinLeave <buffer=".bufnr('')."> HiColumn!"
        aug end
        " Set highlighting for column, on which the cursor is currently
        HiColumn
    else
        exe "aug CSV_HI".bufnr('')
            exe "au! CursorMoved <buffer=".bufnr('').">"
        aug end
        exe "aug! CSV_HI".bufnr('')
        " Remove any existing highlighting
        HiColumn!
    endif
    " undo autocommand:
    let b:undo_ftplugin .= '| exe "sil! au! CSV_HI CursorMoved <buffer> "'
    let b:undo_ftplugin .= '| exe "sil! aug! CSV_HI" |exe "sil! HiColumn!"'

    if has("gui_running") && !exists("#CSV_Menu#FileType")
        augroup CSV_Menu
            au!
            au FileType * call <sid>Menu(&ft=='csv')
            au BufEnter <buffer> call <sid>Menu(1) " enable
            au BufLeave <buffer> call <sid>Menu(0) " disable
            au BufNewFile,BufNew * call <sid>Menu(0)
        augroup END
    endif
endfu
fu! <sid>GetPat(colnr, maxcolnr, pat, allowmore) "{{{3
    " if a:allowmmore, allows more to match after the pattern
    if a:colnr > 1 && a:colnr < a:maxcolnr
        if !exists("b:csv_fixed_width_cols")
            return '^' . <SID>GetColPat(a:colnr-1,0) . '\%([^' .
                \ b:delimiter . ']\{-}\)\?\zs' . a:pat . '\ze' .
                \ (a:allowmore ? ('\%([^' . b:delimiter .']\{-}\)\?' .
                \ b:delimiter . <SID>GetColPat(a:maxcolnr - a:colnr, 0). '$') : '')
        else
            return '\%' . b:csv_fixed_width_cols[(a:colnr - 1)] . 'c\zs'
                \ . a:pat . '.\{-}\ze\%'
                \ . (b:csv_fixed_width_cols[a:colnr]) . 'c\ze'
        endif
    elseif a:colnr == a:maxcolnr
        if !exists("b:csv_fixed_width_cols")
            return '^' . <SID>GetColPat(a:colnr - 1,0) .
                \ '\zs' . a:pat . '\ze' . (a:allowmore ? '' : '$')
        else
            return '\%' . b:csv_fixed_width_cols[-1] .
                \ 'c\zs' . a:pat . '\ze' . (a:allowmore ? '' : '$')
        endif
    else " colnr = 1
        if !exists("b:csv_fixed_width_cols")
            return '^' . '\%([^' . b:delimiter . ']\{-}\)\?\zs' . a:pat .
            \ (a:allowmore ? ('\ze\%([^' . b:delimiter . ']*\)\?' . b:delimiter .
            \ <SID>GetColPat(a:maxcolnr -1 , 0) . '$') : '')
        else
            return a:pat . '\ze.\{-}\%' . b:csv_fixed_width_cols[1] . 'c'
        endif
    endif
    return ''
endfu
fu! <sid>SearchColumn(arg) "{{{3
    try
        let arglist=split(a:arg)
        if len(arglist) == 1
            let colnr=<SID>WColumn()
            let pat=substitute(arglist[0], '^\(.\)\(.*\)\1$', '\2', '')
            if pat == arglist[0]
                throw "E684"
            endif
        else
            " Determine whether the first word in the argument is a number
            " (of the column to search).
            let colnr = substitute( a:arg, '^\s*\(\d\+\)\s.*', '\1', '' )
            " If it is _not_ a number,
            if colnr == a:arg
                " treat the whole argument as the pattern.
                let pat = substitute(a:arg,
                    \ '^\s*\(\S\)\(.*\)\1\s*$', '\2', '' )
                if pat == a:arg
                    throw "E684"
                endif
                let colnr = <SID>WColumn()
            else
                " if the first word tells us the number of the column,
                " treat the rest of the argument as the pattern.
                let pat = substitute(a:arg,
                    \ '^\s*\d\+\s*\(\S\)\(.*\)\1\s*$', '\2', '' )
                if pat == a:arg
                    throw "E684"
                endif
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
    let @/ = <sid>GetPat(colnr, maxcolnr, '\%('.pat. '\)', 1)
    try
        " force redraw, so that the search pattern isn't shown
        exe "norm! n\<c-l>"
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
fu! <sid>DeleteColumn(arg) "{{{3
    let _wsv = winsaveview()
    if a:arg =~ '^[/]'
        let i = 0
        let pat = a:arg[1:]
        call cursor(1,1)
        while search(pat, 'cW')
            " Delete matching column
            sil call <sid>DelColumn('')
            let i+=1
        endw
    else
        let i = 1
        sil call <sid>DelColumn(a:arg)
    endif
    if i > 1
        call <sid>Warn(printf("%d columns deleted", i))
    else
        call <sid>Warn("1 column deleted")
    endif
    call winrestview(_wsv)
endfu
fu! <sid>DelColumn(colnr) "{{{3
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
        let ro = 1
        setl noro
    else
        let ro = 0
    endif
    exe ':%s/' . escape(pat, '/') . '//'
    call setpos('.', _p)
    if ro
        setl ro
    endif
endfu
fu! <sid>HiCol(colnr, bang) "{{{3
    if !a:bang
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
        elseif !exists("b:csv_fixed_width_cols")
            let pat='^'. <SID>GetColPat(colnr-1,1) . b:col
        else
            let pat=<SID>GetColPat(colnr,0)
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
        if a:bang
            return
        endif
        let s:matchid=matchadd(s:hiGroup, pat, 0)
    elseif !a:bang
        exe ":2match " . s:hiGroup . ' /' . pat . '/'
    endif
endfu
fu! <sid>GetDelimiter(first, last) "{{{3
    if !exists("b:csv_fixed_width_cols")
        let _cur = getpos('.')
        let _s   = @/
        let Delim= {0: ';', 1:  ',', 2: '|', 3: '	', 4: '\^'}
        let temp = {}
        " :silent :s does not work with lazyredraw
        let _lz  = &lz
        set nolz
        for i in  values(Delim)
            redir => temp[i]
            exe "silent! ". a:first. ",". a:last. "s/" . i . "/&/nge"
            redir END
        endfor
        let &lz = _lz
        let Delim = map(temp, 'matchstr(substitute(v:val, "\n", "", ""), "^\\d\\+")')
        let Delim = filter(temp, 'v:val=~''\d''')
        let max   = max(values(temp))

        let result=[]
        call setpos('.', _cur)
        let @/ = _s
        for [key, value] in items(Delim)
            if value == max
                return key
            endif
        endfor
        return ''
    else
        " There is no delimiter for fixedwidth files
        return ''
    endif
endfu
fu! <sid>WColumn(...) "{{{3
    " Return on which column the cursor is
    let _cur = getpos('.')
    if !exists("b:csv_fixed_width_cols")
        if line('.') > 1 && mode('') != 'n'
            " in insert mode, get line from above, just in case the current
            " line is empty
            let line = getline(line('.')-1)
        else
            let line = getline('.')
        endif
        " move cursor to end of field
        "call search(b:col, 'ec', line('.'))
        call search(b:col, 'ec')
        let end=col('.')-1
        let fields=(split(line[0:end],b:col.'\zs'))
        let ret=len(fields)
        if exists("a:1") && a:1 > 0
            " bang attribute: Try to get the column name
            let head  = split(getline(get(b:, 'csv_headerline', 1)),b:col.'\zs')
            " remove preceeding whitespace
            if len(head) < ret
                call <sid>Warn("Header has no field ". ret)
            else
                let ret   = substitute(head[ret-1], '^\s\+', '', '')
                " remove delimiter
                let ret   = substitute(ret, b:delimiter. '$', '', '')
            endif
        endif
    else
        let temp=getpos('.')[2]
        let j=1
        let ret = 1
        for i in sort(b:csv_fixed_width_cols, s:csv_numeric_sort ? 'n' : 's:CSVSortValues')
            if temp >= i
                let ret = j
            endif
            let j += 1
        endfor
    endif
    call setpos('.',_cur)
    return ret
endfu
fu! <sid>MaxColumns(...) "{{{3
    let this_col = exists("a:1")
    "return maximum number of columns in first 10 lines
    if !exists("b:csv_fixed_width_cols")
      let i = this_col ? a:1 : get(b:, 'csv_headerline', 1)
        while 1
            let l = getline(i, (this_col ? i : i+10))
            if empty(l) && i >= line('$')
                break
            endif

            " Filter comments out
            let pat = '^\s*\V'. escape(b:csv_cmt[0], '\\')
            call filter(l, 'v:val !~ pat')
            if !empty(l) || this_col
                break
            else
                let i+=10
            endif
        endw

        if empty(l)
            throw 'csv:no_col'
        endif
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
fu! <sid>ColWidth(colnr, ...) "{{{3
    " if a:1 is given, specifies the row, for which to calculate the width
    "
    " Return the width of a column
    " Internal function
    let width=20 "Fallback (wild guess)
    let tlist=[]

    if !exists("b:csv_fixed_width_cols")
        if !exists("b:csv_list")
            " only check first 10000 lines, to be faster
            let last = line('$')
            if exists("a:1")
                let last = a:1
            endif
            if !get(b:, 'csv_arrange_use_all_rows', 0)
                if last > 10000
                    let last = 10000
                    call <sid>Warn('File too large, only checking the first 10000 rows for the width')
                endif
            endif
            let b:csv_list=getline(1,last)
            let pat = '^\s*\V'. escape(b:csv_cmt[0], '\\')
            call filter(b:csv_list, 'v:val !~ pat')
            call filter(b:csv_list, '!empty(v:val)')
            call map(b:csv_list, 'split(v:val, b:col.''\zs'')')
        endif
        try
            for item in b:csv_list
                call add(tlist, get(item, a:colnr-1, ''))
            endfor
            " do not strip leading whitespace
            call map(tlist, 'substitute(v:val, ".", "x", "g")')
            call map(tlist, 'strlen(v:val)')
            return max(tlist)
        catch
            throw "ColWidth-error"
            return width
        endtry
    else
        let cols = len(b:csv_fixed_width_cols)
        if a:colnr == cols
            return strlen(substitute(getline('$'), '.', 'x', 'g')) -
                \ b:csv_fixed_width_cols[cols-1] + 1
        elseif a:colnr < cols && a:colnr > 0
            return b:csv_fixed_width_cols[a:colnr] -
                \ b:csv_fixed_width_cols[(a:colnr - 1)]
        else
            throw "ColWidth-error"
            return 0
        endif
    endif
endfu
fu! <sid>ArrangeCol(first, last, bang, limit, ...) range "{{{3
    " a:1, optional width parameter of line from which to take the width
    "
    " explicitly give the range as argument to the function
    if exists("b:csv_fixed_width_cols")
        " Nothing to do
        call <sid>Warn("ArrangeColumn does not work with fixed width column!")
        return
    endif
    let cur=winsaveview()
    if a:bang || (exists("a:1") && !empty(a:1))
        if a:bang && exists("b:col_width")
          " Unarrange, so that if csv_arrange_align has changed
          " it will be adjusted automaticaly
          call <sid>PrepUnArrangeCol(a:first, a:last)
        endif
        " Force recalculating the Column width
        unlet! b:csv_list b:col_width
    elseif a:limit > -1 && a:limit < getfsize(fnamemodify(bufname(''), ':p'))
        return
    endif

    let first = a:first
    let last  = a:last
    if exists("b:csv_headerline")
      if a:first < b:csv_headerline
        let first = b:csv_headerline
      endif
      if a:last < b:csv_headerline
        let last = b:csv_headerline
      endif
    endif
    if first > line('$')
        let first=line('$')
    endif
    if last > line('$')
        let last=line('$')
    endif
    if &vbs
      echomsg printf("ArrangeCol Start: %d, End: %d", first, last)
    endif

    if !exists("b:col_width")
        " Force recalculation of Column width
        let row = exists("a:1") ? a:1 : ''
        call <sid>CalculateColumnWidth(row)
    endif

    " abort on empty file
    if !len(b:col_width)
        call <sid>Warn("No column data detected, aborting ArrangeCol command!")
        return
    endif
    if &ro
       " Just in case, to prevent the Warning
       " Warning: W10: Changing read-only file
       let ro = 1
       setl noro
    else
       let ro = 0
    endif
    let s:count = 0
    let _stl  = &stl
    let s:max   = (last - first + 1) * len(b:col_width)
    let s:temp  = 0
    try
        exe "sil". first . ',' . last .'s/' . (b:col) .
        \ '/\=<SID>Columnize(submatch(0))/' . (&gd ? '' : 'g')
    finally
        " Clean up variables, that were only needed for <sid>Columnize() function
        unlet! s:columnize_count s:max_cols s:prev_line s:max s:count s:temp s:val
        if ro
            setl ro
            unlet ro
        endif
        let &stl = _stl
        call winrestview(cur)
    endtry
endfu
fu! <sid>ProgressBar(cnt, max) "{{{3
    if get(g:, 'csv_no_progress', 0) || a:max == 0
        return
    endif
    let width = 40 " max width of progressbar
    if width > &columns
        let width = &columns
    endif
    let s:val = a:cnt * width / a:max
    if (s:val > s:temp || a:cnt==1)
        let &stl='%#DiffAdd#['.repeat('=', s:val).'>'. repeat(' ', width-s:val).']'.
                \ (width < &columns  ? ' '.100*s:val/width. '%%' : '')
        redrawstatus
        let s:temp = s:val
    endif
endfu
fu! <sid>PrepUnArrangeCol(first, last) "{{{3
    " Because of the way, Vim works with
    " a:firstline and a:lastline parameter,
    " explicitly give the range as argument to the function
    if exists("b:csv_fixed_width_cols")
        " Nothing to do
        call <sid>Warn("UnArrangeColumn does not work with fixed width column!")
        return
    endif
    let cur=winsaveview()

    if &ro
       " Just in case, to prevent the Warning
       " Warning: W10: Changing read-only file
       setl noro
    endif
    exe a:first . ',' . a:last .'s/' . (b:col) .
    \ '/\=<SID>UnArrangeCol(submatch(0))/' . (&gd ? '' : 'g')
    " Clean up variables, that were only needed for <sid>Columnize() function
    call winrestview(cur)
endfu
fu! <sid>UnArrangeCol(match) "{{{3
    " Strip leading white space, also trims empty records:
    return substitute(a:match, '\%(^\s\+\)\|\%(\s\+\ze'.b:delimiter. '\?$\)', '', 'g')
endfu
fu! <sid>CalculateColumnWidth(row) "{{{3
    " Internal function, not called from external,
    " does not work with fixed width columns
    let b:col_width=[]
    try
        if exists("b:csv_headerline")
          if line('.') < b:csv_headerline
            call cursor(b:csv_headerline,1)
          endif
        endif
        let s:max_cols=<SID>MaxColumns(line('.'))
        for i in range(1,s:max_cols)
            if empty(a:row)
                call add(b:col_width, <SID>ColWidth(i))
            else
                call add(b:col_width, <SID>ColWidth(i,a:row))
            endif
        endfor
    catch /csv:no_col/
        call <sid>Warn("Error: getting Column numbers, aborting!")
    catch /ColWidth/
        call <sid>Warn("Error: getting Column Width, using default!")
    endtry
    " delete buffer content in variable b:csv_list,
    " this was only necessary for calculating the max width
    unlet! b:csv_list s:columnize_count s:decimal_column
endfu
fu! <sid>Columnize(field) "{{{3
    " Internal function, not called from external,
    " does not work with fixed width columns
    if !exists("s:columnize_count")
        let s:columnize_count = 0
    endif

    if !exists("s:max_cols")
        let s:max_cols = len(b:col_width)
    endif

    if exists("s:prev_line") && s:prev_line != line('.')
        let s:columnize_count = 0
    endif
    let s:count+=1

    let s:prev_line = line('.')
    " convert zero based indexed list to 1 based indexed list,
    " Default: 20 width, in case that column width isn't defined
    " Careful: Keep this fast! Using
    " let width=get(b:col_width,<SID>WColumn()-1,20)
    " is too slow, so we are using:
    let colnr = s:columnize_count % s:max_cols
    let width = get(b:col_width, colnr, 20)
    let align = 'r'
    if exists('b:csv_arrange_align')
        let align_list=split(get(b:, 'csv_arrange_align', " "), '\zs')
        try
            let align = align_list[colnr]
        catch
            let align = 'r'
        endtry
    endif
    if ((align isnot? 'r' && align isnot? 'l' &&
       \ align isnot? 'c' && align isnot? '.') || get(b:, 'csv_arrange_leftalign', 0))
       let align = 'r'
    endif
    call <sid>ProgressBar(s:count,s:max)

    let s:columnize_count += 1
    let has_delimiter = (a:field[-1:] is? b:delimiter)
    if align is? 'l'
        " left-align content
        return printf("%-*S%s", width-1,
            \ (has_delimiter ? a:field[:-2] : a:field),
            \ (has_delimiter ? b:delimiter : ' '))
    elseif align is? 'c'
        " center the column
        let t = width - len(split(a:field, '\zs'))
        let leftwidth = t/2
        " uneven width, add one
        let rightwidth = (t%2 ? leftwidth+1 : leftwidth)
        let field = (has_delimiter ?  a:field[:-2] : a:field).  repeat(' ', rightwidth)
        return printf("%*S%s", width , field, (has_delimiter ? b:delimiter : ' '))
    elseif align is? '.'
        if !exists("s:decimal_column")
            let s:decimal_column = {}
        endif
        if get(s:decimal_column, colnr, 0) == 0
            call <sid>CheckHeaderLine()
            call <sid>NumberFormat()
            let data = <sid>CopyCol('', colnr+1, '')[s:csv_fold_headerline : -1]
            let pat1 = escape(s:nr_format[1], '.').'\zs[^'.s:nr_format[1].']*\ze'.
                        \ (has_delimiter ? b:delimiter : '').'$'
            let pat2 = '\d\+\ze\%(\%('.escape(s:nr_format[1], '.'). '\d\+\)\|'.
                        \ (has_delimiter ? b:delimiter : '').'$\)'
            let data1 = map(copy(data), 'matchstr(v:val, pat1)')
            let data2 = map(data, 'matchstr(v:val, pat2)')
            " strlen should be okay for decimals...
            let data1 = map(data1, 'strlen(v:val)')
            let data2 = map(data2, 'strlen(v:val)')
            let dec = max(data1)
            let scal = max(data2)
            if dec + scal + 1 + (has_delimiter ? 1 : 0) > width
                let width = dec + scal + 1 + (has_delimiter ? 1 :0)
                let b:col_width[colnr] = width
            endif

            let s:decimal_column[colnr] = dec
        else
            let dec = get(s:decimal_column, colnr)
        endif
        let field = (has_delimiter ?  a:field[:-2] : a:field)
        let fmt = printf("%%%d.%df", width+1, dec)
        try
            if s:nr_format[1] isnot '.'
                let field = substitute(field, s:nr_format[1], '.', 'g')
                let field = substitute(field, s:nr_format[0], '', 'g')
            endif
            if field =~? '\h' " text in the column, can't be converted to float
                throw "no decimal"
            endif
            let result = printf(fmt, str2float(field)). (has_delimiter ? b:delimiter : ' ')
        catch
            let result = printf("%*S", width+2, a:field)
        endtry
        return result
    else
        " right align
        return printf("%*S", width+1 ,  a:field)
    endif
endfun
fu! <sid>GetColPat(colnr, zs_flag) "{{{3
    " Return Pattern for given column
    if a:colnr > 1
        if !exists("b:csv_fixed_width_cols")
            let pat=b:col . '\{' . (a:colnr) . '\}'
        else
            if a:colnr >= len(b:csv_fixed_width_cols)
            " Get last column
                let pat='\%' . b:csv_fixed_width_cols[-1] . 'v.*'
            else
            let pat='\%' . b:csv_fixed_width_cols[(a:colnr - 1)] .
            \ 'c.\{-}\%' .   b:csv_fixed_width_cols[a:colnr] . 'v'
            endif
        endif
    elseif !exists("b:csv_fixed_width_cols")
        let pat=b:col
    else
        let pat='\%' . b:csv_fixed_width_cols[0] . 'v.\{-}' .
            \ (len(b:csv_fixed_width_cols) > 1 ?
            \ '\%' . b:csv_fixed_width_cols[1] . 'v' :
            \ '')
    endif
    return pat . (a:zs_flag ? '\zs' : '')
endfu
fu! <sid>SetupAutoCmd(window,bufnr) "{{{3
    " Setup QuitPre autocommand to quit cleanly
    aug CSV_QuitPre
        au!
        exe "au QuitPre * call CSV_CloseBuffer(".winbufnr(a:window).")"
        if !exists("##OptionSet")
          exe "au CursorHold <buffer=".a:bufnr."> call CSV_SetSplitOptions(".a:window.")"
        else
          exe "au OptionSet foldcolumn,number,relativenumber call <sid>CSV_SetOption(".a:bufnr.
            \ ", ".bufnr('%').", expand('<amatch>'), v:option_new)"
        endif
        exe "au VimResized,FocusLost,FocusGained <buffer=".a:bufnr."> call CSV_SetSplitOptions(".a:window.")"
    aug END
endfu
fu! <sid>CSV_SetOption(csvfile, header, option, value) "{{{3
  " only trigger if the option is called in the correct buffer
  if getbufvar(a:csvfile, 'csv_SplitWindow') && bufnr('') == a:csvfile
    call setbufvar(a:header, '&'.a:option, a:value)
  endif
endfu
fu! <sid>SplitHeaderLine(lines, bang, hor) "{{{3
    if exists("b:csv_fixed_width_cols")
        call <sid>Warn("Header does not work with fixed width column!")
        return
    endif
    " Check that there exists a header line
    call <sid>CheckHeaderLine()
    if !a:bang
        " A Split Header Window already exists,
        " first close the already existing Window
        if exists("b:csv_SplitWindow")
            call <sid>SplitHeaderLine(a:lines, 1, a:hor)
        endif
        " Split Window
        let _stl = &l:stl
        let _sbo = &sbo
        let a = []
        let b=b:col
        let bufnr = bufnr('.')
        if a:hor
            setl scrollopt=hor scrollbind cursorbind
            let _fdc = &l:fdc
            let lines = empty(a:lines) ? s:csv_fold_headerline : a:lines
            let a = getline(1,lines)
            " Does it make sense to use the preview window?
            " sil! pedit %
            above sp +enew
            call setline(1, a)
            " Needed for syntax highlighting
            "let b:col=b
            "setl syntax=csv
            sil! doautocmd FileType csv
            noa 1
            sil! sign unplace *
            exe "resize" . lines
            setl scrollopt=hor winfixheight nowrap cursorbind
            let &l:stl="%#Normal#".repeat(' ',winwidth(0))
            let s:local_stl = &l:stl
            " set the foldcolumn to the same of the other window
            let &l:fdc = _fdc
        else
            setl scrollopt=ver scrollbind cursorbind
            noa 0
            if a:lines[-1:] is? '!'
                let a=<sid>CopyCol('',a:lines,'')
            else
                let a=<sid>CopyCol('',1, a:lines-1)
            endif
            " Does it make sense to use the preview window?
            "vert sil! pedit |wincmd w | enew!
            above vsp +enew
            call append(0, a)
            $d _
            let b:col = b
            sil! doautocmd FileType csv
            " remove leading delimiter
            exe "sil :%s/^". b:delimiter. "//e"
            " remove trailing delimiter
            exe "sil :%s/". b:delimiter. "\s*$//e"
            syn clear
            noa 0
            let b:csv_SplitWindow = winnr()
            sil :call <sid>ArrangeCol(1,line('$'), 1, -1)
            sil! sign unplace *
            exe "vert res" . len(split(getline(1), '\zs'))
            call matchadd("CSVHeaderLine", b:col)
            setl scrollopt=ver winfixwidth cursorbind nonu nornu fdc=0
        endif
        call <sid>SetupAutoCmd(winnr(),bufnr)
        " disable airline
        let w:airline_disabled = 1
        let win = winnr()
        setl scrollbind buftype=nowrite bufhidden=wipe noswapfile nobuflisted
        noa wincmd p
        let b:csv_SplitWindow = win
        aug CSV_Preview
            au!
            au BufWinLeave <buffer> call <sid>SplitHeaderLine(0, 1, 0)
        aug END
    else
        " Close split window
        if !exists("b:csv_SplitWindow")
            return
        endif
        try
          let winnr = winnr()
          if winnr == b:csv_SplitWindow || winbufnr(b:csv_SplitWindow) == bufnr('')
            " window already closed
            return
          endif
          exe b:csv_SplitWindow . "wincmd w"
          if exists("_stl")
              let &l:stl = _stl
          endif
          if exists("_sbo")
              let &sbo = _sbo
          endif
          setl noscrollbind nocursorbind
          call CSV_CloseBuffer(bufnr('%'))
        catch /^Vim\%((\a\+)\)\=:E444/	" cannot close last window
        catch /^Vim\%((\a\+)\)\=:E517/	" buffer already wiped
            " no-op
        finally
          unlet! b:csv_SplitWindow
          aug CSV_Preview
              au!
          aug END
          aug! CSV_Preview
        endtry
    endif
endfu
fu! <sid>SplitHeaderToggle(hor) "{{{3
    if !exists("b:csv_SplitWindow")
        :call <sid>SplitHeaderLine(1,0,a:hor)
    else
        :call <sid>SplitHeaderLine(1,1,a:hor)
    endif
endfu
" TODO: from here on add logic for fixed-width csv files!
fu! <sid>MoveCol(forward, line, ...) "{{{3
    " Move cursor position upwards/downwards left/right
    " a:1 is there to have some mappings move in the same
    " direction but still stop at a different position
    " see :h csv-mapping-H
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
    if foldclosed(line) != -1
        let line = line > line('.') ? foldclosedend(line) + 1 : foldclosed(line)
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
        if colnr > 0 || cpos == spos
            call search('.\ze'.pat, 'bWe')
            let stime=localtime()
            while getpos('.')[2] == cpos && <sid>Timeout(stime) " make sure loop terminates
                " cursor didn't move, move cursor one cell to the left
                norm! h
                if colnr > 0
                    call <sid>MoveCol(-1, line('.'))
                else
                    norm! 0
                endif
            endw
            if (exists("a:1") && a:1)
                " H also stops at the beginning of the content
                " of a field.
                let epos = getpos('.')
                if getline('.')[col('.')-1] == ' '
                    call search('\S', 'W', line('.'))
                    if getpos('.')[2] > spos
                        call setpos('.', epos)
                    endif
                endif
            endif
        else
            norm! 0
        endif
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
fu! <sid>SortComplete(A,L,P) "{{{3
    return join(range(1,<sid>MaxColumns()),"\n")
endfun
fu! <sid>Sort(bang, line1, line2, colnr) range "{{{3
    " :Sort command
    let wsv  = winsaveview()
    let flag = matchstr(a:colnr, '[nixo]')
    call <sid>CheckHeaderLine()
    let line1 = a:line1
    let line2 = a:line2
    if line1 <= s:csv_fold_headerline
      let line1 += s:csv_fold_headerline
    endif
    if line2 <= s:csv_fold_headerline
      let line2 += s:csv_fold_headerline
    endif
    let col = (empty(a:colnr) || a:colnr !~? '\d\+[nixo]\?') ? <sid>WColumn() : a:colnr+0
    if col != 1
        if !exists("b:csv_fixed_width_cols")
            let pat= '^' . <SID>GetColPat(col-1,1) . b:col
        else
            let pat= <SID>GetColPat(col,0)
        endif
    else
        let pat= '^' . <SID>GetColPat(col,0)
    endif
    exe line1. ','. line2. "sort". (a:bang ? '!' : '') .
        \' r'. flag. ' /' . pat . '/'
    call winrestview(wsv)
endfun
fu! <sid>CopyCol(reg, col, cnt) "{{{3
    " Return Specified Column into register reg
    let col = a:col == "0" ? <sid>WColumn() : a:col+0
    let mcol = <sid>MaxColumns()
    if col == '$' || col > mcol
        let col = mcol
    endif
    " The number of columns to return
    " by default (value of zero, will only return that specific column)
    let cnt_cols = col - 1
    if !empty(a:cnt) && a:cnt > 0 && col + a:cnt <= mcol
        let cnt_cols = col + a:cnt - 1
    endif
    let a = []
    " Don't get lines, that are currently filtered away
    if !exists("b:csv_filter") || empty(b:csv_filter)
        let a=getline(1, '$')
    else
        for line in range(1, line('$'))
            if foldlevel(line)
                continue
            else
                call add(a, getline(line))
            endif
        endfor
    endif
    " Filter comments out
    let pat = '^\s*\V'. escape(b:csv_cmt[0], '\\')
    call filter(a, 'v:val !~ pat')

    if !exists("b:csv_fixed_width_cols")
        call map(a, 'split(v:val, ''^'' . b:col . ''\zs'')[col-1:cnt_cols]')
    else
        call map(a, 'matchstr(v:val, <sid>GetColPat(col, 0)).*<sid>GetColPat(col+cnt_cols, 0)')
    endif
    if type(a[0]) == type([])
        call map(a, 'join(v:val, "")')
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
        let content = getline(i)
        if content =~ '^\s*\V'. escape(b:csv_cmt[0], '\\')
            " skip comments
            continue
        endif
        if !exists("b:csv_fixed_width_cols")
            let fields=split(content, b:col . '\zs')
            " Add delimiter to destination column, in case there was none,
            " remove delimiter from source, in case destination did not have one
            if matchstr(fields[dest], '.$') !~? b:delimiter
                let fields[dest] = fields[dest] . b:delimiter
                if matchstr(fields[source], '.$') =~? b:delimiter
                let fields[source] = substitute(fields[source],
                    \ '^\(.*\).$', '\1', '')
                endif
            endif
        else
            let fields=[]
            " this is very inefficient!
            for j in range(1, max, 1)
                call add(fields, matchstr(content, <sid>GetColPat(j,0)))
            endfor
        endif

        let fields= (source == 0 ? [] : fields[0 : (source-1)])
                \ + fields[ (source+1) : dest ]
                \ + [ fields[source] ] + fields[(dest+1):]

        call setline(i, join(fields, ''))
    endfor
    call winrestview(wsv)
endfu
fu! <sid>AddColumn(start, stop, ...) range "{{{3
    " Add new empty column
    " Explicitly give the range as argument,
    " cause otherwise, Vim would move the cursor
    if exists("b:csv_fixed_width_cols")
        call <sid>Warn("Adding Columns only works for delimited files")
        return
    endif

    let wsv = winsaveview()

    let col = <sid>WColumn()
    let max = <sid>MaxColumns()

    " If no argument is given, add column after current column
    if exists("a:1")
        if a:1 == '$' || a:1 >= max
            let pos = max
        elseif a:1 < 0
            let pos = col
        else
            let pos = a:1
        endif
    else
        let pos = col
    endif
    let cnt=(exists("a:2") && a:2 > 0 ? a:2 : 1)

    " translate 1 based columns into zero based list index
    "let pos -= 1
    let col -= 1

    if pos == 0
        let pat = '^'
    elseif pos == max-1
        let pat = '$'
    else
        let pat = <sid>GetColPat(pos,1)
    endif

    if pat != '$' || (pat == '$' &&  getline(a:stop)[-1:] == b:delimiter)
        let subst = repeat(' '. b:delimiter, cnt)
    else
        let subst = repeat(b:delimiter. ' ', cnt)
    endif

    " if the data contains comments, substitute one line after another
    " skipping comment lines (we could do it with a single :s statement,
    " but that would fail for the first and last column.

    let commentpat = '\%(\%>'.(a:start-1).'l\V'.
                \ escape(b:csv_cmt[0], '\\').'\m\)'. '\&\%(\%<'.
                \ (a:stop+1). 'l\V'. escape(b:csv_cmt[0], '\\'). '\m\)'
    if search(commentpat)
        for i in range(a:start, a:stop)
            let content = getline(i)
            if content =~ '^\s*\V'. escape(b:csv_cmt[0], '\\')
                " skip comments
                continue
            endif
            exe printf("sil %ds/%s/%s/e", i, pat, subst)
        endfor
    else
        " comments should by default be skipped (pattern shouldn't match)
        exe printf("sil %d,%ds/%s/%s/e", a:start, a:stop, pat, subst)
    endif
    call winrestview(wsv)
endfu
fu! <sid>SumColumn(list) "{{{3
    " Sum a list of values, but only consider the digits within each value
    " parses the digits according to the given format (if none has been
    " specified, assume POSIX format (without thousand separator) If Vim has
    " does not support floats, simply sum up only the integer part
    if empty(a:list)
        return 0
    else
        let sum = has("float") ? 0.0 : 0
        for item in a:list
            if empty(item)
                continue
            endif
            let nr = matchstr(item, '-\?\d\(.*\d\)\?$')
            let format1 = '^-\?\d\+\zs\V' . s:nr_format[0] . '\m\ze\d'
            let format2 = '\d\+\zs\V' . s:nr_format[1] . '\m\ze\d'
            try
                let nr = substitute(nr, format1, '', '')
                if has("float") && s:nr_format[1] != '.'
                    let nr = substitute(nr, format2, '.', '')
                endif
            catch
                let nr = 0
            endtry
            let sum += (has("float") ? str2float(nr) : (nr + 0))
        endfor
        if has("float")
            if float2nr(sum) == sum
                return float2nr(sum)
            else
                return printf("%.2f", sum)
            endif
        endif
        return sum
    endif
endfu
fu! <sid>MaxColumn(list) "{{{3
    " Sum a list of values, but only consider the digits within each value
    " parses the digits according to the given format (if none has been
    " specified, assume POSIX format (without thousand separator) If Vim has
    " does not support floats, simply sum up only the integer part
    if empty(a:list)
        return 0
    else
        let result = []
        for item in a:list
            if empty(item)
                continue
            endif
            let nr = matchstr(item, '-\?\d\(.*\d\)\?$')
            let format1 = '^-\?\d\+\zs\V' . s:nr_format[0] . '\m\ze\d'
            let format2 = '\d\+\zs\V' . s:nr_format[1] . '\m\ze\d'
            try
                let nr = substitute(nr, format1, '', '')
                if has("float") && s:nr_format[1] != '.'
                    let nr = substitute(nr, format2, '.', '')
                endif
            catch
                let nr = 0
            endtry
            call add(result, has("float") ? str2float(nr) : nr+0)
        endfor
        let result = sort(result, s:csv_numeric_sort ? 'n' : 's:CSVSortValues')
        let ind = len(result) > 9 ? 9 : len(result)
        if has_key(get(s:, 'additional', {}), 'distinct') && s:additional['distinct']
          if exists("*uniq")
            let result=uniq(result)
          else
            let l = {}
            for item in result
              let l[item] = get(l, 'item', 0)
            endfor
            let result = keys(l)
          endif
        endif
        return s:additional.ismax ? reverse(result)[:ind] : result[:ind]
    endif
endfu
fu! <sid>CountColumn(list) "{{{3
    if empty(a:list)
        return 0
    elseif has_key(get(s:, 'additional', {}), 'distinct') && s:additional['distinct']
      if exists("*uniq")
        return len(uniq(sort(a:list)))
      else
        let l = {}
        for item in a:list
          let l[item] =  get(l, 'item', 0) + 1
        endfor
        return len(keys(l))
      endif
    else
        return len(a:list)
    endif
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
        if foldlevel(line)
          " Filter out folded lines (from dynamic filter)
          continue
        endif
        let t = g:csv_convert
        let line = getline(item)
        if line =~ '^\s*\V'. escape(b:csv_cmt[0], '\\')
            " Filter comments out
            call add(result, line)
            continue
        endif
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
fu! <sid>EscapeValue(val) "{{{3
    return '\V' . escape(a:val, '\')
endfu
fu! <sid>FoldValue(lnum, filter) "{{{3
    call <sid>CheckHeaderLine()

    if (a:lnum == s:csv_fold_headerline)
        " Don't fold away the header line
        return 0
    endif
    let result = 0

    for item in values(a:filter)
        " always fold comments away
        let content = getline(a:lnum)
        if content =~ '^\s*\V'. escape(b:csv_cmt[0], '\\')
            return 1
        elseif eval('content' .  (item.match ? '!~' : '=~') . 'item.pat')
            let result += 1
        endif
    endfor
    return (result > 0)
endfu
fu! <sid>PrepareFolding(add, match)  "{{{3
    if !has("folding")
        return
    endif

    " Move folded-parts away?
    if exists("g:csv_move_folds")
        let s:csv_move_folds = g:csv_move_folds
    else
        let s:csv_move_folds = 0
    endif

    if !exists("b:csv_filter")
        let b:csv_filter = {}
    endif
    if !exists("s:filter_count") || s:filter_count < 1
        let s:filter_count = 0
    endif
    let cpos = winsaveview()

    if !a:add
        " remove last added item from filter
        if !empty(b:csv_filter)
            call <sid>RemoveLastItem(s:filter_count)
            let s:filter_count -= 1
            if empty(b:csv_filter)
                call <sid>DisableFolding()
                return
            endif
        else
            " Disable folding, if no pattern available
            call <sid>DisableFolding()
            return
        endif
    else

        let col = <sid>WColumn()
        let max = <sid>MaxColumns()
        let a   = <sid>GetColumn(line('.'), col, 0)
        let a   = <sid>ProcessFieldValue(a)
        let pat = '\%(^\|'.b:delimiter. '\)\@<='.<sid>EscapeValue(a).
                 \ '\m\ze\%('.b:delimiter.'\|$\)'

        " Make a column pattern
        let b= '\%(' .
            \ (exists("b:csv_fixed_width") ? '.*' : '') .
            \ <sid>GetPat(col, max, pat, 0) . '\)'

        let s:filter_count += 1
        let b:csv_filter[s:filter_count] = { 'pat': b, 'id': s:filter_count,
            \ 'col': col, 'orig': a, 'match': a:match}

    endif
    " Put the pattern into the search register, so they will also
    " be highlighted
"    let @/ = ''
"    for val in sort(values(b:csv_filter), '<sid>SortFilter')
"        let @/ .= val.pat . (val.id == s:filter_count ? '' : '\&')
"    endfor

    " Fold settings:
    call <sid>LocalSettings('fold')
    " Don't put spaces between the arguments!
    exe 'setl foldexpr=<snr>' . s:SID . '_FoldValue(v:lnum,b:csv_filter)'

    " Move folded area to the bottom, so there is only on consecutive
    " non-folded area
    if exists("s:csv_move_folds") && s:csv_move_folds
        \ && !&l:ro && &l:ma
        folddoclosed m$
        let cpos.lnum = s:csv_fold_headerline + 1
    endif
    call winrestview(cpos)
endfu
fu! <sid>ProcessFieldValue(field) "{{{3
    let a = a:field
    if !exists("b:csv_fixed_width")
        try
            " strip leading whitespace
            if (a =~ '\s\+'. b:delimiter . '$')
                let b = split(a, '^\s\+\ze[^' . b:delimiter. ']\+')[0]
            else
                let b = a
            endif
        catch /^Vim\%((\a\+)\)\=:E684/
            " empty pattern - should match only empty columns
            let b = a
        endtry

        " strip trailing delimiter
        try
            let a = split(b, b:delimiter . '$')[0]
        catch /^Vim\%((\a\+)\)\=:E684/
            let a = b
        endtry

        if a == b:delimiter
            try
                let a=repeat(' ', <sid>ColWidth(col))
            catch
                " no-op
            endtry
        endif
    endif
    return a
endfu
fu! <sid>OutputFilters(bang) "{{{3
    if !a:bang
        call <sid>CheckHeaderLine()
        if s:csv_fold_headerline
            let  title="Nr\tMatch\tCol\t      Name\tValue"
        else
            let  title="Nr\tMatch\tCol\tValue"
        endif
        echohl "Title"
        echo   printf("%s", title)
        echo   printf("%s", repeat("=",strdisplaywidth(title)))
        echohl "Normal"
        if !exists("b:csv_filter") || empty(b:csv_filter)
            echo printf("%s", "No active filter")
        else
            let items = values(b:csv_filter)
            call sort(items, "<sid>SortFilter")
            for item in items
                if s:csv_fold_headerline
                    echo printf("%02d\t% 2s\t%02d\t%10.10s\t%s",
                        \ item.id, (item.match ? '+' : '-'), item.col,
                        \ substitute(<sid>GetColumn(1, item.col, 0),
                        \ b:col.'$', '', ''), item.orig)
                else
                    echo printf("%02d\t% 2s\t%02d\t%s",
                        \ item.id, (item.match ? '+' : '-'),
                        \ item.col, item.orig)
                endif
            endfor
        endif
    else
        " Reapply filter again
        if !exists("b:csv_filter") || empty(b:csv_filter)
            call <sid>Warn("No filters defined currently!")
            return
        else
            exe 'setl foldexpr=<snr>' . s:SID . '_FoldValue(v:lnum,b:csv_filter)'
        endif
    endif
endfu
fu! <sid>SortFilter(a, b) "{{{3
    return a:a.id == a:b.id ? 0 :
        \ a:a.id > a:b.id ? 1 : -1
endfu
fu! <sid>GetColumn(line, col, strip) "{{{3
    " Return Column content at a:line, a:col
    let a=getline(a:line)
    " Filter comments out
    if a =~ '^\s*\V'. escape(b:csv_cmt[0], '\\')
        return ''
    endif

    if !exists("b:csv_fixed_width_cols")
        try
            let a = split(a, '^' . b:col . '\zs')[a:col - 1]
        catch
            " index out of range
            let a = ''
        endtry
    else
        let a = matchstr(a, <sid>GetColPat(a:col, 0))
    endif
    if a:strip
        return substitute(a, '^\s\+\|\s\+$', '', 'g')
    else
        return a
    endif
endfu
fu! <sid>RemoveLastItem(count) "{{{3
    for [key,value] in items(b:csv_filter)
        if value.id == a:count
            call remove(b:csv_filter, key)
        endif
    endfor
endfu
fu! <sid>DisableFolding() "{{{3
    setl nofen fdm=manual fdc=0 fdl=0
    if !get(g:, 'csv_disable_fdt',0) && exists("s:fdt") && exists("s:fcs")
        exe printf("setl fdt=%s fcs=%s", s:fdt, escape(s:fcs, '\\|'))
    endif
endfu
fu! <sid>NumberFormat() "{{{3
    let s:nr_format = [',', '.']
    if exists("b:csv_thousands_sep")
        let s:nr_format[0] = b:csv_thousands_sep
    endif
    if exists("b:csv_decimal_sep")
        let s:nr_format[1] = b:csv_decimal_sep
    endif
endfu
fu! <sid>CheckHeaderLine() "{{{3
    if !exists("b:csv_headerline")
        let s:csv_fold_headerline = 1
    else
        let s:csv_fold_headerline = b:csv_headerline
    endif
endfu
fu! <sid>AnalyzeColumn(...) "{{{3
    let maxcolnr = <SID>MaxColumns()
    if len(a:000) == 1
        let colnr = a:1
    else
        let colnr = <sid>WColumn()
    endif

    if colnr > maxcolnr
        call <SID>Warn("There exists no column " . colnr)
        return 1
    endif

    " Initialize s:fold_headerline
    call <sid>CheckHeaderLine()
    let data = <sid>CopyCol('', colnr, '')[s:csv_fold_headerline : -1]
    let qty = len(data)
    let res = {}
    for item in data
        if empty(item) || item ==# b:delimiter
            let item = 'NULL'
        endif
        if !get(res, item)
            let res[item] = 0
        endif
        let res[item]+=1
    endfor

    let max_items = reverse(sort(values(res), s:csv_numeric_sort ? 'n' : 's:CSVSortValues'))
    " What about the minimum 5 items?
    let count_items = keys(res)
    if len(max_items) > 5
        call remove(max_items, 5, -1)
        call map(max_items, 'printf(''\V%s\m'', escape(v:val, ''\\''))')
        call filter(res, 'v:val =~ ''^''.join(max_items, ''\|'').''$''')
    endif

    if has("float")
        let  title="Nr\tCount\t % \tValue"
    else
        let  title="Nr\tCount\tValue"
    endif
    echohl Title
    echo printf("%s", title)
    echohl Normal
    echo printf("%s", repeat('=', strdisplaywidth(title)))

    let i=1
    for val in max_items
        for key in keys(res)
            if res[key] =~ val && i <= len(max_items)
                if !empty(b:delimiter)
                    let k = substitute(key, b:delimiter . '\?$', '', '')
                else
                    let k = key
                endif
                if has("float")
                    echo printf("%02d\t%02d\t%2.0f%%\t%.50s", i, res[key],
                        \ ((res[key] + 0.0)/qty)*100, k)
                else
                    echo printf("%02d\t%02d\t%.50s", i, res[key], k)
                endif
                call remove(res,key)
                let i+=1
            else
                continue
            endif
        endfor
    endfor
    echo printf("%s", repeat('=', strdisplaywidth(title)))
    if &columns > 40
        echo printf("different values in column %d: %d", colnr, len(count_items))
    else
        echo printf("different values: %d", len(count_items))
    endif
    unlet max_items
endfunc
fu! <sid>Vertfold(bang, col) "{{{3
    if a:bang
        do Syntax
        return
    endif
    if !has("conceal")
        call <sid>Warn("Concealing not supported in your Vim")
        return
    endif
    if empty(b:delimiter) && !exists("b:csv_fixed_width_cols")
        call <sid>Warn("There are no columns defined, can't hide away anything!")
        return
    endif
    if empty(a:col)
        let colnr=<SID>WColumn()
    else
        let colnr=a:col
    endif
    let pat=<sid>GetPat(colnr, <sid>MaxColumns(), '.*', 1)
    if exists("b:csv_fixed_width_cols") &&
        \ pat !~ '^\^\.\*'
        " Make the pattern implicitly start at line start,
        " so it will be applied by syntax highlighting (:h :syn-priority)
        let pat='^.*' . pat
    endif
    let pat=substitute(pat, '\\zs\(\.\*\)\@=', '', '')
    if !empty(pat)
        exe "syn match CSVFold /" . pat . "/ conceal cchar=+"
    endif
endfu
fu! <sid>InitCSVFixedWidth() "{{{3
    if !exists("+cc")
        call <sid>Warn("Command disabled: 'colorcolumn' option not available")
        return
    endif
    " Turn off syntax highlighting
    syn clear
    let max_line = line('$') > 10 ? 10 : line('$')
    let t = getline(1, max_line)
    let max_len = max(map(t, 'len(split(v:val, ''\zs''))'))
    let _cc  = &l:cc
    let &l:cc = 1
    redraw!
    let Dict = {'1': 1} " first column is always the start of a new column
    let tcc  = &l:cc
    let &l:cc = 1
    echo "<Cursor>, <Space>, <ESC>, <BS>, <CR>, ?"
    let char=getchar()
    while 1
        let skip_mess = 0
        if char == "\<Left>" || char == "\<Right>"
            let tcc = eval('tcc'.(char=="\<Left>" ? '-' : '+').'1')
            if tcc < 0
                let tcc=0
            elseif tcc > max_len
                let tcc = max_len
            endif
        elseif char == "\<Space>" || char == 32 " Space
            let Dict[tcc] = 1
        elseif char == "\<BS>" || char == 127
            try
                call remove(Dict, reverse(sort(keys(Dict)))[0])
            catch /^Vim\%((\a\+)\)\=:E\(\%(716\)\|\%(684\)\)/	" Dict or List empty
                break
            endtry
        elseif char == "\<ESC>" || char == 27
            let &l:cc=_cc
            redraw!
            return
        elseif char == "\<CR>" || char == "\n" || char == "\r"  " Enter
            let Dict[tcc] = 1
            break
        elseif char == char2nr('?')
            redraw!
            echohl Title
            echo    "Key\tFunction"
            echo    "=================="
            echohl Normal
            echo    "<cr>\tDefine new column"
            echo    "<left>\tMove left"
            echo    "<right>\tMove right"
            echo    "<esc>\tAbort"
            echo    "<bs>\tDelete last column definition"
            echo    "?\tShow this help\n"
            let skip_mess = 1
        else
            let Dict={}
            break
        endif
        let &l:cc=tcc . (!empty(keys(Dict))? ',' . join(keys(Dict), ','):'')
        if !skip_mess
          redraw!
          echo "<Cursor>, <Space>, <ESC>, <BS>, <CR>..."
        endif
        let char=getchar()
    endw
    let b:csv_fixed_width_cols=[]
    let tcc=0
    let b:csv_fixed_width_cols = sort(keys(Dict), s:csv_numeric_sort ? 'n' : 's:CSVSortValues')
    let b:csv_fixed_width = join(sort(keys(Dict), s:csv_numeric_sort ? 'n' : 's:CSVSortValues'), ',')
    call <sid>Init(1, line('$'))

    let &l:cc=_cc
    redraw!
endfu
fu! <sid>NewRecord(line1, line2, count) "{{{3
    if a:count =~ "\D"
        call <sid>Warn("Invalid count specified")
        return
    endif

    let cnt = (empty(a:count) ? 1 : a:count)
    let record = ""
    for item in range(1,<sid>MaxColumns())
        if !exists("b:col_width")
            " Best guess width
            if exists("b:csv_fixed_width_cols")
                let record .= printf("%*s", <sid>ColWidth(item),
                            \ b:delimiter)
            else
                let record .= printf("%20s", b:delimiter)
            endif
        else
            let record .= printf("%*s", get(b:col_width, item-1, 0)+1, b:delimiter)
        endif
    endfor

    if getline(1)[-1:] !=  b:delimiter
        let record = record[0:-2] . " "
    endif

    let line = []
    for item in range(cnt)
        call add(line, record)
    endfor
    for nr in range(a:line1, a:line2)
        call append(nr, line)
    endfor
endfu
fu! <sid>MoveOver(outer) "{{{3
    " Move over a field
    " a:outer means include the delimiter
    let last = 0
    let outer_field = a:outer
    let cur_field = <sid>WColumn()
    let _wsv = winsaveview()

    if cur_field == <sid>MaxColumns()
        let last = 1
        if !outer_field && getline('.')[-1:] != b:delimiter
            " No trailing delimiter, so inner == outer
            let outer_field = 1
        endif
    endif
    " Move 1 column backwards, unless the cursor is in the first column
    " or in front of a delimiter
    if matchstr(getline('.'), '.\%'.virtcol('.').'v') != b:delimiter && virtcol('.') > 1
        call <sid>MoveCol(-1, line('.'))
    endif
"    if cur_field != <sid>WColumn()
        " cursor was at the beginning of the field, and moved back to the
        " previous field, move back to original position
"        call cursor(_wsv.lnum, _wsv.col)
"    endif
    let _s = @/
    if last
        exe "sil! norm! v$h" . (outer_field ? "" : "h") . (&sel ==# 'exclusive' ? "l" : '')
    else
        exe "sil! norm! v/." . b:col . "\<cr>h" . (outer_field ? "" : "h") . (&sel ==# 'exclusive' ? "l" : '')
    endif
    let _wsv.col = col('.')-1
    call winrestview(_wsv)
    let @/ = _s
endfu
fu! <sid>CSVMappings() "{{{3
    call <sid>Map('noremap', 'W', ':<C-U>call <SID>MoveCol(1, line("."))<CR>')
    call <sid>Map('noremap', '<C-Right>', ':<C-U>call <SID>MoveCol(1, line("."))<CR>')
    call <sid>Map('noremap', 'L', ':<C-U>call <SID>MoveCol(1, line("."))<CR>')
    call <sid>Map('noremap', 'E', ':<C-U>call <SID>MoveCol(-1, line("."))<CR>')
    call <sid>Map('noremap', '<C-Left>', ':<C-U>call <SID>MoveCol(-1, line("."))<CR>')
    call <sid>Map('noremap', 'H', ':<C-U>call <SID>MoveCol(-1, line("."), 1)<CR>')
    call <sid>Map('noremap', 'K', ':<C-U>call <SID>MoveCol(0, line(".")-v:count1)<CR>')
    call <sid>Map('nnoremap', '<Up>', ':<C-U>call <SID>MoveCol(0, line(".")-v:count1)<CR>')
    call <sid>Map('noremap', 'J', ':<C-U>call <SID>MoveCol(0, line(".")+v:count1)<CR>')
    call <sid>Map('nnoremap', '<Down>', ':<C-U>call <SID>MoveCol(0, line(".")+v:count1)<CR>')
    call <sid>Map('nnoremap', '<CR>', ':<C-U>call <SID>PrepareFolding(1, 1)<CR>')
    call <sid>Map('nnoremap', '<Space>', ':<C-U>call <SID>PrepareFolding(1, 0)<CR>')
    call <sid>Map('nnoremap', '<BS>', ':<C-U>call <SID>PrepareFolding(0, 1)<CR>')
    call <sid>Map('imap', '<CR>', '<sid>ColumnMode()', 'expr')
    " Text object: Field
    call <sid>Map('xnoremap', 'if', ':<C-U>call <sid>MoveOver(0)<CR>')
    call <sid>Map('xnoremap', 'af', ':<C-U>call <sid>MoveOver(1)<CR>')
    call <sid>Map('omap', 'af', ':norm vaf<cr>')
    call <sid>Map('omap', 'if', ':norm vif<cr>')
    call <sid>Map('xnoremap', 'iL', ':<C-U>call <sid>SameFieldRegion()<CR>')
    call <sid>Map('omap', 'iL', ':<C-U>call <sid>SameFieldRegion()<CR>')
    " Remap <CR> original values to a sane backup
    call <sid>Map('noremap', '<LocalLeader>J', 'J')
    call <sid>Map('noremap', '<LocalLeader>K', 'K')
    call <sid>Map('xnoremap', '<LocalLeader>W', 'W')
    call <sid>Map('xnoremap', '<LocalLeader>E', 'E')
    call <sid>Map('noremap', '<LocalLeader>H', 'H')
    call <sid>Map('noremap', '<LocalLeader>L', 'L')
    call <sid>Map('nnoremap', '<LocalLeader><CR>', '<CR>')
    call <sid>Map('nnoremap', '<LocalLeader><Space>', '<Space>')
    call <sid>Map('nnoremap', '<LocalLeader><BS>', '<BS>')
endfu
fu! <sid>CommandDefinitions() "{{{3
    call <sid>LocalCmd("WhatColumn", ':echo <sid>WColumn(<bang>0)',
        \ '-bang')
    call <sid>LocalCmd("NrColumns", ':call <sid>NrColumns(<q-bang>)', '-bang')
    call <sid>LocalCmd("HiColumn", ':call <sid>HiCol(<q-args>,<bang>0)',
        \ '-bang -nargs=?')
    call <sid>LocalCmd("SearchInColumn",
        \ ':call <sid>SearchColumn(<q-args>)', '-nargs=*')
    call <sid>LocalCmd("DeleteColumn", ':call <sid>DeleteColumn(<q-args>)',
        \ '-nargs=? -complete=custom,<sid>SortComplete')
    call <sid>LocalCmd("ArrangeColumn",
        \ ':call <sid>ArrangeCol(<line1>, <line2>, <bang>0, -1, <q-args>)',
        \ '-range -bang -nargs=?')
    call <sid>LocalCmd("UnArrangeColumn",
        \':call <sid>PrepUnArrangeCol(<line1>, <line2>)',
        \ '-range')
    call <sid>LocalCmd("CSVInit", ':call <sid>Init(<line1>,<line2>,<bang>0)',
        \ '-bang -range=%')
    call <sid>LocalCmd('Header',
        \ ':call <sid>SplitHeaderLine(<q-args>,<bang>0,1)',
        \ '-nargs=? -bang')
    call <sid>LocalCmd('VHeader',
        \ ':call <sid>SplitHeaderLine(<q-args>,<bang>0,0)',
        \ '-nargs=? -bang')
    call <sid>LocalCmd("HeaderToggle",
        \ ':call <sid>SplitHeaderToggle(1)', '')
    call <sid>LocalCmd("VHeaderToggle",
        \ ':call <sid>SplitHeaderToggle(0)', '')
    call <sid>LocalCmd("Sort",
        \ ':call <sid>Sort(<bang>0, <line1>,<line2>,<q-args>)',
        \ '-nargs=* -bang -range=% -complete=custom,<sid>SortComplete')
    call <sid>LocalCmd("Column",
        \ ':call <sid>CopyCol(empty(<q-reg>)?''"'':<q-reg>,<q-count>,<q-args>)',
        \ '-count -register -nargs=?')
    call <sid>LocalCmd("MoveColumn",
        \ ':call <sid>MoveColumn(<line1>,<line2>,<f-args>)',
        \ '-range=% -nargs=* -complete=custom,<sid>SortComplete')
    call <sid>LocalCmd("SumCol",
        \ ':echo csv#EvalColumn(<q-args>, "<sid>SumColumn", <line1>,<line2>)',
        \ '-nargs=? -range=% -complete=custom,<sid>SortComplete')
    call <sid>LocalCmd("MaxCol",
        \ ':echo csv#EvalColumn(<q-args>, "<sid>MaxColumn", <line1>,<line2>, 1)',
        \ '-nargs=? -range=% -complete=custom,<sid>SortComplete')
    call <sid>LocalCmd("MinCol",
        \ ':echo csv#EvalColumn(<q-args>, "<sid>MaxColumn", <line1>,<line2>, 0)',
        \ '-nargs=? -range=% -complete=custom,<sid>SortComplete')
    call <sid>LocalCmd("CountCol",
        \ ':echo csv#EvalColumn(<q-args>, "<sid>CountColumn", <line1>,<line2>)',
        \ '-nargs=? -range=% -complete=custom,<sid>SortComplete')
    call <sid>LocalCmd("ConvertData",
        \ ':call <sid>PrepareDoForEachColumn(<line1>,<line2>,<bang>0)',
        \ '-bang -nargs=? -range=%')
    call <sid>LocalCmd("Filters", ':call <sid>OutputFilters(<bang>0)',
        \ '-nargs=0 -bang')
    call <sid>LocalCmd("Analyze", ':call <sid>AnalyzeColumn(<args>)',
        \ '-nargs=?')
    call <sid>LocalCmd("VertFold", ':call <sid>Vertfold(<bang>0,<q-args>)',
        \ '-bang -nargs=? -range=% -complete=custom,<sid>SortComplete')
    call <sid>LocalCmd("CSVFixed", ':call <sid>InitCSVFixedWidth()', '')
    call <sid>LocalCmd("NewRecord", ':call <sid>NewRecord(<line1>,
        \ <line2>, <q-args>)', '-nargs=? -range')
    call <sid>LocalCmd("NewDelimiter", ':call <sid>NewDelimiter(<q-args>, 1, line(''$''))',
        \ '-nargs=1')
    call <sid>LocalCmd("Duplicates", ':call <sid>CheckDuplicates(<q-args>)',
        \ '-nargs=1 -complete=custom,<sid>CompleteColumnNr')
    call <sid>LocalCmd('Transpose', ':call <sid>Transpose(<line1>, <line2>)',
        \ '-range=%')
    call <sid>LocalCmd('CSVTabularize', ':call <sid>Tabularize(<bang>0,<line1>,<line2>)',
        \ '-bang -range=%')
    call <sid>LocalCmd("AddColumn",
        \ ':call <sid>AddColumn(<line1>,<line2>,<f-args>)',
        \ '-range=% -nargs=* -complete=custom,<sid>SortComplete')
    call <sid>LocalCmd('Substitute', ':call <sid>SubstituteInColumn(<q-args>,<line1>,<line2>)',
        \ '-nargs=1 -range=%')
endfu
fu! <sid>Map(map, name, definition, ...) "{{{3
    let keyname = substitute(a:name, '[<>]', '', 'g')
    let expr = (exists("a:1") && a:1 == 'expr'  ? '<expr>' : '')
    if !get(g:, "csv_nomap_". tolower(keyname), 0)
        " All mappings are buffer local
        exe a:map "<buffer> <silent>". expr a:name a:definition
        " should already exists
        if a:map == 'nnoremap'
            let unmap = 'nunmap'
        elseif a:map == 'noremap' || a:map == 'map'
            let unmap = 'unmap'
        elseif a:map == 'vnoremap'
            let unmap = 'vunmap'
        elseif a:map == 'omap'
            let unmap = 'ounmap'
        elseif a:map == 'imap'
            let unmap = 'iunmap'
        elseif a:map == 'xnoremap'
            let unmap = 'xunmap'
        endif
        let b:undo_ftplugin .= "| " . unmap . " <buffer> " . a:name
    endif
endfu
fu! <sid>LocalCmd(name, definition, args) "{{{3
    if !exists(':'.a:name)
        exe "com! -buffer " a:args a:name a:definition
        let b:undo_ftplugin .= "| sil! delc " . a:name
    endif
    " Setup :CSV<Command> Aliases
    if a:name !~ '^CSV'
        call <sid>LocalCmd('CSV'.a:name, a:definition, a:args)
    endif
endfu
fu! <sid>Menu(enable) "{{{3
    if a:enable
        " Make a menu for the graphical vim
        amenu CSV.&Init\ Plugin             :CSVInit<cr>
        amenu CSV.SetUp\ &fixedwidth\ Cols  :CSVFixed<cr>
        amenu CSV.-sep1-                    <nul>
        amenu &CSV.&Column.&Number          :WhatColumn<cr>
        amenu CSV.Column.N&ame              :WhatColumn!<cr>
        amenu CSV.Column.&Highlight\ column :HiColumn<cr>
        amenu CSV.Column.&Remove\ highlight :HiColumn!<cr>
        amenu CSV.Column.&Delete            :DeleteColumn<cr>
        amenu CSV.Column.&Sort              :%Sort<cr>
        amenu CSV.Column.&Copy              :Column<cr>
        amenu CSV.Column.&Move              :%MoveColumn<cr>
        amenu CSV.Column.S&um               :%SumCol<cr>
        amenu CSV.Column.Analy&ze           :Analyze<cr>
        amenu CSV.Column.&Arrange           :%ArrangeCol<cr>
        amenu CSV.Column.&UnArrange         :%UnArrangeCol<cr>
        amenu CSV.Column.&Add               :%AddColumn<cr>
        amenu CSV.-sep2-                    <nul>
        amenu CSV.&Toggle\ Header           :HeaderToggle<cr>
        amenu CSV.&ConvertData              :ConvertData<cr>
        amenu CSV.Filters                   :Filters<cr>
        amenu CSV.Hide\ C&olumn             :VertFold<cr>
        amenu CSV.&New\ Record              :NewRecord<cr>
    else
        " just in case the Menu wasn't defined properly
        sil! amenu disable CSV
    endif
endfu
fu! <sid>SaveOptions(list) "{{{3
    let save = {}
    for item in a:list
        exe "let save.". item. " = &l:". item
    endfor
    return save
endfu
fu! <sid>NewDelimiter(newdelimiter, firstl, lastl) "{{{3
    let save = <sid>SaveOptions(['ro', 'ma'])
    if exists("b:csv_fixed_width_cols")
        call <sid>Warn("NewDelimiter does not work with fixed width column!")
        return
    endif
    if !&l:ma
        setl ma
    endif
    if &l:ro
        setl noro
    endif
    let delimiter = a:newdelimiter
    if a:newdelimiter is '\t'
        let delimiter="\t"
    endif
    let line=a:firstl
    while line <= a:lastl
        " Don't change delimiter for comments
        if getline(line) =~ '^\s*\V'. escape(b:csv_cmt[0], '\\')
            let line+=1
            continue
        endif
        let fields=split(getline(line), b:col . '\zs')
        " Remove field delimiter
        call map(fields, 'substitute(v:val, b:delimiter .
            \ ''\?$'' , "", "")')
        call setline(line, join(fields, delimiter))
        let line+=1
    endwhile
    " reset local buffer options
    for [key, value] in items(save)
        call setbufvar('', '&'. key, value)
    endfor
    "reinitialize the plugin
    if exists("g:csv_delim")
        let _delim = g:csv_delim
    endif
    let g:csv_delim = delimiter
    call <sid>Init(1,line('$'))
    if exists("_delim")
        let g:csv_delim = _delim
    else
        unlet g:csv_delim
    endif
    unlet! _delim
endfu
fu! <sid>IN(list, value) "{{{3
    for item in a:list
        if item == a:value
            return 1
        endif
    endfor
    return 0
endfu
fu! <sid>DuplicateRows(columnlist) "{{{3
    let duplicates = {}
    let cnt   = 0
    let line  = 1
    while line <= line('$')
        let key = ""
        let i = 1
        let content = getline(line)
        " Skip comments
        if content =~ '^\s*\V'. escape(b:csv_cmt[0], '\\')
            continue
        endif
        let cols = split(content, b:col. '\zs')
        for column in cols
            if <sid>IN(a:columnlist, i)
                let key .= column
            endif
            let i += 1
        endfor
        if has_key(duplicates, key) && cnt < 10
            call <sid>Warn("Duplicate Row ". line)
            let cnt += 1
        elseif has_key(duplicates, key)
            call <sid>Warn("More duplicate Rows after: ". line)
            call <sid>Warn("Aborting...")
            return
        else
            let duplicates[key] = 1
        endif
        let line += 1
    endwhile
    if cnt == 0
        call <sid>Warn("No Duplicate Row found!")
    endif
endfu
fu! <sid>CompleteColumnNr(A,L,P) "{{{3
    return join(range(1,<sid>MaxColumns()), "\n")
endfu
fu! <sid>CheckDuplicates(list) "{{{3
    let string = a:list
    if string =~ '\d\s\?-\s\?\d'
        let string = substitute(string, '\(\d\+\)\s\?-\s\?\(\d\+\)',
            \ '\=join(range(submatch(1),submatch(2)), ",")', '')
    endif
    let list=split(string, ',')
    call <sid>DuplicateRows(list)
endfu
fu! <sid>Transpose(line1, line2) "{{{3
    " Note: - Comments will be deleted.
    "       - Does not work with fixed-width columns
    if exists("b:csv_fixed_width")
        call <sid>Warn("Transposing does not work with fixed-width columns!")
        return
    endif
    let _wsv    = winsaveview()
    let TrailingDelim = 0

    if line('$') > 1
        let TrailingDelim = getline(1) =~ b:delimiter.'$'
    endif

    let pat = '^\s*\V'. escape(b:csv_cmt[0], '\\')

    try
        let columns = <sid>MaxColumns(a:line1)
    catch
        " No column, probably because of comment or empty line
        " so use the number of columns from the beginning of the file
        let columns = <sid>MaxColumns()
    endtry
    let matrix  = []
    for line in range(a:line1, a:line2)
        " Filter comments out
        if getline(line) =~ pat
            continue
        endif
        let r   = []
        for row in range(1,columns)
            let field = <sid>GetColumn(line, row, 0)
            call add(r, field)
        endfor
        call add(matrix, r)
    endfor
    unlet row

    " create new transposed matrix
    let transposed = []
    for row in matrix
        let i = 0
        for val in row
            if get(transposed, i, []) == []
                call add(transposed, [])
            endif
            if val[-1:] != b:delimiter
                let val .= b:delimiter
            endif
            call add(transposed[i], val)
            let i+=1
        endfor
    endfor
    " Save memory
    unlet! matrix
    call map(transposed, 'join(v:val, '''')')
    if !TrailingDelim
        call map(transposed, 'substitute(v:val, b:delimiter.''\?$'', "", "")')
    endif
    " filter out empty records
    call filter(transposed, 'v:val != b:delimiter')

    " Insert transposed data
    let delete_last_line = 0
    if a:line1 == 1 && a:line2 == line('$')
        let delete_last_line = 1
    endif
    exe a:line1. ",". a:line2. "d _"
    let first = (a:line1 > 0 ? (a:line1 - 1) : 0)
    call append(first, transposed)
    if delete_last_line
        sil $d _
    endif
    " save memory
    unlet! transposed
    call winrestview(_wsv)
endfu
fu! <sid>NrColumns(bang) "{{{3
      try
          let cols = empty(a:bang) ? <sid>MaxColumns() : <sid>MaxColumns(line('.'))
      catch
          " No column or comment line
          call <sid>Warn("No valid CSV Column!")
      endtry
    echo cols
endfu
fu! <sid>Tabularize(bang, first, last) "{{{3
    if match(split(&ft, '\.'),'csv') == -1
        call <sid>Warn("No CSV filetype, aborting!")
        return
    endif
    let _c = winsaveview()
    " Table delimiter definition "{{{4
    if !exists("s:td")
        let s:td = {
            \ 'hbar': (&enc =~# 'utf-8' ? '─' : '-'),
            \ 'vbar': (&enc =~# 'utf-8' ? '│' : '|'),
            \ 'scol': (&enc =~# 'utf-8' ? '├' : '|'),
            \ 'ecol': (&enc =~# 'utf-8' ? '┤' : '|'),
            \ 'ltop': (&enc =~# 'utf-8' ? '┌' : '+'),
            \ 'rtop': (&enc =~# 'utf-8' ? '┐' : '+'),
            \ 'lbot': (&enc =~# 'utf-8' ? '└' : '+'),
            \ 'rbot': (&enc =~# 'utf-8' ? '┘' : '+'),
            \ 'cros': (&enc =~# 'utf-8' ? '┼' : '+'),
            \ 'dhor': (&enc =~# 'utf-8' ? '┬' : '-'),
            \ 'uhor': (&enc =~# 'utf-8' ? '┴' : '-')
            \ }
    endif "}}}4
    if match(getline(a:first), '^'.s:td.ltop) > -1
        " Already tabularized, done
        call <sid>Warn("Looks already Tabularized, aborting!")
        return
    endif
    let _ma = &l:ma
    setl ma
    let colwidth = 0
    let adjust_last = 0
    call cursor(a:first,0)
    call <sid>CheckHeaderLine()
    let line=a:first
    if exists("g:csv_table_leftalign")
        let b:csv_arrange_leftalign = 1
    endif
    let newlines=[]
    let content=[]
    while line <= a:last
        if foldclosed(line) != -1
            let line = foldclosedend(line) + 1
            continue
        endif
        let curline = getline(line)
        call add(content, curline)
        if empty(split(curline, b:delimiter))
            " only empty delimiters, add one empty delimiter
            " (:NewDelimiter strips trailing delimiter
            let curline = repeat(b:delimiter, <sid>MaxColumns())
            call add(newlines, line)
            call setline(line, curline)
        endif
        let line+=1
    endw
    unlet! line
    let delim=b:delimiter
    new
    call setline(1,content)
    let b:delimiter=delim
    let csv_highlight_column = get(g:, 'csv_highlight_column', '')
    unlet! g:csv_highlight_column
    call <sid>Init(1,line('$'), 1)
    if exists("b:csv_fixed_width_cols")
        let cols=copy(b:csv_fixed_width_cols)
        let pat = join(map(cols, ' ''\(\%''. v:val. ''c\)'' '), '\|')
        let colwidth = strlen(substitute(getline('$'), '.', 'x', 'g'))
        let t=-1
        let b:col_width = []
        for item in b:csv_fixed_width_cols + [colwidth]
            if t > -1
                call add(b:col_width, item-t)
            endif
            let t = item
        endfor
    else
        " don't clear column width variable, might have been set in the
        " plugin!
        sil call <sid>ArrangeCol(1, line('$'), 0, -1)
        if !get(b:, 'csv_arrange_leftalign',0)
            for line in newlines
                let cline = getline(line)
                let cline = substitute(cline, '\s$', ' ', '')
                call setline(line, cline)
            endfor
            unlet! line
        endif
    endif

    if empty(b:col_width)
        call <sid>Warn('An error occured, aborting!')
        return
    endif
    if getline(a:first)[-1:] isnot? b:delimiter
        let b:col_width[-1] += 1
    endif
    let marginline = s:td.scol. join(map(copy(b:col_width), 'repeat(s:td.hbar, v:val)'), s:td.cros). s:td.ecol

    call <sid>NewDelimiter(s:td.vbar, 1, line('$'))
    "exe printf('sil %d,%ds/%s/%s/ge', a:first, (a:last+adjust_last),
    "    \ (exists("b:csv_fixed_width_cols") ? pat : b:delimiter ), s:td.vbar)
    " Add vertical bar in first column, if there isn't already one
    exe printf('sil %d,%ds/%s/%s/e', 1, line('$'),
        \ '^[^'. s:td.vbar. s:td.scol. ']', s:td.vbar.'&')
    " And add a final vertical bar, if there isn't one already
    exe printf('sil %d,%ds/%s/%s/e', 1, line('$'),
        \ '[^'. s:td.vbar. s:td.ecol. ']$', '&'. s:td.vbar)
    " Make nice intersection graphs
    let line = split(getline(1), s:td.vbar)
    call map(line, 'substitute(v:val, ''[^''.s:td.vbar. '']'', s:td.hbar, ''g'')')
    " Set top and bottom margins
    call append(0, s:td.ltop. join(line, s:td.dhor). s:td.rtop)
    call append(line('$'), s:td.lbot. join(line, s:td.uhor). s:td.rbot)

    if s:csv_fold_headerline > 0
        call append(1 + s:csv_fold_headerline, marginline)
        let adjust_last += 1
    endif
    " Syntax will be turned off, so disable this part
    "
    " Adjust headerline to header of new table
    "let b:csv_headerline = (exists('b:csv_headerline')?b:csv_headerline+2:3)
    "call <sid>CheckHeaderLine()
    " Adjust syntax highlighting
    "unlet! b:current_syntax
    "ru syntax/csv.vim

    if a:bang
        exe printf('sil %d,%ds/^%s\zs\n/&%s&/e', 1 + s:csv_fold_headerline, line('$') + adjust_last,
                    \ '[^'.s:td.scol. '][^'.s:td.hbar.'].*', marginline)
    endif

    syn clear
    let &l:ma = _ma
    if !empty(csv_highlight_column)
      let g:csv_highlight_column = csv_highlight_column
    endif
    call winrestview(_c)
endfu
fu! <sid>SubstituteInColumn(command, line1, line2) range "{{{3
    " Command can be something like 1,2/foobar/foobaz/ to replace in 1 and second column
    " Command can be something like /foobar/foobaz/ to replace in the current column
    " Command can be something like 1,$/foobar/foobaz/ to replace in all columns
    " Command can be something like 3/foobar/foobaz/flags to replace only in the 3rd column

    " Save position and search register
    let _wsv = winsaveview()
    let _search = [ '/', getreg('/'), getregtype('/')]
    let columns = []
    let maxcolnr = <sid>MaxColumns()
    let simple_s_command = 0 " when set to 1, we can simply use an :s command

    " try to split on '/' if it is not escaped or in a collection
    let cmd = split(a:command, '\%([\\]\|\[[^]]*\)\@<!/')
    if a:command !~? '^\%([$]\|\%(\d\+\)\%(,\%([0-9]\+\|[$]\)\)\?\)/' ||
                \ len(cmd) == 2 ||
                \ ((len(cmd) == 3 && cmd[2] =~# '^[&cgeiInp#l]\+$'))
        " No Column address given
        call add(columns, <sid>WColumn())
        let cmd = [columns[0]] + cmd "First item of cmd list contains address!
    elseif ((len(cmd) == 3 && cmd[2] !~# '^[&cgeiInp#l]\+$')
    \ || len(cmd) == 4)
        " command could be '1/foobbar/foobaz'
        " but also 'foobar/foobar/g'
        let columns = split(cmd[0], ',')
        if empty(columns)
            " No columns given? replace in current column only
            let columns[0] = <sid>WColumn()
        elseif columns[-1] == '$'
            let columns[-1] = maxcolnr
        endif
    else " not reached ?
        call add(columns, <sid>WColumn())
    endif

    try
        if len(cmd) == 1 || columns[0] =~ '\D' || (len(columns) == 2 && columns[1] =~ '\D')
            call <SID>Warn("Error! Usage :S [columns/]pattern/replace[/flags]")
            return
        endif

        if len(columns) == 2 && columns[0] == 1 && columns[1] == maxcolnr
            let simple_s_command = 1
        elseif len(columns) == 2
            let columns = range(columns[0], columns[1])
        endif

        let has_flags = len(cmd) == 4

        if simple_s_command
            while search(cmd[1])
                exe printf("%d,%ds/%s/%s%s", a:line1, a:line2, cmd[1], cmd[2], (has_flags ? '/'. cmd[3] : ''))
                if !has_flags || (has_flags && cmd[3] !~# 'g')
                    break
                endif
            endw
        else
            for colnr in columns
                let @/ = <sid>GetPat(colnr, maxcolnr, cmd[1], 1)
                while search(@/)
                    let curpos = getpos('.')
                    " safety check
                    if (<sid>WColumn() != colnr)
                      break
                    endif
                    if  len(split(getline('.'), '\zs')) > curpos[2] && <sid>GetCursorChar() is# b:delimiter
                      " Cursor is on delimiter and next char belongs to the
                      " next field, skip this match
                      norm! l
                      if (<sid>WColumn() != colnr)
                        break
                      endif
                      call setpos('.', curpos)
                    endif
                    exe printf("%d,%ds//%s%s", a:line1, a:line2, cmd[2], (has_flags ? '/'. cmd[3] : ''))
                    if !has_flags || (has_flags && cmd[3] !~# 'g')
                        break
                    endif
                endw
            endfor
        endif
    catch /^Vim\%((\a\+)\)\=:E486/
        " Pattern not found
        echohl Error
        echomsg "E486: Pattern not found in column " . colnr . ": " . pat
        if &vbs > 0
            echomsg substitute(v:exception, '^[^:]*:', '','')
        endif
        echohl Normal
    catch
        echohl Error
        "if &vbs > 0
            echomsg substitute(v:exception, '^[^:]*:', '','')
        "endif
        echohl Normal
    finally
        " Restore position and search register
        call winrestview(_wsv)
        call call('setreg', _search)
    endtry
endfu
fu! <sid>ColumnMode() "{{{3
    let mode = mode()
    if mode =~# 'R'
        " (virtual) Replace mode
        let new_line = (line('.') == line('$') ||
        \ (synIDattr(synIDtrans(synID(line("."), col("."), 1)), "name") =~? "comment"))
        return "\<ESC>g`[". (new_line ? "o" : "J".mode)
    else
        return "\<CR>"
    endif
endfu
fu! <sid>Timeout(start) "{{{3
    return localtime()-a:start < 2
endfu
fu! <sid>GetCursorChar() "{{{3
    let register = ['a', getreg('a'), getregtype('a')]
    try
      norm! v"ay
      let s=getreg('a')
      return s
    finally
      call call('setreg', register)
    endtry
endfu

fu! <sid>SameFieldRegion() "{{{3
    " visually select the region, that has the same value in the cursor field
    let col = <sid>WColumn()
    let max = <sid>MaxColumns()
    let field = <sid>GetColumn(line('.'), col, 0)
    let line = line('.')

    let limit = [line, line]
    " Search upwards and downwards from the current position and find the
    " limit of the current selection
    while line > 1
        let line -= 1
        if <sid>GetColumn(line, col, 0) ==# field
            let limit[0] = line
        else
            break
        endif
    endw
    let line = line('.')
    while line > 1 && line < line('$')
        let line += 1
        if <sid>GetColumn(line, col, 0) ==# field
            let limit[1] = line
        else
            break
        endif
    endw
    exe printf(':norm! %dGV%dG',limit[0],limit[1])
endfu


fu! CSV_CloseBuffer(buffer) "{{{3
    " Setup by SetupAutoCmd autocommand
    try
        if bufnr((a:buffer)+0) > -1
            exe a:buffer. "bw"
        endif
    catch /^Vim\%((\a\+)\)\=:E517/	" buffer already wiped
    " no-op
    finally
        augroup CSV_QuitPre
            au!
        augroup END
        augroup! CSV_QuitPre
    endtry
endfu
fu! CSV_SetSplitOptions(window) "{{{3
    if exists("s:local_stl")
        " local horizontal statusline
        for opt in items({'&nu': &l:nu, '&rnu': &l:rnu, '&fdc': &fdc})
            if opt[1] != getwinvar(a:window, opt[0])
                call setwinvar(a:window, opt[0], opt[1])
            endif
        endfor
        " Check statusline (airline might change it)
        if getwinvar(a:window, '&l:stl') != s:local_stl
            call setwinvar(a:window, '&stl', s:local_stl)
        endif
    endif
endfun
" Global functions "{{{2
fu! csv#EvalColumn(nr, func, first, last, ...) range "{{{3
    " Make sure, the function is called for the correct filetype.
    if match(split(&ft, '\.'), 'csv') == -1
        call <sid>Warn("File is no CSV file!")
        return
    endif
    let save = winsaveview()
    call <sid>CheckHeaderLine()
    let nr = matchstr(a:nr, '^\-\?\d\+')
    let col = (empty(nr) ? <sid>WColumn() : nr)
    if col == 0
        let col = 1
    endif
    " don't take the header line into consideration
    let start = a:first - 1 + s:csv_fold_headerline
    let stop  = a:last  - 1 + s:csv_fold_headerline

    let column = <sid>CopyCol('', col, '')[start : stop]
    " Delete delimiter
    call map(column, 'substitute(v:val, b:delimiter . "$", "", "g")')
    " Revmoe trailing whitespace
    call map(column, 'substitute(v:val, ''^\s\+$'', "", "g")')
    " Remove leading whitespace
    call map(column, 'substitute(v:val, ''^\s\+'', "", "g")')
    " Delete empty values
    " Leave this up to the function that does something
    " with each value
    "call filter(column, '!empty(v:val)')

    " parse the optional number format
    let format = matchstr(a:nr, '/[^/]*/')
    let s:additional={}
    call <sid>NumberFormat()
    if !empty(format)
        try
            let s = []
            " parse the optional number format
            let str = matchstr(format, '/\zs[^/]*\ze/', 0, start)
            let s = matchlist(str, '\(.\)\?:\(.\)\?')[1:2]
            if empty(s)
                " Number format wrong
                call <sid>Warn("Numberformat wrong, needs to be /x:y/!")
                return ''
            endif
            if !empty(s[0])
                let s:nr_format[0] = s[0]
            endif
            if !empty(s[1])
                let s:nr_format[1] = s[1]
            endif
        endtry
    endif
    let distinct = matchstr(a:nr, '\<distinct\>')
    if !empty(distinct)
      let s:additional.distinct=1
    endif
    if function(a:func) is# function("\<snr>".s:SID."_MaxColumn")
      let s:additional.ismax = a:1
    endif
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
" return field index (x,y) with leading/trailing whitespace and trailing
" delimiter stripped (only when a:0 is not given)
fu! CSVField(x, y, ...) "{{{3
    if &ft != 'csv'
        return
    endif
    let y = a:y - 1
    let x = (a:x < 0 ? 0 : a:x)
    let orig = !empty(a:0)
    let y = (y < 0 ? 0 : y)
    let x = (x > (<sid>MaxColumns()) ? (<sid>MaxColumns()) : x)
    let col = <sid>CopyCol('',x,'')
    if !orig
    " remove leading and trainling whitespace and the delimiter
        return matchstr(col[y], '^\s*\zs.\{-}\ze\s*'.b:delimiter.'\?$')
    else
        return col[y]
    endif
endfu
" return current column number (if a:0 is given, returns the name
fu! CSVCol(...) "{{{3
    return <sid>WColumn(a:0)
endfu
fu! CSVPat(colnr, ...) "{{{3
    " Make sure, we are working in a csv file
    if &ft != 'csv'
        return ''
    endif
    " encapsulates GetPat(), that returns the search pattern for a
    " given column and tries to set the cursor at the specific position
    let pat = <sid>GetPat(a:colnr, <SID>MaxColumns(), a:0 ? a:1 : '.*', 1)
    "let pos = match(pat, '.*\\ze') + 1
    " Try to set the cursor at the beginning of the pattern
    " does not work
    "call setcmdpos(pos)
    return pat
endfu
fu! CSVSum(col, fmt, first, last) "{{{3
    let first = a:first
    let last  = a:last
    if empty(first)
        let first = 1
    endif
    if empty(last)
        let last = line('$')
    endif
    return csv#EvalColumn(a:col, '<sid>SumColumn', first, last)
endfu
fu! CSVMax(col, fmt, first, last) "{{{3
    let first = a:first
    let last  = a:last
    if empty(first)
        let first = 1
    endif
    if empty(last)
        let last = line('$')
    endif
    return csv#EvalColumn(a:col, '<sid>MaxColumn', first, last, 1)
endfu
fu! CSVMin(col, fmt, first, last) "{{{3
    let first = a:first
    let last  = a:last
    if empty(first)
        let first = 1
    endif
    if empty(last)
        let last = line('$')
    endif
    return csv#EvalColumn(a:col, '<sid>MaxColumn', first, last, 0)
endfu
fu! CSVCount(col, fmt, first, last, ...) "{{{3
    let first = a:first
    let last  = a:last
    let distinct = 0
    if empty(first)
        let first = 1
    endif
    if empty(last)
        let last = line('$')
    endif
    if !exists('s:additional')
      let s:additional = {}
    endif
    if exists("a:1") &&  !empty(a:1)
      let s:additional['distinct'] = 1
    endif
    let result=csv#EvalColumn(a:col, '<sid>CountColumn', first, last, distinct)
    unlet! s:additional['distinct']
    return (empty(result) ? 0 : result)
endfu
fu! CSV_WCol(...) "{{{3
    " Needed for airline
    try
        if line('$') == 1 && empty(getline(1))
            " Empty file
            return ''
        elseif exists("a:1") && (a:1 == 'Name' || a:1 == 1)
            return printf("%s", <sid>WColumn(1))
        else
            return printf(" %d/%d", <SID>WColumn(), <SID>MaxColumns())
        endif
    catch
        return ''
    endtry
endfun

" Initialize Plugin "{{{2
let b:csv_start = exists("b:csv_start") ? b:csv_start : 1
let b:csv_end   = exists("b:csv_end") ? b:csv_end : line('$')

call <SID>Init(b:csv_start, b:csv_end)
let &cpo = s:cpo_save
unlet s:cpo_save

" Vim Modeline " {{{2
" vim: set foldmethod=marker et:
doc/ft-csv.txt	[[[1
1923
*ft-csv.txt*	For Vim version 7.4	Last Change: Thu, 15 Jan 2015

Author:		Christian Brabandt <cb@256bit.org>
Version:	0.31
Homepage:	http://www.vim.org/scripts/script.php?script_id=2830

The VIM LICENSE applies to the CSV filetype plugin (see |copyright|).
NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK.
                                                           *csv-toc*
1. Introduction.................................|csv-intro|
2. Installation.................................|csv-installation|
3. CSV Commands.................................|csv-commands|
    3.1 WhatColumn..............................|WhatColumn_CSV|
    3.2 NrColumns...............................|NrColumns_CSV|
    3.3 SearchInColumn..........................|SearchInColumn_CSV|
    3.4 HiColumn................................|HiColumn_CSV|
    3.5 ArrangeColumn...........................|ArrangeColumn_CSV|
    3.6 UnArrangeColumn.........................|UnArrangeColumn_CSV|
    3.7 DeleteColumn............................|DeleteColumn_CSV|
    3.8 InitCSV.................................|InitCSV|
    3.9 Header..................................|Header_CSV|
    3.10 Sort...................................|Sort_CSV|
    3.11 CopyColumn.............................|Copy_CSV|
    3.12 MoveColumn.............................|MoveCol_CSV|
    3.13 Sum of a column........................|SumCol_CSV|
    3.14 Create new records ....................|NewRecord_CSV|
    3.15 Change the delimiter...................|NewDelimiter_CSV|
    3.16 Check for duplicate records............|Duplicate_CSV|
    3.17 Normal mode commands...................|csv-mapping|
    3.18 Convert CSV file.......................|csv-convert|
    3.19 Dynamic filters........................|csv-filter|
    3.20 Analyze a column.......................|csv-analyze|
    3.21 Vertical Folding.......................|csv-vertfold|
    3.22 Transposing columns....................|csv-transpose|
    3.23 Transforming into a table..............|csv-tabularize|
    3.24 Add new empty columns..................|AddColumn_CSV|
    3.25 Substitute in columns..................|Substitute_CSV|
    3.26 Count values inside a column...........|Count_CSV|
    3.27 Maximum/Minimum values ................|MaxCol_CSV|
4. CSV Filetype configuration...................|csv-configuration|
    4.1 Delimiter...............................|csv-delimiter|
    4.2 Column..................................|csv-column|
    4.3 HiGroup.................................|csv-higroup|
    4.4 Strict Columns..........................|csv-strict|
    4.5 Concealing..............................|csv-conceal|
    4.6 Newlines................................|csv-newline|
    4.7 Highlight column automatically..........|csv-hicol|
    4.8 Fixed width columns.....................|csv-fixedwidth|
        4.8.1 Manual setup
        4.8.2 Setup using a Wizard
    4.9 CSV Header lines........................|csv-header|
    4.10 Number format..........................|csv-nrformat|
    4.11 Move folded lines......................|csv-move-folds|
    4.12 Using Comments.........................|csv-comments|
5. Functions....................................|CSV-Functions|
    5.1 CSVPat()................................|CSVPat()|
    5.2 CSVField()..............................|CSVField()|
    5.3 CSVCol()................................|CSVCol()|
    5.4 CSVCount()..............................|CSVCount()|
    5.4 CSVMax()................................|CSVMax()|
    5.4 CSVMin()................................|CSVMin()|
6. CSV Tips and Tricks..........................|csv-tips|
    6.1 Statusline..............................|csv-stl|
    6.2 Slow CSV plugin.........................|csv-slow|
    6.3 Defining custom aggregate functions.....|csv-aggregate-functions|
    6.4 Autocommand on opening/closing files....|csv-arrange-autocmd|
    6.5 CSV Syntax error........................|csv-syntax-error|
    6.6 Calculating new column values...........|csv-calculate-column|
7. CSV Changelog................................|csv-changelog|

==============================================================================
1. Introduction                                                    *csv-intro*

This plugin is used for handling column separated data with Vim. Usually those
files are called csv files and use the ',' as delimiter, though sometimes they
use e.g. the '|' or ';' as delimiter and there also exists fixedwidth columns.
The aim of this plugin is to ease handling these kinds of files.

This is a filetype plugin for CSV files. It was heavily influenced by
the Vim Wiki Tip667 (http://vim.wikia.com/wiki/VimTip667), though it
works differently. For instructions on installing this file, type
:help add-local-help |add-local-help| inside Vim. For a screenshot, of
how the plugin can be used, see http://www.256bit.org/~chrisbra/csv.gif

==============================================================================
2. Installation						*csv-installation*

In order to have vim automatically detect csv files, you need to have
|ftplugins| enabled (e.g. by having this line in your |.vimrc| file: >

   :filetype plugin on

<
The plugin already sets up some logic to detect CSV files. By default,
the plugin recognizes *.csv and *.dat files as CSV filetype. In order that the
CSV filetype plugin is loaded correctly, vim needs to be enabled to load
|filetype-plugins|. This can be ensured by putting a line like this in your
|.vimrc|: >
    :filetype plugin on
<
(see also |filetype-plugin-on|).

In case this did not work, you need to setup vim like this:

To have Vim automatically detect csv files, you need to do the following.

   1) Create your user runtime directory if you do not have one yet. This
      directory needs to be in your 'runtime' path. In Unix this would
      typically the ~/.vim directory, while in Windows this is usually your
      ~/vimfiles directory. Use :echo expand("~") to find out, what Vim thinks
      your user directory is.
      To create this directory, you can do: >

      :!mkdir ~/.vim
<
      for Unix and >

      :!mkdir ~/vimfiles
<
      for Windows.

   2) In that directory you create a file that will detect csv files. >

    if exists("did_load_csvfiletype")
      finish
    endif
    let did_load_csvfiletype=1

    augroup filetypedetect
      au! BufRead,BufNewFile *.csv,*.dat	setfiletype csv
    augroup END
<
      You save this file as "filetype.vim" in your user runtime diretory: >

        :w ~/.vim/filetype.vim
<
   3) To be able to use your new filetype.vim detection, you need to restart
      Vim. Vim will then  load the csv filetype plugin for all files whose
      names end with .csv.

==============================================================================
3. Commands							*csv-commands*

The CSV ftplugin provides several Commands. All commands are also provided
with the prefix :CSV (e.g. |:CSVNrColumns|)

                                                            *:CSVWhatColumn*
3.1 WhatColumn                                                *WhatColumn_CSV*
--------------

If you would like to know, on which column the cursor is, use >
    :WhatColumn
<
or >
    :CSVWhatColumn
<
Use the bang attribute, if you have a heading in the first line and you want
to know the name of the column in which the cursor is: >
    :WhatColumn!
<
                                                            *:CSVNrColumns*
3.2 NrColumns                                                 *NrColumns_CSV*
--------------

`:NrColumns` and `:CSVNrColumns` outputs the maximum number of columns
available. It does this by testing the first 10 lines for the number of
columns. This usually should be enough. If you use the '!' attribute, it
outputs the number of columns in the current line.

                                                        *:CSVSearchInColumn*
3.3 SearchInColumn                                        *SearchInColumn_CSV*
------------------

Use `:SearchInColumn` or `:CSVSearchInColumn` to search for a pattern within a
specific column. The usage is: >

    :SearchInColumn [<nr>] /{pat}/
<

So if you would like to search in Column 1 for the word foobar, you enter >

    :SearchInColumn 1 /foobar/

Instead of / as delimiter, you can use any other delimiter you like. If you
don't enter a column, the current column will be used.

                                                            *:CSVHiColumn*
3.4 HiColumn                                                    *HiColumn_CSV*
------------

`:HiColumn` or `:CSVHiColumn` <nr> can be used to highlight Column <nr>.
Currently the plugin uses the WildMenu Highlight Group. If you would like to
change this, you need to define the variable |g:csv_hiGroup|.

If you do not specify a <nr>, HiColumn will highlight the column on which the
cursor is. Use >

    :HiColumn!

to remove any highlighting.

If you want to automatically highlight a column, see |csv-hicol|

                                            *:ArrangeColumn* *:CSVArrangeColumn*
3.5 ArrangeColumn                                          *ArrangeColumn_CSV*
-----------------

If you would like all columns to be visually arranged, you can use the
`:ArrangeColumn` or `:CSVArrangeColumn` command: >

    :[range]ArrangeColumn[!] [<Row>]

Beware, that this will change your file and depending on the size of
your file may slow down Vim significantly. This is highly experimental.
:ArrangeCommand will try to vertically align all columns by their maximum
column size. While the command is run, a progressbar in the statusline 'stl'
will be shown.

Use the bang attribute to force recalculating the column width. This is
slower, but especially if you have modified the file, this will correctly
calculate the width of each column so that they can be correctly aligned. If
no column width has been calculated before, the width will be calculated, even
if the '!' has not been given.

If <Row> is given, will use the Row, to calculate the width, else will
calculate the maximum of at least the first 10,000 rows to calculate the
width. The limit of 10,000 is set to speed up the processing and can be
overriden by setting the "b:csv_arrange_use_all_rows" variable (see below).

If [range] is not given, it defaults to the current line.

By default, the columns will be righ-aligned. If you want a different
alignment you need to specify this through the b:csv_arrange_align variable.
This is a string of flags ('r': right align, 'l': left align, 'c': center
alignment, '.': decimal alignment) where each flag defines the alignment for
a particular column (starting from left). Missing columns will be right aligned.
So this: >

    :let b:csv_arrange_align = 'lc.'
<
Will left-align the first column, center align the second column, decimal
align the third column and all following columns right align. (Note: decimal
aligning might slow down Vim and additionally, if the value is no decimal
number it will be right aligned).
If you change the alignment parameter, you need to use the "!" attribute, the
next time you run the |:ArrangeCol| command, otherwise for performance
reasons, it won't be considered.

Note, arranging the columns can be very slow on large files or many columns (see
|csv-slow| on how to increase performance for this command). For large files,
calculating the column width can take long and take a consierable amount of
memory. Therefore, the csv plugin will at most check 10.000 lines for the
width. Set the variable b:csv_arrange_use_all_rows to 1 to use all records: >

    :let b:csv_arrange_use_all_rows = 1
<
(this could however in the worst case lead to a crash).

To disable the statusline progressbar set the variable g:csv_no_progress: >

    :let g:csv_no_progress = 1
<
This will disable the progressbar and slightly improve performance (since no
additional redraws are needed).

Note: this command does not work for fixed width columns |csv-fixedwidth|

See also |csv-arrange-autocmd| on how to have vim automaticaly arrange a CSV
file upon entering it.

                                                        *:CSVUnArrangeColumn*
3.6 UnArrangeColumn                                    *UnArrangeColumn_CSV*
-----------------

If you would like to undo a previous :ArrangeColumn command, you can use this
`:UnArrangeColumn` or `:CSVUnArrangeColumn` command: >

    :[range]UnArrangeColumn

Beware, that is no exact undo of the :ArrangeColumn command, since it strips
away all leading blanks for each column. So if previously a column contained
only some blanks, this command will strip all blanks.

If [range] is given, it defaults to the current line.

                                                        *:CSVDeleteColumn*
3.7 DeleteColumn                                           *DeleteColumn_CSV*
----------------

The command `:DeleteColumn` or `:CSVDeleteColumn` can be used to delete a specific column. >

    :DeleteColumn 2

will delete column 2.

If you don't specify a column number, it will delete the column on which the
cursor is. Alternatively, you can also specify a search string. The plugin
will then delete all columns that match the pattern: >

    :DeleteColumn /foobar
<
will delete all columns where the pattern "foobar" matches.

                                                                *:CSVInit*
3.8 CSVInit
-----------
Reinitialize the Plugin. Use this, if you have changed the configuration
of the plugin (see |csv-configuration| ).
If you use the bang (!) attribute, it will keep the b:delimiter configuration
variable.

                                                                *:CSVHeader*
3.9 Header lines						 *Header_CSV*
----------------
The `:Header` or `:CSVHeader` command splits the csv-buffer and adds a window,
that holds a small fraction of the csv file. This is useful, if the first line
contains some kind of a heading and you want always to display it. This works
similar to fixing a certain line at the top. As optional argument, you can
give the number of columns from the top, that shall be displayed. By default,
1 is used (You can define youre own default by setting the b:csv_headerline
variable, see |csv-header|). Use the '!' to close this window. So this >

    :Header 3

opens at the top a split window, that holds the first 3 lines, is fixed
and horizontally 'scrollbind'ed to the csv window and highlighted using the
CSVHeaderLine highlighting.
To close the header window, use >

    :Header!

Note, this won't work with linebreaks in the column.

Note also, that if you already have a horizontal header window (|VHeader_CSV|),
this command will close the horizontal Header window. This is because of a
limitation of Vim itsself, which doesn't allow to sync the scrolling between
two windows horizontally and at the same time have another window only sync
its scrolling vertically.

Note: this command does not work for fixed width columns |csv-fixedwidth|

                                                *:CSVVHeader* *VHeader_CSV*
If you want a vertical header line, use `:VHeader` or `:CSVVHeader`. This works
similar to the |Header_CSV| command, except that it will open a vertical split
window with the first column always visible. It will always open the first
column in the new split window. Use the '!' to close the window. If you
specify a count, that many columns will be visible (default: the first). Add
the bang to the count, if you only want the specific column to be visible.
>
    :VHeader 2
<
This will open a vertical split window containing the first 2 columns, while
>
    :VHeader 2!
<
Opens a new vertical split window containing only the 2 second column.

Note, this won't work with linebreaks in the column.
Note also: this command does not work for fixed width columns |csv-fixedwidth|


                                        *:CSVVHeaderToggle* *:CSVHeaderToggle*
                                        *VHeaderToggle_CSV* *HeaderToggle_CSV*
Use the `:HeaderToggle` and `:VHeaderToggle` command to toggle displaying the
horizontal or vertical header line. Alternatively, use `:CSVHeaderToggle` or
`:CSVVHeaderToggle`


                                                                *:CSVSort*
3.10 Sort							*Sort_CSV*
---------
The command `:Sort` or `:CSVSort` can be used to sort the csv file on a
certain column. If no range is given, is sorts the whole file. Specify the
column number to sort on as argument. Use the '!' attribute to reverse the
sort order. For example, the following command sorts line 1 til 10 on the 3
column >

    :1,10Sort 3

While this command >

    :1,10Sort! 3

reverses the order based on column 3.

The column number can be optionally followed by any of the flags [i], [n],
[x] and [o] for [i]gnoring case, sorting by [n]umeric, he[x]adecimal
or [o]ctal value.

When no column number is given, it will sort by the column, on which the
cursor is currently.

                                                                *:CSVColumn*
3.11 Copy Column        					 *Copy_CSV*
----------------
If you need to copy a specific column, you can use the command `:CSVColumn` or
`:Column` >

    :[N]Column [a]

Copy column N into register a. This will copy all the values, that are
not folded-away (|csv-filter|) and skip comments.

If you don't specify N, the column of the current cursor position is used.
If no register is given, the default register
|quotequote| is used.

                                                                *:CSVMoveCol*
3.12 Move A Column        					 *MoveCol_CSV*
------------------
You can move one column to the right of another column by using the
`:CSVMoveColumn` or `:MoveColumn` command >

    :[range]MoveColumn [source] [dest]

This moves the column number source to the right of column nr destination. If
both arguments are not given, move the column on which the cursor is to the
right of the current last column. If [range] is not given, MoveColumn moves
the entire column, otherwise, it moves the columns only for the lines within
the range, e.g. given that your first line is a header line, which you don't
want to change >

    :2,$MoveColumn 1 $

this would move column 1 behind the last column, while keeping the header line
as is.


                                                                *:CSVSumCol*
3.13 Sum of a Column        					 *SumCol_CSV*
--------------------
You can let Vim output the sum of a column using the `:CSVSumCol` or `:SumCol`
command >

    :[range]SumCol [nr] [/format/]

This outputs the result of the column <nr> within the range given. If no range
is given, this will calculate the sum of the whole column. If <nr> is not
given, this calculates the sum for the column the cursor is on. Note, that the
delimiter will be stripped away from each value and also empty values won't be
considered.

By default, Vim uses the a numerical format that uses the '.' as decimal
separator while there is no thousands separator. If youre file contains
the numbers in a different format, you can use the /format/ option to specify
a different thousands separator or a different decimal separator. The format
needs to be specified like this:
    /x:y/
where 'x' defines the thousands separator and y defines the decimal
separator and each one is optional. This means, that >

    :SumCol 1 /:,/

uses the default thousands separator and ',' as the decimal separator and >

    :SumCol 2 / :./

uses the Space as thousands separator and the '.' as decimal separator.

Note, if you Vim is compiled without floating point number format (|+float|),
Vim will only aggregate the integer part and therefore won't use the 'y'
argument in the /format/ specifier.

See also |csv-aggregate-functions|

                                                            *:CSVNewRecord*
3.14 Create new Records                                      *NewRecord_CSV*
-----------------------
If you want to create one or several records, you can use the `:NewRecord` or
`:CSVNewRecord` command: >

    :[range]NewRecord [count]

This will create in each line given by range [count] number of new empty
records. If [range] is not specified, creates a new line below the line the
cursor is on and if count is not given, it defaults to 1.


                                                            *:CSVNewDelimiter*
3.15 Change the delimiter                                    *NewDelimiter_CSV*
-------------------------
If you want to change the field delimiter of your file you can use the
`:CSVNewDelimiter` or `:NewDelimiter` command: >

    :NewDelimiter char

This changes the field delimiter of your file to the new delimiter "char".
Note: Will remove trailing delimiters.

                                                            *:CSVDuplicate*
3.16 Check for duplicate records                            *Duplicate_CSV*
--------------------------------
If you want to check the file for duplicate records, use the command
`:Duplicate` or `:CSVDuplicate`: >

    :Duplicate columnlist
<

Columnlist needs to be a numeric comma-separated list of all columns that you
want to check. You can also use a range like '2-5' which means the plugin
should check columns 2,3,4 and 5.

If the plugin finds a duplicate records, it outputs its line number (but it
only does that at most 10 times).

3.17 Normal mode commands					 *csv-mapping*
-------------------------
The csv filetype plugin redefines the following keys as:

<C-Right> or L or W	Move [count] field forwards

<C-Left> or E or H	Move [count] field backwards (but see |csv-mapping-H| 
                        for the movement of H).

<Up> or K		Move [count] lines upwards within the same column

<Down> or J		Move [count] lines downwards within the same column

<Enter>                 Dynamically fold all lines away, that don't match
                        the value in the current column. See |csv-filter|

                        In |Replace-mode| and |Virtual-Replace-mode| does not
                        create a new row, but instead moves the cursor to the
                        beginning of the same column, one more line below.

<Space>                 Dynamically fold all lines away, that match
                        the value in the current column. See |csv-filter|

<BS>                    Remove last item from the dynamic filter.
                        See |csv-filter|

                                                    *csv-mapping-H*
Note how the mapping of 'H' differs from 'E'

H step fields backwards but also stops at where the content of the columns
begins.

If you look into this example (with the cursor being '|')

    aaa,   bbbb,|ccc `

Pressing 'H' moves to

    aaa,   |bbbb,ccc `

Pressing 'H' again moves to

    aaa,|   bbbb,ccc `

Pressing 'H' again moves to 

    |aaa,   bbbb,ccc `

While with 'E', the cursor moves to: 

     aaa,|  bbbb,ccc `

and pressing  'E' again, it would move directly to 

    |aaa,   bbbb,ccc `

                                                            *csv-textobjects*
Also, the csv plugin defines these text-object:

if                      Inner Field (contains everything up to the delimiter)
af                      Outer Field (contains everything up to and including
                        the delimiter)
iL                      Inner Line (visually linewise select all lines, that
                        has the same value at the cursor's column)

Note, that the <BS>, <CR>, K and J overlap Vim's default mapping for |<CR>|,
|<BS>|, |J| and |K| respectively. Therefore, this functionality has been
mapped to a sane default of <Localleader>J and <LocalLeader>K. If you haven't
changed the |<Leader>| or |<LocalLeader>| variables, those the <Localleader>
is equival to a single backslash '\', e.g. \K would run the lookup function on
the word under the cursor and \J would join this line with the previous line.

If you want to prevent the mapping of keys, simply set the global variable
g:csv_nomap_<key> to 1, e.g. to prevent mapping of <CR> in csv files, put >

    let g:csv_nomap_cr = 1
<
into your |.vimrc|. Note, the keyname must be lower case.


                                           *:CSVConvertData* *ConvertData_CSV*
3.18 Converting a CSV File					 *csv-convert*
--------------------------
You can convert your CSV file to a different format with the `:ConvertData`
or `:CSVConvertData` command >

    ConvertData

Use the the ! attribute, to convert your data without the delimiter.

This command will interactively ask you for the definition of 3 variables.
After which it will convert your csv file into a new format, defined by those
3 variables and open the newly created file in a new window. Those 3 variables
define how the text converted.

First, You need to define what has to be done, before converting your column
data. That is done with the "pre convert" variable. The content of this
variable will be put in front of the new document.

Second, you define, what has to be put after the converted content of your
column data. This happens with the "post convert" variable. Basically the
contents of this variable will be put after processing the columns.

Last, the columns need to be converted into your format. For this you can
specify a printf() format like string, that defines how your data will be
converted. You can use '%s' to specify placeholders, which will later be
replaced by the content of the actual column.

For example, suppose you want to convert your data into HTML, then you first
call the >

    :ConvertData

At this point, Vim will ask you for input. First, you need to specify, what
needs to be done before processing the data:

    Pre convert text: <html><body><table> `

This would specify to put the HTML Header before the actual data can be
processed. If the variable g:csv_pre_convert is already defined, Vim will
already show you its' content as default value. Simply pressing Enter will use
this data. After that, Vim asks, what the end of the converted file needs to
look like:

    Post convert text: </table></body></html> `

So here you are defining how to finish up the HTML file. If the variable
g:csv_post_convert is already defined, Vim will already show you its' content
as default value which you can confirm by pressing Enter. Last, you define,
how your columns need to be converted. Again, Vim asks you for how to do that:

    Converted text, use %s for column input: `
    <tr><td>%s</td><td>%s</td><td>%s</td></tr>

This time, you can use '%s' expandos. They tell Vim, that they need to be
replaced by the actual content of your file. It does by going from the first
column in your file and replacing it with the corresponding %s in that order.
If there are less '%s' expandos then columns in your file, Vim will skip the
columns, that are not used. Again If the variable g:csv_convert is already
defined, Vim will already show you its' content as default value which you can
confirm by pressing Enter.

After you hit Enter, Vim will convert your data and put it into a new window.
It may look like this:

    <html><body><table> `
    <tr><td>1,</td><td>2,</td><td>3,</td></tr> `
    <tr><td>2,</td><td>2,</td><td>4,</td></tr> `
    </table></body></html> `

Note, this is only a proof of concept. A better version of converting your
data to HTML is bundled with Vim (|:TOhtml|).

But may be you want your data converted into SQL-insert statements. That could
be done like this: >

    ConvertData!
<
    Pre convert text: `

(Leave this empty. It won't be used).

    Post convert text: Commit; `

After inserting the data, commit it into the database.

    Converted text, use %s for column input: `
    Insert into table foobar values ('%s', '%s', %s); `

Note, that the last argument is not included within single quotation marks,
since in this case the data is assumed to be integer and won't need to be
quoted for the database.

After hitting Enter, a new Window will be opened, which might look like this:

    Insert into table foobar values('Foobar', '2', 2011); `
    Insert into table foobar values('Bar', '1', 2011); `
    Commit; `

Since the command was used with the bang attribute (!), the converted data
doesn't include the column delimiters.

Now you can copy it into your database, or further manipulate it.

3.19 Dynamic filters      					 *csv-filter*
--------------------
If you are on a value and only want to see lines that have the same value in
this column, you can dynamically filter the file and fold away all lines not
matching the value in the current column. To do so, simply press <CR> (Enter).
Now Vim will fold away all lines, that don't have the same value in this
particular row. Note, that leading blanks and the delimiter is removed and the
value is used literally when comparing with other values. If you press <Space>
on the value, all fields having the same value will be folded away.

The way this is done is, that the value from the column is extracted and a
regular expression for that field is generated from it. In the end this
regular expression is used for folding the file.

A subsequent <CR> or <Space> on another value, will add this value to the
current applied filter (this is like using the logical AND between the
currently active filter and the new value). To remove the last item from the
filter, press <BS> (backspace). If all items from the filter are removed,
folding will be disabled.

If some command messes up the folding, you can use |zX| to have the folding
being reinitialized.

By default, the first line is assumed to be the header and won't be folded
away. See also |csv-header|.

If you have set the g:csv_move_folds variable and the file is modifiable, all
folded lines will be moved to the end of the file, so you can view all
non-folded lines as one consecutive area  (see also |csv-move-folds|)

                                           *:CSVFilter* *:Filter* *Filter_CSV*
To see the active filters, you can use the `:Filter` or `:CSVFilter` command.
This will show you a small summary, of what filters are active and looks like
this:

Nr      Match   Col           Name              Value ~
===================================================== `
01       -       07          Price              23.10 `
02       +       08            Qty                 10 `

This means, there are two filters active. The current active filter is on
column 7 (column name is Price) and all values that match 23.10 will be folded
away AND all values that don't match a value of 10 in the QTY column will also
be folded away.
When removing one item from the filter by pressing <BS>, it will always remove
the last item (highest number in NR column) from the active filter values.

Note, that depending on your csv file and the number of filters you used,
applying the filter might actually slow down vim, because a complex regular
expression is generated that is applied by the fold expression. Look into the
@/ (|quote_/|) register to see its value.

Use |zX| to apply the current value of your search register as filter. Use >

    :Filters!

to reapply all values from the current active filter and fold non-matching
items away.

                                                    *:CSVAnalyze* *Analyze_CSV*
3.20 Analyze a Column       					 *csv-analyze*
---------------------
If you'd like to know, how the values are distributed among a certain column,
you can use the `:CSVAnalyze` or `:Analyze` command. So >

    :Analyze 3

outputs the the distribution of the top 5 values in column 3. This looks like
this:

Nr      Count    %      Value ~
============================= `
01      20      50%     10    `
02      10      25%     2     `
03      10      25%     5     `

This tells you, that the the value '10' in column 3 occurs 50% of the time
(exactly 20 times) and the other 2 values '2' and '5' occur only 10 times, so
25% of the time.

                                                 *:CSVVertFold* *VertFold_CSV*
3.21 Vertical Folding       					 *csv-vertfold*
---------------------
Sometimes, you want to hide away certain columns to better view only certain
columns without having to horizontally scroll. You can use the `:CSVVertFold`
or `:VertFold` command to hide certain columns: >

    :VertFold [<nr>]
<
This will hide all columns from the first until the number entered. It
currently can't hide single columns, because of the way, syntax highlighting
is used. This command uses the conceal-feature |:syn-conceal| to hide away
those columns. If no nr is given, hides all columns from the beginning till
the current column.

Use >
    :VertFold!

to display all hidden columns again.

                                                *:CSVTranspose* *Transpose_CSV*
3.22 Transposing a column                                      *csv-transpose*
-------------------------
Transposing means to exchange rows and columns. You can transpose the csv
file, using the `:CSVTranspose` or `:Transpose` : >

    :[range]Transpose
<
command. If [range] is not given, it will transpose the complete file,
otherwise it will only transpose the lines in the range given. Note, comments
will be deleted and transposing does not work with fixed-width columns.

                                                          *:CSVTabularize*
3.23 Transforming into a table                      *:CSVTable* *csv-tabularize*
------------------------------
You  can also transform your csv data into a visual table, using the
`:CSVTabularize` or `:CSVTable`: >

    :CSVTabularize
<
command. This will make a frame around your csv data and substitute all
delimiters by '|', so that it will look like a table.

e.g. consider this data: >
>
First,Second,Third ~
10,5,2 `
5,2,10 `
2,10,5 `
10,5,2 `

This will be transformed into: >

    |---------------------|
    | First| Second| Third|
    |------|-------|------|
    |    10|      5|     2|
    |     5|      2|    10|
    |     2|     10|     5|
    |    10|      5|     2|
    |---------------------|

If your Vim uses an unicode 'encoding', the plugin makes a nice table using
special unicode drawing glyphs (but it might be possible, that those chars are
not being displayed correctly, if either your terminal or the gui font doesn't
have characters for those codepoints). If you use the bang form, each row will
be separated by a line.
You can also visual select a range of lines and use :Tabularize to have only
that range converted into a nice ascii table. Else it try to use the current
paragraph and try to transform it.

If you use the '!' bang argument, between each row, a line will be drawn.

In csv files, you can also use the :CSVTabularize command, in different
filetypes you can use the :CSVTable command (and is available as plugin so it
will be available for non-CSV filetypes).

Set the variable g:csv_table_leftalign=1 if you want the columns to be
leftaligned.

Note: Each row must contain exactly as many fields as columns.

                                                            *:CSVAddColumn*
3.24 Add new empty columns                                   *AddColumn_CSV*
--------------------------
If you want to add new empty columns to your file you can use the
`:CSVAddColumn` or `:AddColumn` command: >

    :[range]AddColumn [column] [count]

By default, this works for the whole file, but you can give a different range
to which the AddColumn command applies. If no arguments are given, the new
empty column will be added after the column on which the cursor is. You can
however add as first argument the column number after which the new column
needs to be added.

Additionally, you can also add a count number to add several columns at once
after the specified column number. You 0 for the column number, if you want to
add several columns after the current column.

                                                            *:CSVSubstitute*
3.25 Substitute in columns                                  *Substitute_CSV*
--------------------------
If you want to substitute only in specific columns, you can use the
`:CSVSubstitute` or `:Substitute` command: >

    :[range]Substitute [column/]pattern/string[/flags]

This means in the range and within the given columns replace pattern by
string. This works bascially like the |:s| command, except that you MUST use
forward slashes / to delimit the command. The optional part `[column/]` can
take either the form of an address or if you leave it out, substitution will
only happen in the current column. Additionally, you can use the `1,5/` form
to substitute within the columns 1 till 5 or you can even use `1,$` which
means to substitute in each column (so in fact this simplifies to a simple
`:s` command whithin the given range. For the use of `[/flags]` see |:s_flags|
Here are some examples: >

    :%Substitute 1,4/foobar/baz/gce

Substitutes in the whole file in columns 1 till 4 the pattern foobar by baz
for every match ('g' flag) and asks for confirmation ('c' flag).

    :%S 3,$/(\d\+)/\1 EUR/g

Substitutes in each column starting from the third each number and appends the
EURO suffix to it.

3.26 Count Values inside a Column      				 *CountCol_CSV*
---------------------------------
You can let Vim output the number of values inside a column using the `:CSVCountCol` 
command >

    :[range]CountCol [nr] [distinct]

This outputs the number of [distinct] values visible in the column [nr]
If [distinct] is not given, count's all values. Note, header rows and folded
rows won't be counted.

See also |csv-aggregate-functions|


                                                                *MinCol_CSV*
3.27 Maximum/Minimum value of a Column 				*MaxCol_CSV*
---------------------------------------
You can let Vim output the 10 maximum/minimum values of a column using the
`:CSVMaxCol` command >

    :[range]MaxCol [nr][distinct] [/format/]
    :[range]MinCol [nr][distinct] [/format/]

This outputs the result of the column <nr> within the range given. If no range
is given, this will calculate the max value of the whole column. If <nr> is not
given, this calculates the sum for the column the cursor is on. Note, that the
delimiter will be stripped away from each value and also empty values won't be
considered.

By default, Vim uses the a numerical format that uses the '.' as decimal
separator while there is no thousands separator. If youre file contains
the numbers in a different format, you can use the /format/ option to specify
a different thousands separator or a different decimal separator. The format
needs to be specified like this:
    /x:y/
where 'x' defines the thousands separator and y defines the decimal
separator and each one is optional. This means, that >

    :MaxCol 1 /:,/

uses the default thousands separator and ',' as the decimal separator and >

    :MaxCol 2 / :./

uses the Space as thousands separator and the '.' as decimal separator.

If [distinct] is given, only returns the number of distinct values.

Note, if you Vim is compiled without floating point number format (|+float|),
Vim will only aggregate the integer part and therefore won't use the 'y'
argument in the /format/ specifier.

See also |csv-aggregate-functions|
==============================================================================
4. CSV Configuration					 *csv-configuration*

The CSV plugin tries to automatically detect the field delimiter for your
file, cause although often the file is called CSV (comma separated values), a
semicolon is actually used. The column separator is stored in the buffer-local
variable b:delimiter. This delimiter is heavily used, because you need
it to define a column. Almost all commands use this variable therefore.

4.1 Delimiter							*csv-delimiter*
-------------
To override the automatic detection of the plugin and define the separator
manually, use: >

    :let g:csv_delim=','

to let the comma be the delimiter. This sets the buffer local delimiter
variable b:delimiter.

If your file does not consist of delimited columns, but rather is a fixed
width csv file, see |csv-fixedwidth| for configuring the plugin appropriately.

If you changed the delimiter, you should reinitiliaze the plugin using
|InitCSV|

Note: the delimiter will be used to generate a regular expression that matches
a column. Therefore, you need to escape special characters. So instead of '^'
use '\^'.

4.2 Column							*csv-column*
----------
The definition, of what a column is, is defined as buffer-local variable
b:col. By default this variable is initialized to: >

    let b:col='\%(\%([^' . b:delimiter . ']*"[^"]*"[^' . b:delimiter . ']*'
    \. b:delimiter . '\)\|\%([^' . b:delimiter . ']*\%(' . b:delimiter
    \. '\|$\)\)\)'

This should take care of quoted delimiters within a column. Those should
obviously not count as a delimiter. This regular expression is quite
complex and might not always work on some complex cases (e.g. linebreaks
within a field, see RFC4180 for some ugly cases that will probably not work
with this plugin).

If you changed the b:delimiter variable, you need to redefine the b:col
variable, cause otherwise it will not reflect the change. To change the
variable from the comma to a semicolon, you could call in your CSV-Buffer
this command: >

    :let b:col=substitute(b:col, ',', ';', 'g')

Check with :echo b:col, if the definition is correct afterwards.

You can also force the plugin to use your own defined regular expression as
column. That regular expression should include the delimiter for the columns.
To define your own regular expression, set the g:csv_col variable: >

    let g:csv_col='[^,]*,'

This defines a column as a field delimited by the comma (where no comma can be
contained inside a field), similar to how |csv-strict| works.

You should reinitialize the plugin afterwards |InitCSV|

4.3 Highlighting Group                                         *csv-higroup*
----------------------
By default the csv ftplugin uses the WildMenu highlighting Group to define how
the |HiColumn| command highlights columns. If you would like to define a
different highlighting group, you need to set this via the g:csv_hiGroup
variable. You can e.g. define it in your |.vimrc|: >

    :let g:csv_hiGroup = "IncSearch"

You need to restart Vim, if you have changed this variable or use |InitCSV|

The |hl-Title| highlighting is used for the Header line that is created by the
|Header_CSV| command. If you prefer a different highlighting, set the
g:csv_hiHeader variable to the prefered highlighting: >

    let g:csv_hiHeader = 'Pmenu'
<
This would set the header window to the |hl-Pmenu| highlighting, that is used
for the popup menu. To disable the custom highlighting, simply |unlet| the
variable: >

    unlet g:csv_hiHeader

You should reinitialize the plugin afterwards |InitCSV|

4.4 Strict Columns						*csv-strict*
------------------
The default regular expression to define a column is quite complex
(|csv-column|). This slows down the processing and makes Vim use more memory
and it could still not fit to your specific use case.

If you know, that in your data file, the delimiter cannot be contained inside
the fields quoted or escaped, you can speed up processing (this is quite
noticeable when using the |ArrangeColumn_CSV| command) by setting the
g:csv_strict_columns variable: >

    let g:csv_strict_columns = 1

This would define a column as this regex: >

    let b:col = '\%([^' . b:delimiter . ']*' . b:delimiter . '\|$\)'

Much simpler then the default column definition, isn't it?
See also |csv-column| and |csv-delimiter|

You can disable the effect if you |unlet| the variable: >

    unlet g:csv_strict_columns

You should reinitialize the plugin afterwards |InitCSV|

For example when opening a CSV file you get the Error |E363|: pattern uses
more memory than 'maxmempattern'. In this case, either increase the
'maxmempattern' or set the g:csv_strict_columns variable.


4.5 Concealing					*csv-syntax*	*csv-conceal*
--------------
The CSV plugin comes with a function to syntax highlight csv files. Basically
allt it does is highlight the columns and the header line.

By default, the delimiter will not be displayed, if Vim supports |conceal| of
syntax items and instead draws a vertical line. If you don't want that, simply
set the g:csv_noconceal variable in your .vimrc >

    let g:csv_no_conceal = 1

and to disable it, simply unlet the variable >

    unlet g:csv_no_conceal

You should reinitialize the plugin afterwards |InitCSV|
Note: You can also set the 'conceallevel' option to control how the concealed
chars will be displayed.

If you want to customize the syntax colors, you can define your own groups.
The CSV plugin will use already defined highlighting groups, if they are
already defined, otherwise it will define its own defaults which should be
visible with 8, 16, 88 and 256 color terminals. For that it uses the
CSVColumnHeaderOdd and CSVColumnHeaderEven highlight groups for syntax
coloring the first line. All other lines get either the CSVColumnOdd or
CSVColumnEven highlighting.

In case you want to define your own highlighting groups, you can define your
own syntax highlighting like this in your |.vimrc| >

    hi CSVColumnEven term=bold ctermbg=4 guibg=DarkBlue
    hi CSVColumnOdd  term=bold ctermbg=5 guibg=DarkMagenta
    hi CSVColumnHeaderEven ...
    hi CSVColumnHeaderOdd ...

Alternatively, you can simply link those highlighting groups to some other
ones, you really like: >

    hi link CSVColumnOdd MoreMsg
    hi link CSVColumnEven Question
<
If you do not want column highlighting, set the variable
g:csv_no_column_highlight to 1 >

    :let g:csv_no_column_highlight = 1
<
Note, these changes won't take effect, until you restart Vim.


4.6 Newlines						*csv-newline*
------------
RFC4180 allows newlines in double quoted strings. By default, the csv-plugin
won't recognize newlines inside fields. It is however possible to make the
plugin aware of newlines within quoted strings. To enable this, set >

    let g:csv_nl = 1

and to disable it again, simply unset the variable >

    unlet g:csv_nl

It is a good idea to reinitialize the plugin afterwards |InitCSV|

Note, this might not work correctly in all cases. The syntax highlighting
seems to change on cursor movements. This could possibly be a bug in the
syntax highlighting engine of Vim. Also, |WhatColumn_CSV| can't handle
newlines inside fields and will most certainly be wrong.

4.7 Highlight column automatically				*csv-hicol*
----------------------------------
You can let vim automatically highlight the column on which the cursor is.
This works by defining an |CursorMoved| autocommand to always highlight the
column, when the cursor is moved in normal mode. Note, this does not update
the highlighting, if the Cursor is moved in Insert mode. To enable this,
define the g:csv_highlight_column variable like this >

    let g:csv_highlight_column = 'y'

and to disable it again, simply unset the variable >

    unlet g:csv_highlight_column

It is a good idea to reinitialize the plugin afterwards |InitCSV|

4.8 Fixed width columns                                        *csv-fixedwidth*
-----------------------
Sometimes there are no real columns, but rather the file is fixed width with
no distinct delimiters between each column. The CSV plugin allows you to
handle such virtual columns like csv columns, if you define where each column
starts.

Note: Except for |ArrangeColumn_CSV| and the |Header_CSV| commands, all
commands work in either mode. Those two commands won't do anything in the case
of fixedwidth columns, since they don't really make sense here.

4.8.1 Manual setup
------------------
You can do this, by setting the buffer-local variable
b:csv_fixed_width like this >

    let b:csv_fixed_width="1,5,9,13,17,21"

This defines that each column starts at multiples of 4. Be sure, to issue
this command in the buffer, that contains your file, otherwise, it won't
have an effect, since this is a buffer-local option (|local-option|)

After setting this variable, you should reinitialize the plugins using
|InitCSV|

                                                                    *CSVFixed*
4.8.2 Setup using a Wizard
--------------------------
Alternatively, you can setup the fixed width columns using the :CSVFixed
command. This provides a simple wizard to select each column. If you enter
the command: >
    :CSVFixed
<
The first column will be highlighted and Vim outputs:
<Cursor>, <Space>, <ESC>, <BS>, <CR>...
This means, you can now use those 5 keys to configure the fixed-width columns:

   <Cursor> Use Cursor Left (<Left>) and Cursor Right (<Right>) to move the
            highlighting bar.
   <Space>  If you press <Space>, this column will be fixed and remain
            highlighted and there will be another bar, you can move using
            the Cursor keys. This means this column will be considered to be
            the border between 2 fixed with columns.
   <ESC>    Abort
   <BS>     Press the backspace key, to remove the last column you fixed with
            the <Space> key.
   <CR>     Use Enter to finish the wizard. This will use all fixed columns
            to define the fixed width columns of your csv file. The plugin
            will be initialized and syntax highlighting should appear.

Note: This only works, if your Vim has the 'colorcolumn' option available
(This won't work with Vim < 7.3 and also not with a Vim without +syntax
feature).


4.9 CSV Header lines                                        *csv-header*
--------------------
By default, dynamic filtering |csv-filter| will not fold away the first line.
If you don't like that, you can define your header line using the variable
b:csv_fold_headerline, e.g. >

    let b:csv_headerline = 0

to disable, that a header line won't be folded away. If your header line
instead is on line 5, simply set this variable to 5. This also applies to the
|Header_CSV| command.

4.10 Number format                                           *csv-nrformat*
------------------
When using the |SumCol_CSV| command, you can specify a certain number format
using the /x:y/ argument. You can however also configure the plugin to detect
a different number format than the default number format (which does not
support a thousands separator and uses the '.' as decimal separator).

To specify a different thousands separator by default, use >

    let b:csv_thousands_sep = ' '

to have the space use as thousands separator and >

    let b:csv_decimal_sep = ','

to use the comma as decimal separator.

4.11 Move folded lines                                        *csv-move-folds*
----------------------
If you use dynamic filters (see |csv-filter|), you can configure the plugin to
move all folded lines to the end of the file. This only happens if you set the
variable >

    let g:csv_move_folds = 1
<
and the file is modifiable. This let's you see all non-folded records as a
consecutive area without being disrupted by folded lines.

4.12 Using comments                                           *csv-comments*
-------------------
Strictly speaking, in csv files there can't be any comments. You might however
still wish to comment or annotate certain sections in your file, so the CSV
plugin supports Comments.

Be default, the CSV plugin will use the 'commentstring' setting to identify
comments. If this option includes the '%s' it will consider the part before
the '%s' as leading comment marker and the part behind it as comment
delimiter.

You can however define your own comment marker, using the variable
g:csv_comment. Like with the 'commentstring' setting, you can use '%s'
expandos, that will denote where the actual comment text belongs. To define
your own comment string, put this in your |.vimrc| >

    :let g:csv_comment = '#'
<
Which will use the '#' sign as comment leader like in many scripting
languages.

After setting this variable, you should reinitialize the plugins using
|InitCSV|

                                                            *csv-foldtext*
By default, the csv plugin sets the 'foldtext' option. If you don't want this,
set the variable `g:csv_disable_fdt` in your |.vimrc| >

    :let g:csv_disable_fdt = 1

==============================================================================
5. Functions                                                    *CSV-Functions*

The csv plugins also defines some functions, that can be used for scripting
when a csv file is open

5.1 CSVPat()  							*CSVPat()*
------------
CSVPat({column}[, {pattern}])

This function returns the pattern for the selected column. If only columns is
given, returns the regular expression used to search for the pattern '.*' in
that column (which means the content of that column). Alternatively, an
optional pattern can be given, so the return string can be directly feeded to
the |/| or |:s| command, e.g. type: >

    :s/<C-R>=CSVPat(3, 'foobar')<cr>/baz

where the <C-R> means pressing Control followed by R followed by =
(see |c_CTRL-R_=|). A prompt will apear, with the '=' as the first character
on which you can enter expressions.

In this case enter CSVPat(3, 'foobar') which returns the pattern to search for
the string 'foobar' in the third column. After you press enter, the returned
pattern will be put after the :s command so you can directly enter / and the
substitute string.

5.2 CSVField(x,y[, orig])					*CSVField()*
-------------------------
This function returns the field at index (x,y) (starting from 1). If the
parameter orig is given, returns the column "as is" (e.g. including delimiter
and leading and trailing whitespace, otherwise that will be stripped.)

5.3 CSVCol([name])				        	*CSVCol()*
------------------
If the name parameter is given, returns the name of the column, else returns
the index of the current column, starting at 1.

5.4 CSVSum(col, fmt, startline, endline)                        *CSVSum()*
----------------------------------------
Returns the sum for column col. Uses fmt to parse number format (see
|:CSVSumCol|) startline and endline specify the lines to consider, if empty,
will be first and last line.

5.5 CSVCount(col, fmt, startline, endline[, distinct])            *CSVCount()*
------------------------------------------------------
Returns the count of values for column col. If the optional parameter
[distinct] is given, only returns the distinct number of values.

5.6 CSVMax(col, fmt, startline, endline)                         *CSVMax()*
------------------------------------------------------
Returns the 10 largest values for column col. 

5.7 CSVMin(col, fmt, startline, endline)                         *CSVMin()*
------------------------------------------------------
Returns the 10 smallest values for column col. 

5.8 CSVAvg(col, fmt, startline, endline)                         *CSVAvg()*
------------------------------------------------------
Returns the average value for column col. 

==============================================================================
6. CSV Tips and Tricks						*csv-tips*

Here, there you'll find some small tips and tricks that might help when
working with CSV files.

6.1 Statusline							*csv-stl*
--------------
Suppose you want to include the column, on which the cursor is, into your
statusline. You can do this, by defining in your .vimrc the 'statusline' like
this: >

    function MySTL()
        if has("statusline")
            hi User1 term=standout ctermfg=0 ctermbg=11 guifg=Black guibg=Yellow
            let stl = ...
            if exists("*CSV_WCol")
                let csv = '%1*%{&ft=~"csv" ? CSV_WCol() : ""}%*'
            else
                let csv = ''
            endif
            return stl.csv
        endif
    endfunc
    set stl=%!MySTL()
<

This will draw in your statusline right aligned the current column and max
column (like 1/10), if you are inside a CSV file. The column info will be
drawn using the User1 highlighting (|hl-User1|), that has been defined in the
second line of the function. In the third line of your function, put your
desired 'statusline' settings as |expression|. Note the section starting with
'if exists(..)' guards against not having loaded the filetype plugin.

Note: vim-airline (https://github.com/bling/vim-airline) by default supports
the csv plugin and enables a nice little csv statusline which helps for
navigating within a csv file. For details, see the Vim-Airline documentation.

                                                                 *CSV_WCol()*
The CSV_WCol() function controls, what will be output. In the simplest case,
when no argument is given, it simply returns on which column the cursor is.
This would look like '1/10' which means the cursor is on the first of 10
columns. If you rather like to know the name of the column, simply give as
parameter to the function the string "Name". This will return the column name
as it is printed on the first line of that column. This can be adjusted, to
have the column name printed into the statusline (see |csv-stl| above) by
replacing the line >

    let csv = '%1*%{&ft=~"csv" ? CSV_WCol() : ""}%*'
<
by e.g.

    let csv = '%1*%{&ft=~"csv" ? CSV_WCol("Name") . " " . CSV_WCol() : ""}%*'

which will output "Name 2/10" if the cursor is in the second column
which is named "Name".

6.2 Slow CSV plugin						*csv-slow*
-------------------
Processing a csv file using |ArrangeColumn_CSV| can be quite slow, because Vim
needs to calculate the width for each column and then replace each column by
itself widened by spaces to the optimal length. Unfortunately, csv files tend
to be quite big. Remember, for a file with 10,000 lines and 50 columns Vim
needs to process each cell, which accumulates to 500,000 substitutions. It
might take some time, until Vim is finished.

You can speed up things a little bit, if you omit the '!' attribute to the
|ArrangeColumn| (but this will only work, if the width has been calculated
before, e.g. by issuing a :1ArrangeColumn command to arrange only the first
line. Additionally you can also configure how this command behaves by setting
some configuration variables.

Also note, using dynamic filters (|csv-filter|), can slow down Vim
considerably, since they internally work with complex regular expressions, and
if you have a large file, containing many columns, you might hit a performance
penalty (especially, if you want to filter many columns). It's best to avoid
those functions if you are using a large csv file (so using strict columns
|csv-strict| might help a little and also setting 're' to 1 might also
alleviate it a little).


6.3 Defining custom aggregate functions		    *csv-aggregate-functions*
---------------------------------------
The CSV plugin already defines the |SumCol_CSV| command, to let you calculate
the sum of all values of a certain column within a given range. This will
consider all values within the range, that are not folded away (|csv-filter|),
and also skip comments and the header lines. The delimiter will be deleted
from each field.

But it may be, that you don't need the sum, but would rather want to have the
average of all values within a certain column. You can define your own
function and let the plugin call it for a column like this:

    1) You define your own custom function in the after directory of your
       vim runtime path |after-directory| (see also #2 below) >

        fun! My_CSV_Average(col)
            let sum=0
            for item in a:col
                let sum+=item
            endfor
            return sum/len(a:col)
        endfun
<
       This function takes a list as argument, and calculates the average for
       all items in the list. You could also make use of Vim's |eval()|
       function and write your own Product function like this >

        fun! My_CSV_Product(col)
            return eval(join(a:col, '*'))
        endfun
<

    2) Now define your own custom command, that calls your custom function for
    a certain column >

            command! -buffer -nargs=? -range=% AvgCol
            \ :echo csv#EvalColumn(<q-args>,
            \ "My_CSV_Average", <line1>,<line2>)
<
        This command should best be put into a file called csv.vim and save
        it into your ~/.vim/after/ftplugin/ directory. Create directories
        that don't exist yet. For Windows, this would be the
        $VIMRUNTIME/vimfiles/after/ftplugin directory.

    3) Make sure, your |.vimrc| includes a filetype plugin setting like this >

        filetype plugin on
<
       This should make sure, that all the necessary scripts are loaded by
       Vim.

    After restarting Vim, you can now use your custom command definition
    :AvgCol. Use a range, for the number of lines you want to evaluate and
    optionally use an argument to specify which column you want to be
    evaluated >

        :2,$AvgCol 7
<
    This will evaluate the average of column seven (assuming, line 1 is the
    header line, which should not be taken into account).

    Note: this plugin already defines an average function.

6.4 Autocommand on opening/closing files                *csv-arrange-autocmd*
----------------------------------------
If you want your CSV files to always be displayed like a table, you can
achieve this using the |ArrangeColumn_CSV| command and some autocommands.
Define these autocommands in your |.vimrc| >

    aug CSV_Editing
        au!
        au BufRead,BufWritePost *.csv :%ArrangeColumn
        au BufWritePre *.csv :%UnArrangeColumn
    aug end

Upon Entering a csv file, Vim will visually arrange all columns and before
writing, those columns will be collapsed again. The BufWritePost autocommand
makes sure, that after the file has been written successfully, the csv file
will again be visually arranged.

You can also simply set the variable >

    let g:csv_autocmd_arrange = 1
<
in your vimrc and an autocmd will be installed, that visually arranges your
csv file whenever you open them for editing. Alternatively, you can restrict
this setting to files below a certain size. For example, if you only want to
enable this feature for files smaller than 1 MB, put this into your |.vimrc| >

    let g:csv_autocmd_arrange      = 1
    let g:csv_autocmd_arrange_size = 1024*1024

Note, this is highly experimental and especially on big files, this might
slow down Vim considerably.

6.5 Syntax error when opening a CSV file               *csv-syntax-error*
----------------------------------------
If you see this error: >

   CSV Syntax:Invalid column pattern, using default pattern \%([^,]*,\|$\)
<
This happens usually, when the syntax script is read before the filetype
plugin, so the plugin did not have a chance to setup the column delimiter
correctly.

The easy way to fix it, is to make sure the :syntax on (|:syn-on|) statement
comes after the :filetype plugin (|:filetype-plugin-on|) statement in your
|.vimrc|

Alternatively, you can simply call |InitCSV| and ignore the error.

6.6 Calculate new columns               *csv-calculate-column*
-------------------------
Suppose you have a table like this:

Index;Value1;Value2~
1;100;3 `
2;20;4 `

And you need one more column, that is the calculated product of column 2 and
3, you can make use of the provided |CSVField()| function using a
|sub-replace-expression| of an |:s| command. In this case, you would do this: >

    :2,3s/$/\=printf("%s%.2f", b:delimiter,
    (CSVField(2,line('.'))+0.0)*(CSVField(3,line('.'))+0.0/

Note: Enter as single line. The result will be this: >

Index;Value1;Value2~
1;100;3;300.00 `
2;20;4;80.00 `
==============================================================================
7. CSV Changelog					       *csv-changelog*

0.32 (unreleased) {{{1
- Remove old Vim 7.3 workarounds (plugin needs now a Vim version 7.4)
- allow to align columns differently (right/left or center align) for
  |ArrangeColumn_CSV| (suggested by Giorgio Robino, thanks!)
- document better how to adjust syntax highlighting (suggested by Giorgio
  Robino, thanks!)
- Allow the |:CSVHeader| command to only display a specific column (suggested
  by Giorgio Robino, thanks!)
- When using |VHeader_CSV| or |Header_CSV| command, check
  number/relativenumber and foldcolumn to make sure, header line is always
  aligened with main window (suggested by Giorgio Robino, thanks!)
- hide search pattern, when calling |SearchInColumn_CSV| (suggested by Giorgio
  Robino, thanks!)
- compute correct width of marginline for |:CSVTable|
- do not allow |:CSVTable| command for csv files, that's what the
  |:CSVTabularize| command is for.
- add progressbar for the |:CSVArrangeCol| command. 
- |InitCSV| accepts a '!' for keeping the b:delimiter (|csv-delimiter|) variable
  (https://github.com/chrisbra/csv.vim/issues/43 reported by Jeet Sukumaran,
  thanks!)
- New text-object iL (Inner Line, to visually select the lines that have the
  same value in the cursor column, as requested at
  https://github.com/chrisbra/csv.vim/issues/44, thanks justmytwospence!)
- |:CSVArrangeColumn| can be given an optional row number and the width will
  be calculated using that row. (https://github.com/chrisbra/csv.vim/issues/45
  reported by jchain, thanks!)
- Allow for hexadecimal |Sort_CSV|
  (https://github.com/chrisbra/csv.vim/issues/46, reported by ThomsonTan,
  thanks!)
- support all flags for |Sort_CSV| as for the builting |:sort| command (except
  for "u" and "r")
- prevent mapping of <Up> and <Down> in visual mode (reported by naught101 at
  https://github.com/chrisbra/csv.vim/issues/50, thanks!)
- prevent increasing column width on subsequent call of |:ArrangeColumn_CSV|
  (reported by naught101 at https://github.com/chrisbra/csv.vim/issues/51,
  thanks!)
- New Count function |CSVCount()| (reported by jungle-booke at
  https://github.com/chrisbra/csv.vim/issues/49, thanks!)
- fix pattern generation for last column
- |ConvertData_CSV| should filter out folded lines (reported by jungle-booke
  at https://github.com/chrisbra/csv.vim/issues/53, thanks!)
- Make |:CSVTable| ignore folded lines (reported by jungle-booke at 
  https://github.com/chrisbra/csv.vim/issues/56, thanks!)
- Better filtering for dynamic filters (reported by jungle-booke at 
  https://github.com/chrisbra/csv.vim/issues/57, thanks!)
- Implement a |MaxCol_CSV| and |MinCol_CSV| command (reported by jungle-booke at 
  https://github.com/chrisbra/csv.vim/issues/60, thanks!)
- Make |UnArrangeColumn_CSV| strip leading and trailing whitespace (reported
  by SuperFluffy at https://github.com/chrisbra/csv.vim/issues/62, thanks!)
- Do not sort headerlines (reported by jungle-booke at https://github.com/chrisbra/csv.vim/issues/63,
  thanks!)
- Do not error out in |:ArrangeCol| command, if line does not have that many
  columns (reported by SuperFluffy at https://github.com/chrisbra/csv.vim/issues/64, thanks)
- Use |OptionSet|autocommand to adjust window for |CSV_Header| command
- when doing |:ArrangeCol| with bang attribute, unarrange first, so that if
  the alignment changed, it will be adjusted accordingly
- Allow distinct keyword for |MaxCol_CSV| and |MinCol_CSV| command (reported
  by jungle-boogie at https://github.com/chrisbra/csv.vim/issues/67, thanks!)
- When left-aligning columns, don't add trailing whitespace (reported by
  jjaderberg at https://github.com/chrisbra/csv.vim/issues/66, thanks!)
- Do not remove highlighting when calling ":CSVTabularize" (reported by
   hyiltiz at https://github.com/chrisbra/csv.vim/issues/70, thanks!)
- Make |:ArrangeCol| respect given headerlines
- when checking Header/comment lines at beginning of file, make sure to escape
  the comment pattern correctly.
- use b:csv_headerline variable for checking column name and column numbers
  (reported by Werner Freund at https://github.com/chrisbra/csv.vim/issues/78,
  thanks!)
- Statusline function could cause a hang in an empty file (reported by Jeet
  Sukumaran in issue https://github.com/chrisbra/csv.vim/issues/80, thanks!)
- Wrong headerline highlighting when creating a new file (reported by Jeet
  Sukumaran in issue https://github.com/chrisbra/csv.vim/issues/79, thanks!)
- Do not strip leading whitespace, when applying filters (reported by
  blubb123muh in https://github.com/chrisbra/csv.vim/issues/87, thanks!)
- display column name on |:Analyze_CSV| command (suggested by indera in
  https://github.com/chrisbra/csv.vim/issues/88, thanks!)

0.31 Jan 15, 2015 {{{1
- supports for Vim 7.3 dropped
- fix that H on the very first cell, results in an endless loop
  (https://github.com/chrisbra/csv.vim/issues/31, reported by lahvak, thanks!)
- fix that count for |AddColumn| did not work (according to the documentation)
  (https://github.com/chrisbra/csv.vim/issues/32, reported by lahvak, thanks!)
- invalid reference to a WarningMsg() function
- WhatColumn! error, if the first line did not contain as many fields
  as the line to check.
- Rename |:Table| command to |:CSVTable| (
  https://github.com/chrisbra/csv.vim/issues/33,
  reported by Peter Jaros, thanks!)
- Mention to escape special characters when manually specifying the delimiter.
  https://github.com/chrisbra/csv.vim/issues/35), also detect '^' as
  delimiter.
- Csv fixed with columns better use '\%v' to match columns, otherwise, one
  could get problems with multibyte chars
- Sorting should work better with csv fixed with patterns (could generate an
  inavlide pattern before)
- Refactor GetSID() (provided by Ingo Karkat
  https://github.com/chrisbra/csv.vim/pull/37, thanks!)
- New public function |CSVSum()|
- Restrict |csv-arrange-autocmd| to specific file sizes (suggested by Spencer
  Boucher in https://github.com/chrisbra/csv.vim/issues/39, thanks!)
- Make |:CSVSearchInColumn| wrap pattern in '%\(..\)' pairs, so it works
  correctly with '\|' atoms
- Small improvements on |:CSVTable| and |:NewDelimiter| command
- <Up> and <Down> should skip folds (like in normal Vi mode, suggested by
  Kamaraju Kusuma, thanks!)

0.30 Mar 27, 2014 {{{1
- |:CSVSubstitute| should substitute all matches in a column, when 'g' flag is
  given
- Don't override 'fdt' setting (https://github.com/chrisbra/csv.vim/issues/18,
  reported by Noah Frederick, thanks!)
- Consistent Commands naming (https://github.com/chrisbra/csv.vim/issues/19,
  reported by Noah Frederick, thanks!)
- New Function |CSVField()| and |CSVCol()|
- clean up function did not remove certain buffer local variables,
  possible error when calling Menu function to disable CSV menu
- make |:CSVArrangeColumn| do not output the numer of substitutions happened
  (suggested by Caylan Larson, thanks!)
- better cleaning up on exit, if Header windows were used
- Let |:CSVVHeader| accept a number, of how many columns to show
  (suggested by Caylan Larson, thanks!)
- better error-handling for |CSVFixed|
- selection of inner/outer text objects  was wrong, reported by Ingo Karkat,
  thanks!)
- errors, when using |:CSVAnalyze| and there were empty attributes
- allow to left-align columns when using |:CSVArrangeColumn|
- |SumCol_CSV| did not detect negative values
- make <cr> in (Virtual-) Replace work as documented

0.29 Aug 14, 2013 {{{1
- setup |QuitPre| autocommand to quit cleanly in newer vims when using :Header
  and :VHeader
- new |AddColumn_CSV| command
- prevent mapping of keys, if g:csv_nomap_<keyname> is set
  (reported by ping)
- new |Substitute_CSV| command
- better syntax highlighting
- small speedup for |ArrangeColumn_CSV|
- 'E' did not correctly move the the previous column
- support for vim-airline added

0.28 Dec 14, 2012 {{{1
- new command :Table to create ascii tables for non-csv files

0.27 Nov 21, 2012 {{{1
- Better |CSV-Tabularize|
- Documentation update

0.26 Jul 25, 2012 {{{1
- Better handling of setting filetype specific options
- |CSV-Tabularize|
- fix some small errors

0.25 May 17, 2012 {{{1
- |SearchInColumn_CSV| should match non-greedily, patch by Matěj Korvas,
- better argument parsing for |SearchInColumn_CSV|, patch by Matěj Korvas,
  thanks!
0.24 Apr 12, 2012 {{{1
- Allow to transpose the file (|csv-transpose|, suggested by Karan Mistry,
  thanks!)
- |DeleteColumn_CSV| allows to specify a search pattern and all matching
  columns will be deleted (suggested by Karan Mistry, thanks!)

0.23 Mar 25, 2012 {{{1
- Don't error out, when creating a new file and syntax highlighting
  script can't find the delimiter
  (ftplugin will still give a warning, so).
- Don't pollute the search register when loading a file
- Give Warning when number format is wrong
- Don't source ftdetect several times (patch by Zhao Cai, thanks!)
- |NewDelimiter_CSV| to change the delimiter of the file
- |Duplicate_CSV| to check for duplicate records in the file
- Issue https://github.com/chrisbra/csv.vim/issues/13 fixed (missing quote,
  reported by y, thanks!)
- |CSVPat()| function
- 'lz' does not work with |:silent| |:s| (patch by Sergey Khorev, thanks!)
- support comments (|csv_comment|, suggested by Peng Yu, thanks!)
0.22 Nov 08, 2011 {{{1
- Small enhancements to |SumCol_CSV|
- :Filters! reapplys the dynamic filter
- Apply |csv-aggregate-functions| only to those values, that are
  not folded away.
- |SumCol_CSV| can use a different number format (suggested by James Cole,
  thanks! (also |csv-nrformat|
- Documentation updates (suggested by James Cole and Peng Yu)
- More code cleanup and error handling
  https://github.com/chrisbra/csv.vim/issues/9 reported Daniel Carl, thanks!
  https://github.com/chrisbra/csv.vim/issues/8 patch by Daniel Carl, thanks!
- New Command |NewRecord_CSV| (suggest by James Cole, thanks!)
- new textobjects InnerField (if) and outerField (af) which contain the field
  without or with the delimiter (suggested by James Cole, thanks!)
- |csv-arrange-autocmd| to let Vim automatically visually arrange the columns
  using |ArrangeColumn_CSV|
- |csv-move-folds| let Vim move folded lines to the end
- implement a Menu for graphical Vim

0.21 Oct 06, 2011 {{{1
- same as 0.20 (erroneously uploaded to vim.org)

0.20 Oct 06, 2011 {{{1

- Implement a wizard for initializing fixed-width columns (|CSVFixed|)
- Vertical folding (|VertFold_CSV|)
- fix plugin indentation (by Daniel Karl, thanks!)
- fixed missing bang parameter for HiColumn function (by Daniel Karl, thanks!)
- fixed broken autodection of delimiter (reported by Peng Yu, thanks!)

0.19 Sep 26, 2011 {{{1

- Make |:ArrangeColumn| more robust
- Link CSVDelimiter to the Conceal highlighting group for Vim's that have
  +conceal feature (suggested by John Orr, thanks!)
- allow the possibility to return the Column name in the statusline |csv-stl|
  (suggested by John Orr, thanks!)
- documentation updates
- Allow to dynamically add Filters, see |csv-filter|
- Also display what filters are active, see |:Filter|
- Analyze a column for the distribution of a value |csv-analyze|
- Implement UnArrangeColumn command |UnArrangeColumn_CSV|
  (suggested by Daniel Karl in https://github.com/chrisbra/csv.vim/issues/7)

0.18 Aug 30, 2011 {{{1

- fix small typos in documentation
- document, that 'K' and 'J' have been remapped and the originial function is
  available as \K and \J
- Delimiters should not be highlighted within a column, only when used
  as actual delimiters (suggested by Peng Yu, thanks!)
- Performance improvements for |:ArrangeColumn|

0.17 Aug 16, 2011 {{{1

- small cosmetic changes
- small documentation updates
- fold away changelog in help file
- Document, that |DeleteColumn_CSV| deletes the column on which the cursor
  is, if no column number has been specified
- Support csv fixed width columns (|csv-fixedwidth|)
- Support to interactively convert your csv file to a different
  format (|csv-convert|)

0.16 Jul 25, 2011 {{{1

- Sort on the range, specified (reported by Peng Yu, thanks!)
- |MoveCol_CSV| to move a column behind another column (suggested by Peng Yu,
  thanks!)
- Document how to use custom functions with a column
  (|csv-aggregate-functions|)
- Use g:csv_highlight_column variable, to have Vim automatically highlight the
  column on which the cursor is (|csv-hicol|)
- Header/VHeader command should work better now (|Header_CSV|, |VHeader_CSV|)
- Use setreg() for setting the register for the |Column_CSV| command and make
  sure it is blockwise.
- Release 0.14 was not correctly uploaded to vim.org

0.14 Jul 20, 2011 {{{1

- really use g:csv_no_conceal variable (reported by Antonio Ospite, thanks!)
- Force redrawing before displaying error messages in syntax script (reported
  by Antonio Ospite, thanks!)
- Make syntax highlighting work better with different terminals (Should work
  now with 8, 88 and 256 color terminals, tested with linux konsole, xterm and
  rxvt) (https://github.com/chrisbra/csv.vim/issues/4)
- Automatically detect '|' as field separator for csv files

0.13 Mar 14, 2011 {{{1

- documentation update
- https://github.com/chrisbra/csv.vim/issues#issue/2 ('splitbelow' breaks
  |Header_CSV|, fix this; thanks lespea!)
- https://github.com/chrisbra/csv.vim/issues#issue/3 ('gdefault' breaks
  |ArrangeColumn_CSV|, fix this; thanks lespea!)
- https://github.com/chrisbra/csv.vim/issues#issue/1 (make syntax highlighting
  more robust, thanks lespea!)
- fix some small annoying bugs
- WhatColumn! displays column name

0.12 Feb 24, 2011 {{{1

- bugfix release:
- don't use |:noa| when switching between windows
- make sure, colwidth() doesn't throw an error

0.11 Feb 24, 2011 {{{1

- new command |Copy_CSV|
- |Search_CSV| did not find anything in the last column if no delimiter
  was given (reported by chroyer)
- |VHeader_CSV| display the first column as Header similar to how
  |Header_CSV| works
- |HeaderToggle_CSV| and |VHeaderToggle_CSV| commands that toggle displaying
  the header lines/columns

0.10 Feb 23, 2011 {{{1

- Only conceal real delimiters
- document g:csv_no_conceal variable
- document g:csv_nl variable
- document conceal feature and syntax highlighting
- Normal mode command <Up>/<Down> work like K/J
- More robust regular expression engine, that can also handle newlines inside
  quoted strings.
- Slightly adjusted syntax highlighting

0.9 Feb 19, 2011 {{{1

- use conceal char depending on encoding
- Map normal mode keys also for visual/select and operator pending mode

0.8 Feb 17, 2011 {{{1

- Better Error handling
- HiColumn! removes highlighting
- Enable NrColumns, that was deactivated in v.0.7
- a ColorScheme autocommand makes sure, that the syntax highlighting is
  reapplied, after changing the colorscheme.
- SearchInColumn now searches in the current column, if no column has been
  specified
- A lot more documentation
- Syntax Highlighting conceales delimiter
- small performance improvements for |ArrangeColumn_CSV|

0.7 Feb 16, 2011 {{{1

- Make the motion commands 'W' and 'E' work more reliable
- Document how to setup filetype plugins
- Make |WhatColumn_CSV| work more reliable (report from
  http://vim.wikia.com/Script:3280)
- DeleteColumn deletes current column, if no argument given
- |ArrangeColumn_CSV| handles errors better
- Code cleanup
- Syntax highlighting
- 'H' and 'L' move forward/backwards between csv fields
- 'K' and 'J' move upwards/downwards within the same column
- |Sort_CSV| to sort on a certain column
- |csv-tips| on how to colorize the statusline

0.6 Feb 15, 2011 {{{1

- Make |ArrangeColumn_CSV| work more reliable (had problems with multibyte
  chars before)
- Add |Header_CSV| function
- 'W' and 'E' move forward/backwards between csv fields
- provide a file ftdetect/csv.vim to detect csv files

0.5  Apr 20 2010 {{{1

- documentation update
- switched to a public repository: http://github.com/chrisbra/csv.vim
- enabled GLVS (see |GLVS|)

0.4a Mar 11 2010 {{{1

- fixed documentation

0.4  Mar 11 2010 {{{1

- introduce |InitCSV|
- better Error handling
- HiColumn now by default highlights the current column, if no argument is
  specified.

0.3  Oct, 28 2010 {{{1

- initial Version

vim:tw=78:ts=8:ft=help:norl:et:fdm=marker:fdl=0
syntax/csv.vim	[[[1
185
" A simple syntax highlighting, simply alternate colors between two
" adjacent columns
" Init {{{2
let s:cpo_save = &cpo
set cpo&vim

scriptencoding utf8
if version < 600
    syn clear
elseif exists("b:current_syntax")
    finish
endif

" Helper functions "{{{2
fu! <sid>Warning(msg) "{{{3
    " Don't redraw, so we are not overwriting messages from the ftplugin
    " script
    "redraw!
    echohl WarningMsg
    echomsg "CSV Syntax:" . a:msg
    echohl Normal
endfu

fu! <sid>Esc(val, char) "{{{3 
    if empty(a:val)
	return a:val
    endif
    return '\V'.escape(a:val, '\\'.a:char).'\m'
endfu

fu! <sid>CheckSaneSearchPattern() "{{{3
    let s:del_def = ','
    let s:col_def = '\%([^' . s:del_def . ']*' . s:del_def . '\|$\)'
    let s:col_def_end = '\%([^' . s:del_def . ']*' . s:del_def . '\)'

    " First: 
    " Check for filetype plugin. This syntax script relies on the filetype
    " plugin, else, it won't work properly.
    redir => s:a |sil filetype | redir end
    let s:a=split(s:a, "\n")[0]
    if match(s:a, '\cplugin:off') > 0
	call <sid>Warning("No filetype support, only simple highlighting using"
		    \ . s:del_def . " as delimiter! See :h csv-installation")
    endif

    " Check Comment setting
    if !exists("g:csv_comment")
        let b:csv_cmt = split(&cms, '%s')
    elseif match(g:csv_comment, '%s') >= 0
        let b:csv_cmt = split(g:csv_comment, '%s')
    else
	let b:csv_cmt = [g:csv_comment]
    endif


    " Second: Check for sane defaults for the column pattern
    " Not necessary to check for fixed width columns
    if exists("b:csv_fixed_width_cols")
	return
    endif


    " Try a simple highlighting, if the defaults from the ftplugin
    " don't exist
    let s:col  = exists("b:col") && !empty(b:col) ? b:col  : s:col_def
    let s:col_end  = exists("b:col_end") && !empty(b:col_end) ? b:col_end
		\ : s:col_def_end
    let s:del  = exists("b:delimiter") && !empty(b:delimiter) ? b:delimiter
		\ : s:del_def
    let s:cmts = b:csv_cmt[0]
    let s:cmte = len(b:csv_cmt) == 2 ? b:csv_cmt[1] : ''
    " Make the file start at the first actual CSV record (issue #71)
    if !exists("b:csv_headerline")
	let cmts    = <sid>Esc(s:cmts, '')
	let pattern = '\%^\(\%('.cmts.'.*\n\)\|\%(\s*\n\)\)\+'
	let start = search(pattern, 'nWe', 10)
	" don't do it, on an empty file
	if start > 0 && !empty(getline(start))
	    let b:csv_headerline = start+1
	endif
    endif
    " escape '/' for syn match command
    let s:cmts=<sid>Esc(s:cmts, '/')
    let s:cmte=<sid>Esc(s:cmte, '/')

    if line('$') > 1 && (!exists("b:col") || empty(b:col))
    " check for invalid pattern, ftplugin hasn't been loaded yet
	call <sid>Warning("Invalid column pattern, using default pattern " . s:col_def)
    endif
endfu

" Syntax rules {{{2
fu! <sid>DoHighlight() "{{{3
    if has("conceal") && !exists("g:csv_no_conceal") &&
		\ !exists("b:csv_fixed_width_cols")
	" old val
	    "\ '\%(.\)\@=/ms=e,me=e contained conceal cchar=' .
	    " Has a problem with the last line!
	exe "syn match CSVDelimiter /" . s:col_end . 
	    \ '/ms=e,me=e contained conceal cchar=' .
	    \ (&enc == "utf-8" ? "│" : '|')
	"exe "syn match CSVDelimiterEOL /" . s:del . 
	"    \ '\?$/ contained conceal cchar=' .
	"    \ (&enc == "utf-8" ? "│" : '|')
	hi def link CSVDelimiter Conceal
    elseif !exists("b:csv_fixed_width_cols")
	" The \%(.\)\@<= makes sure, the last char won't be concealed,
	" if it isn't a delimiter
	"exe "syn match CSVDelimiter /" . s:col . '\%(.\)\@<=/ms=e,me=e contained'
	exe "syn match CSVDelimiter /" . s:col_end . '/ms=e,me=e contained'
	"exe "syn match CSVDelimiterEOL /" . s:del . '\?$/ contained'
	if has("conceal")
	    hi def link CSVDelimiter Conceal
	else
	    hi def link CSVDelimiter Ignore
	endif
    endif " There is no delimiter for csv fixed width columns


    if !exists("b:csv_fixed_width_cols")
	exe 'syn match CSVColumnEven nextgroup=CSVColumnOdd /'
		    \ . s:col . '/ contains=CSVDelimiter'
	exe 'syn match CSVColumnOdd nextgroup=CSVColumnEven /'
		    \ . s:col . '/ contains=CSVDelimiter'
	exe 'syn match CSVColumnHeaderEven nextgroup=CSVColumnHeaderOdd /\%<'. (get(b:, 'csv_headerline', 1)+1).'l'
		    \. s:col . '/ contains=CSVDelimiter'
	exe 'syn match CSVColumnHeaderOdd nextgroup=CSVColumnHeaderEven /\%<'. (get(b:, 'csv_headerline', 1)+1).'l'
		    \. s:col . '/ contains=CSVDelimiter'
    else
	for i in range(len(b:csv_fixed_width_cols))
	    let pat = '/\%' . b:csv_fixed_width_cols[i] . 'v.*' .
			\ ((i == len(b:csv_fixed_width_cols)-1) ? '/' : 
			\ '\%' . b:csv_fixed_width_cols[i+1] . 'v/')

	    let group  = "CSVColumn" . (i%2 ? "Odd"  : "Even" )
	    let ngroup = "CSVColumn" . (i%2 ? "Even" : "Odd"  )
	    exe "syn match " group pat " nextgroup=" . ngroup
	endfor
    endif
    " Comment regions
    exe 'syn match CSVComment /'. s:cmts. '.*'.
		\ (!empty(s:cmte) ? '\%('. s:cmte. '\)\?'
		\: '').  '/'
    hi def link CSVComment Comment
endfun

fu! <sid>HiLink(name, target) "{{{3
    if !hlexists(a:name)
	exe "hi def link" a:name a:target
    endif
endfu

fu! <sid>DoSyntaxDefinitions() "{{{3
    syn spell toplevel

    " Not really needed
    syn case ignore

    call <sid>HiLink("CSVColumnHeaderOdd", "WarningMsg")
    call <sid>HiLink("CSVColumnHeaderEven", "WarningMsg")
    if get(g:, 'csv_no_column_highlight', 0)
	call <sid>HiLink("CSVColumnOdd", "Normal")
	call <sid>HiLink("CSVColumnEven", "Normal")
    else
	call <sid>HiLink("CSVColumnOdd", "DiffAdd")
	call <sid>HiLink("CSVColumnEven","DiffChange")
    endif
endfun

" Main: {{{2 
" Make sure, we are using a sane, valid pattern for syntax
" highlighting
call <sid>CheckSaneSearchPattern()

" Define all necessary syntax groups
call <sid>DoSyntaxDefinitions()

" Highlight the file
call <sid>DoHighlight()

" Set the syntax variable {{{2
let b:current_syntax="csv"

let &cpo = s:cpo_save
unlet s:cpo_save
ftdetect/csv.vim	[[[1
3
" Install Filetype detection for CSV files
au BufRead,BufNewFile *.csv,*.dat,*.tsv,*.tab set filetype=csv

plugin/csv.vim	[[[1
94
if exists('g:loaded_csv') && g:loaded_csv
  finish
endif
let g:loaded_csv = 1

let s:cpo_save = &cpo
set cpo&vim

if exists("g:csv_autocmd_arrange")
    if !exists("*CSVDoBufLoadAutocmd")
	fu! CSVDoBufLoadAutocmd()
	    " Visually arrange columns when opening a csv file
	    aug CSV_Edit
		au!
		au BufReadPost,BufWritePost *.csv,*.dat,*.tsv,*.tab :exe
			    \ printf(":call CSVArrangeCol(1, %d, 0, %d)",
			    \ line('$'), get(g:, 'csv_autocmd_arrange_size', -1))
		au BufWritePre *.csv,*.dat,*.tsv,*.tab :sil %UnArrangeColumn
	    aug end
	endfu
	call CSVDoBufLoadAutocmd()
    endif
endif

com! -range -bang -nargs=? CSVTable call <sid>Table(<bang>0, <line1>, <line2>, <q-args>)

fu! <sid>Table(bang, line1, line2, delim)
    if match(split(&ft, '\.'), 'csv') > -1
	" Use CSVTabularize command
	echohl WarningMsg
	echomsg "For CSV files, use the :CSVTabularize command!"
	echohl None
	return
    endif
    " save and restore some options
    if has("conceal")
	let _a = [ &l:lz, &l:syntax, &l:ft, &l:sol, &l:tw, &l:wrap, &l:cole, &l:cocu, &l:fen, &l:fdm, &l:fdl, &l:fdc, &l:fml, &l:fdt, &l:ma, &l:ml]
    else
	let _a = [ &l:lz, &l:syntax, &l:ft, &l:sol, &l:tw, &l:wrap, &l:fen, &l:fdm, &l:fdl, &l:fdc, &l:fml, &l:fdt, &l:ma, &l:ml]
    endif
    let _b = winsaveview()
    let line1 = a:line1
    let line2 = a:line2

    if line1 == line2
	" use the current paragraph
	let line1 = line("'{") + 1 
	let line2 = line("'}") - 1
    endif

    if !empty(a:delim)
	let g:csv_delim = (a:delim ==# '\t' ? "\t" : a:delim)
    endif
    " try to guess the delimiter from the specified region, therefore, we need
    " to initialize the plugin to inspect only those lines
    let [ b:csv_start, b:csv_end ] = [ line1, line2 ]
    " Reset b:did_ftplugin just to be sure
    unlet! b:did_ftplugin
    setl noml ft=csv lz ma
    " get indent
    let indent = matchstr(getline(a:line1), '^\s\+')
    exe printf(':sil %d,%ds/^\s\+//e', line1, line2)
    let last = line('$')
    try
	let b:csv_list=getline(line1, line2)
	call filter(b:csv_list, '!empty(v:val)')
	call map(b:csv_list, 'split(v:val, b:col.''\zs'')')
	if exists(":CSVTabularize")
	    exe printf("%d,%dCSVTabularize%s", line1, line2, empty(a:bang) ? '' : '!')
	else
	    echoerr "Not possible to call :CSVTabularize"
	endif
	unlet! b:col_width b:csv_list
    catch
    finally
	" move back to previous window
	noa wincmd p
	if !empty(indent)
	    " undo removing the indent
	    u
	endif
	if has("conceal")
	    let [ &l:lz, &l:syntax, &l:ft, &l:sol, &l:tw, &l:wrap, &l:cole, &l:cocu, &l:fen, &l:fdm, &l:fdl, &l:fdc, &l:fml, &l:fdt, &l:ma, &l:ml] = _a
	else
	    let [ &l:lz, &l:syntax, &l:ft, &l:sol, &l:tw, &l:wrap, &l:fen, &l:fdm, &l:fdl, &l:fdc, &l:fml, &l:fdt, &l:ma, &l:ml] = _a
	endif
	unlet! g:csv_delim
	call winrestview(_b)
    endtry
endfu
    

let &cpo = s:cpo_save
unlet s:cpo_save

let s:cpo_save = &cpo
set cpo&vim

if exists("g:csv_autocmd_arrange") &&
    \ !exists("#CSV_Edit#BufReadPost")
    aug CSV_Editing
	au!
	au BufReadPost,BufWritePost *.csv,*.dat,*.tsv,*.tab :ru! ftplugin/csv.vim | exe ":sil! InitCSV" | exe ":sil! %ArrangeCol" | setl noro
	au BufWritePre *.csv,*.dat,*.tsv,*.tab :%UnArrangeCol
    aug end
elseif exists("#CSV_Edit#BufReadPost")
    aug CSV_Edit
	au!
    aug end
    aug! CSV_Edit
endif

com! -range -bang Table call <sid>Table(<bang>0, <line1>, <line2>)

fu! <sid>Table(bang, line1, line2)
    " save and restore some options
    if has("conceal")
	let _a = [ &l:lz, &l:syntax, &l:ft, &l:sol, &l:tw, &l:wrap, &l:cole, &l:cocu, &l:fen, &l:fdm, &l:fdl, &l:fdc, &l:fml, &l:fdt]
    else
	let _a = [ &l:lz, &l:syntax, &l:ft, &l:sol, &l:tw, &l:wrap, &l:fen, &l:fdm, &l:fdl, &l:fdc, &l:fml, &l:fdt]
    endif
    let _b = winsaveview()
    " try to guess the delimiter from the specified region, therefore, we need
    " to initialize the plugin to inspect only those lines
    let [ b:csv_start, b:csv_end ] = [ a:line1, a:line2 ]
    " Reset b:did_ftplugin just to be sure
    unlet! b:did_ftplugin
    setl ft=csv lz
    " get indent
    let indent = matchstr(getline(a:line1), '^\s\+')
    exe printf(':sil %d,%ds/^\s\+//e', a:line1, a:line2)
    let last = line('$')

    try
	let b:csv_list=getline(a:line1, a:line2)
	call filter(b:csv_list, '!empty(v:val)')
	call map(b:csv_list, 'split(v:val, b:col.''\zs'')')
	if exists(":CSVTabularize")
	    exe printf("%d,%dCSVTabularize%s", a:line1, a:line2, empty(a:bang) ? '' : '!')
	endif
	unlet! b:col_width b:csv_list
    catch
    finally
	if !empty(indent)
	    " Added one line above a:line1 and several lines below, so need to
	    " correct the range
	    exe printf(':sil %d,%ds/^/%s/e', (a:line1 - 1), (a:line2 + line('$') - last), indent)
	endif
	if has("conceal")
	    let [ &l:lz, &l:syntax, &l:ft, &l:sol, &l:tw, &l:wrap, &l:cole, &l:cocu, &l:fen, &l:fdm, &l:fdl, &l:fdc, &l:fml, &l:fdt] = _a
	else
	    let [ &l:lz, &l:syntax, &l:ft, &l:sol, &l:tw, &l:wrap, &l:fen, &l:fdm, &l:fdl, &l:fdc, &l:fml, &l:fdt] = _a
	endif
	call winrestview(_b)
    endtry
endfu
    

let &cpo = s:cpo_save
unlet s:cpo_save

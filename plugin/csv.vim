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

com! -range -bang Table -call <sid>Table(<bang>0, <line1>, <line2>)

fu! <sid>Table(bang, line1, line2)
    " save and restore some options
    let _a = [ &lz, &syntax, &ft, &sol, &tw, &wrap, &cole, &cocu, &fen, &fdm, &fdl, &fdc, &fml]
    " try to guess the delimiter from the specified region, therefore, we need
    " to initialize the plugin to inspect only those lines
    let [ b:csv_start, b:csv_end ] = [ a:line1, a:line2 ]
    setl ft=csv lz
    let b:csv_list=getline(a:line1, a:line2)
    call filter(b:csv_list, '!empty(v:val)')
    call map(b:csv_list, 'split(v:val, b:col.''\zs'')')
    if exists(":Tabularize")
	exe printf("%d,%dTabularize%s", a:line1, a:line2, empty(a:bang) ? '' : '!')
    endif
    let [ &lz, &syntax, &ft, &sol, &tw, &wrap, &cole, &cocu, &fen, &fdm, &fdl, &fdc, &fml] = _a
endfu
    

let &cpo = s:cpo_save
unlet s:cpo_save

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
    let _a = [ &lz, &syntax, &ft]
    setl ft=csv lz
    InitCSV
    if exists(":Tabularize")
	exe printf("%d,%dTabularize%s", a:line1, a:line2, empty(a:bang) ? '' : '!')
    endif
    let [ &lz, &syntax, &ft] = _a
endfu
    

let &cpo = s:cpo_save
unlet s:cpo_save

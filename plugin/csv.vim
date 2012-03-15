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

let &cpo = s:cpo_save
unlet s:cpo_save

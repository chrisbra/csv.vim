" Install Filetype detection for CSV files
augroup ftdetect_csv
    au!
    au BufRead,BufNewFile *.csv,*.dat,*.tsv,*.tab set filetype=csv
augroup END


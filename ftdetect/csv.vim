" Install Filetype detection for CSV files
augroup ftdetect_csv
    au!
    au BufRead,BufNewFile *.csv,*.dat set filetype=csv
augroup END


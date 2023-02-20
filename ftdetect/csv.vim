" Install Filetype detection for CSV files
au BufRead,BufNewFile *.tsv,*.tab let b:delimiter="\t" | set filetype=csv
au BufRead,BufNewFile *.csv,*.dat set filetype=csv


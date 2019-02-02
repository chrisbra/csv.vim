# Changelog 

## 0.32 (unreleased)
- Add Standard Deviation and Variance to available column calculations
- Remove old Vim 7.3 workarounds (plugin needs now a Vim version 7.4)
- allow to align columns differently (right/left or center align) for
  `ArrangeColumn_CSV` (suggested by Giorgio Robino, thanks!)
- document better how to adjust syntax highlighting (suggested by Giorgio
  Robino, thanks!)
- Allow the `:CSVHeader` command to only display a specific column (suggested
  by Giorgio Robino, thanks!)
- When using `VHeader_CSV` or `Header_CSV` command, check
  number/relativenumber and foldcolumn to make sure, header line is always
  aligened with main window (suggested by Giorgio Robino, thanks!)
- hide search pattern, when calling `SearchInColumn_CSV` (suggested by Giorgio
  Robino, thanks!)
- compute correct width of marginline for `:CSVTable`
- do not allow `:CSVTable` command for csv files, that's what the
  `:CSVTabularize` command is for.
- add progressbar for the `:CSVArrangeCol` command. 
- `InitCSV` accepts a '!' for keeping the b:delimiter (`csv-delimiter`) variable
  (https://github.com/chrisbra/csv.vim/issues/43 reported by Jeet Sukumaran,
  thanks!)
- New text-object iL (Inner Line, to visually select the lines that have the
  same value in the cursor column, as requested at
  https://github.com/chrisbra/csv.vim/issues/44, thanks justmytwospence!)
- `:CSVArrangeColumn` can be given an optional row number and the width will
  be calculated using that row. (https://github.com/chrisbra/csv.vim/issues/45
  reported by jchain, thanks!)
- Allow for hexadecimal `Sort_CSV`
  (https://github.com/chrisbra/csv.vim/issues/46, reported by ThomsonTan,
  thanks!)
- support all flags for `Sort_CSV` as for the builting `:sort` command (except
  for "u" and "r")
- prevent mapping of `<Up>` and `<Down>` in visual mode (reported by naught101 at
  https://github.com/chrisbra/csv.vim/issues/50, thanks!)
- prevent increasing column width on subsequent call of `:ArrangeColumn_CSV`
  (reported by naught101 at https://github.com/chrisbra/csv.vim/issues/51,
  thanks!)
- New Count function `CSVCount()` (reported by jungle-booke at
  https://github.com/chrisbra/csv.vim/issues/49, thanks!)
- fix pattern generation for last column
- `ConvertData_CSV` should filter out folded lines (reported by jungle-booke
  at https://github.com/chrisbra/csv.vim/issues/53, thanks!)
- Make `:CSVTable` ignore folded lines (reported by jungle-booke at 
  https://github.com/chrisbra/csv.vim/issues/56, thanks!)
- Better filtering for dynamic filters (reported by jungle-booke at 
  https://github.com/chrisbra/csv.vim/issues/57, thanks!)
- Implement a `MaxCol_CSV` and `MinCol_CSV` command (reported by jungle-booke at 
  https://github.com/chrisbra/csv.vim/issues/60, thanks!)
- Make `UnArrangeColumn_CSV` strip leading and trailing whitespace (reported
  by SuperFluffy at https://github.com/chrisbra/csv.vim/issues/62, thanks!)
- Do not sort headerlines (reported by jungle-booke at https://github.com/chrisbra/csv.vim/issues/63,
  thanks!)
- Do not error out in `:ArrangeCol` command, if line does not have that many
  columns (reported by SuperFluffy at https://github.com/chrisbra/csv.vim/issues/64, thanks)
- Use `OptionSet`autocommand to adjust window for `CSV_Header` command
- when doing `:ArrangeCol` with bang attribute, unarrange first, so that if
  the alignment changed, it will be adjusted accordingly
- Allow distinct keyword for `MaxCol_CSV` and `MinCol_CSV` command (reported
  by jungle-boogie at https://github.com/chrisbra/csv.vim/issues/67, thanks!)
- When left-aligning columns, don't add trailing whitespace (reported by
  jjaderberg at https://github.com/chrisbra/csv.vim/issues/66, thanks!)
- Do not remove highlighting when calling ":CSVTabularize" (reported by
   hyiltiz at https://github.com/chrisbra/csv.vim/issues/70, thanks!)
- Make `:ArrangeCol` respect given headerlines
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
- display column name on `:Analyze_CSV` command (suggested by indera in
  https://github.com/chrisbra/csv.vim/issues/88, thanks!)
- use :sil for BufWinLeave autocommand (to not display error messages)
  (by Hans-Guenter, https://github.com/chrisbra/csv.vim/pull/90, thanks!)
- add `:AvgCol_CSV` command (suggested by jungle-boogie
  https://github.com/chrisbra/csv.vim/issues/85, thanks!)
- Make `:AddColumn_CSV` work as expected
- Add `:DupColumn` command (suggested by lkraav in
  https://github.com/chrisbra/csv.vim/issues/84, thanks!)
- Do not remove tabs on `:UnArrangeColumn` (reported by taylor-peterson in 
  https://github.com/chrisbra/csv.vim/issues/98, thanks!)
- Allow for better aligning of columns (reported by taylor-peterson in
  https://github.com/chrisbra/csv.vim/issues/99, thanks!)
- `:SearchInColumn` did not work correctly for the last column, if `:ArrangeColumn`
  has been used (reported by Xavier Laviron in #100, thanks!)
- Check that the pattern actually matches for `:CSVDeleteCol /pattern` before
  reporting that a column has been deleted (reported by cometsong in #101, thanks!)
- Allow to delete a range of columns usine `:DeleteColumn 2-3` (suggested by klaernie in
  https://github.com/chrisbra/csv.vim/issues/105, thanks!)
- New command `:SumRow` to display the sum of a row  (suggested by kozross in
  https://github.com/chrisbra/csv.vim/issues/116, thanks!)
- Allow to specify what delimiters to automatically detect using the `g:csv_delim_test` variable
- Use `g:csv_start` and `g_csv_end` to specify how many lines to use when detecting
  the delimiter (default: all lines)
- Make `b:csv_result` available as result of last evaluation (Sum, Max, Deviation, etc..)
  (suggested by serrussel in https://github.com/chrisbra/csv.vim/issues/127 thanks!)
- Make plugin autoloadable (https://github.com/chrisbra/csv.vim/pull/130 done by jeetsukumaran, thanks!)
- Determining the delimiter automatically depends on the locale, therefore use explicitly the
  C locale to parse the output of the `:s/<del>/<del>/nge` command
- Calculate Max columns per current line for Movements correctly
  (https://github.com/chrisbra/csv.vim/issues/141)
- Adjust positions within cell after movement only if starting and
  end cells have the same width, document this as best effort approach.
  (https://github.com/chrisbra/csv.vim/issues/139)
- Do not beep on custom movements commands
  (https://github.com/chrisbra/csv.vim/issues/140)
- Make H/L work consistently with regards to empty cells
  (https://github.com/chrisbra/csv.vim/issues/138)

## 0.31 Jan 15, 2015
- supports for Vim 7.3 dropped
- fix that H on the very first cell, results in an endless loop
  (https://github.com/chrisbra/csv.vim/issues/31, reported by lahvak, thanks!)
- fix that count for `AddColumn` did not work (according to the documentation)
  (https://github.com/chrisbra/csv.vim/issues/32, reported by lahvak, thanks!)
- invalid reference to a WarningMsg() function
- WhatColumn! error, if the first line did not contain as many fields
  as the line to check.
- Rename `:Table` command to `:CSVTable` (
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
- New public function `CSVSum()`
- Restrict `csv-arrange-autocmd` to specific file sizes (suggested by Spencer
  Boucher in https://github.com/chrisbra/csv.vim/issues/39, thanks!)
- Make `:CSVSearchInColumn` wrap pattern in '%\(..\)' pairs, so it works
  correctly with '\|' atoms
- Small improvements on `:CSVTable` and `:NewDelimiter` command
- <Up> and <Down> should skip folds (like in normal Vi mode, suggested by
  Kamaraju Kusuma, thanks!)
- Do not remap keys in visual mode (reported by jeffzemla in 
  https://github.com/chrisbra/csv.vim/issues/111, thanks!)

## 0.30 Mar 27, 2014
- `:CSVSubstitute` should substitute all matches in a column, when 'g' flag is
  given
- Don't override 'fdt' setting (https://github.com/chrisbra/csv.vim/issues/18,
  reported by Noah Frederick, thanks!)
- Consistent Commands naming (https://github.com/chrisbra/csv.vim/issues/19,
  reported by Noah Frederick, thanks!)
- New Function `CSVField()` and `CSVCol()`
- clean up function did not remove certain buffer local variables,
  possible error when calling Menu function to disable CSV menu
- make `:CSVArrangeColumn` do not output the numer of substitutions happened
  (suggested by Caylan Larson, thanks!)
- better cleaning up on exit, if Header windows were used
- Let `:CSVVHeader` accept a number, of how many columns to show
  (suggested by Caylan Larson, thanks!)
- better error-handling for `CSVFixed`
- selection of inner/outer text objects  was wrong, reported by Ingo Karkat,
  thanks!)
- errors, when using `:CSVAnalyze` and there were empty attributes
- allow to left-align columns when using `:CSVArrangeColumn`
- `SumCol_CSV` did not detect negative values
- make <cr> in (Virtual-) Replace work as documented

## 0.29 Aug 14, 2013
- setup `QuitPre` autocommand to quit cleanly in newer vims when using :Header
  and :VHeader
- new `AddColumn_CSV` command
- prevent mapping of keys, if g:csv_nomap_<keyname> is set
  (reported by ping)
- new `Substitute_CSV` command
- better syntax highlighting
- small speedup for `ArrangeColumn_CSV`
- 'E' did not correctly move the the previous column
- support for vim-airline added

## 0.28 Dec 14, 2012
- new command :Table to create ascii tables for non-csv files

## 0.27 Nov 21, 2012
- Better `CSV-Tabularize`
- Documentation update

## 0.26 Jul 25, 2012
- Better handling of setting filetype specific options
- `CSV-Tabularize`
- fix some small errors

## 0.25 May 17, 2012
- `SearchInColumn_CSV` should match non-greedily, patch by Matěj Korvas,
- better argument parsing for `SearchInColumn_CSV`, patch by Matěj Korvas,
  thanks!

## 0.24 Apr 12, 2012
- Allow to transpose the file (`csv-transpose`, suggested by Karan Mistry,
  thanks!)
- `DeleteColumn_CSV` allows to specify a search pattern and all matching
  columns will be deleted (suggested by Karan Mistry, thanks!)

## 0.23 Mar 25, 2012
- Don't error out, when creating a new file and syntax highlighting
  script can't find the delimiter
  (ftplugin will still give a warning, so).
- Don't pollute the search register when loading a file
- Give Warning when number format is wrong
- Don't source ftdetect several times (patch by Zhao Cai, thanks!)
- `NewDelimiter_CSV` to change the delimiter of the file
- `Duplicate_CSV` to check for duplicate records in the file
- Issue https://github.com/chrisbra/csv.vim/issues/13 fixed (missing quote,
  reported by y, thanks!)
- `CSVPat()` function
- 'lz' does not work with `:silent` `:s` (patch by Sergey Khorev, thanks!)
- support comments (`csv_comment`, suggested by Peng Yu, thanks!)

## 0.22 Nov 08, 2011
- Small enhancements to `SumCol_CSV`
- :Filters! reapplys the dynamic filter
- Apply `csv-aggregate-functions` only to those values, that are
  not folded away.
- `SumCol_CSV` can use a different number format (suggested by James Cole,
  thanks! (also `csv-nrformat`
- Documentation updates (suggested by James Cole and Peng Yu)
- More code cleanup and error handling
  https://github.com/chrisbra/csv.vim/issues/9 reported Daniel Carl, thanks!
  https://github.com/chrisbra/csv.vim/issues/8 patch by Daniel Carl, thanks!
- New Command `NewRecord_CSV` (suggest by James Cole, thanks!)
- new textobjects InnerField (if) and outerField (af) which contain the field
  without or with the delimiter (suggested by James Cole, thanks!)
- `csv-arrange-autocmd` to let Vim automatically visually arrange the columns
  using `ArrangeColumn_CSV`
- `csv-move-folds` let Vim move folded lines to the end
- implement a Menu for graphical Vim

## 0.21 Oct 06, 2011
- same as 0.20 (erroneously uploaded to vim.org)

## 0.20 Oct 06, 2011

- Implement a wizard for initializing fixed-width columns (`CSVFixed`)
- Vertical folding (`VertFold_CSV`)
- fix plugin indentation (by Daniel Karl, thanks!)
- fixed missing bang parameter for HiColumn function (by Daniel Karl, thanks!)
- fixed broken autodection of delimiter (reported by Peng Yu, thanks!)

## 0.19 Sep 26, 2011

- Make `:ArrangeColumn` more robust
- Link CSVDelimiter to the Conceal highlighting group for Vim's that have
  +conceal feature (suggested by John Orr, thanks!)
- allow the possibility to return the Column name in the statusline `csv-stl`
  (suggested by John Orr, thanks!)
- documentation updates
- Allow to dynamically add Filters, see `csv-filter`
- Also display what filters are active, see `:Filter`
- Analyze a column for the distribution of a value `csv-analyze`
- Implement UnArrangeColumn command `UnArrangeColumn_CSV`
  (suggested by Daniel Karl in https://github.com/chrisbra/csv.vim/issues/7)

## 0.18 Aug 30, 2011

- fix small typos in documentation
- document, that 'K' and 'J' have been remapped and the originial function is
  available as \K and \J
- Delimiters should not be highlighted within a column, only when used
  as actual delimiters (suggested by Peng Yu, thanks!)
- Performance improvements for `:ArrangeColumn`

## 0.17 Aug 16, 2011

- small cosmetic changes
- small documentation updates
- fold away changelog in help file
- Document, that `DeleteColumn_CSV` deletes the column on which the cursor
  is, if no column number has been specified
- Support csv fixed width columns (`csv-fixedwidth`)
- Support to interactively convert your csv file to a different
  format (`csv-convert`)

## 0.16 Jul 25, 2011

- Sort on the range, specified (reported by Peng Yu, thanks!)
- `MoveCol_CSV` to move a column behind another column (suggested by Peng Yu,
  thanks!)
- Document how to use custom functions with a column
  (`csv-aggregate-functions`)
- Use g:csv_highlight_column variable, to have Vim automatically highlight the
  column on which the cursor is (`csv-hicol`)
- Header/VHeader command should work better now (`Header_CSV`, `VHeader_CSV`)
- Use setreg() for setting the register for the `Column_CSV` command and make
  sure it is blockwise.
- Release 0.14 was not correctly uploaded to vim.org

## 0.14 Jul 20, 2011

- really use g:csv_no_conceal variable (reported by Antonio Ospite, thanks!)
- Force redrawing before displaying error messages in syntax script (reported
  by Antonio Ospite, thanks!)
- Make syntax highlighting work better with different terminals (Should work
  now with 8, 88 and 256 color terminals, tested with linux konsole, xterm and
  rxvt) (https://github.com/chrisbra/csv.vim/issues/4)
- Automatically detect '|' as field separator for csv files

## 0.13 Mar 14, 2011

- documentation update
- https://github.com/chrisbra/csv.vim/issues#issue/2 ('splitbelow' breaks
  `Header_CSV`, fix this; thanks lespea!)
- https://github.com/chrisbra/csv.vim/issues#issue/3 ('gdefault' breaks
  `ArrangeColumn_CSV`, fix this; thanks lespea!)
- https://github.com/chrisbra/csv.vim/issues#issue/1 (make syntax highlighting
  more robust, thanks lespea!)
- fix some small annoying bugs
- WhatColumn! displays column name

## 0.12 Feb 24, 2011

- bugfix release:
- don't use `:noa` when switching between windows
- make sure, colwidth() doesn't throw an error

## 0.11 Feb 24, 2011

- new command `Copy_CSV`
- `Search_CSV` did not find anything in the last column if no delimiter
  was given (reported by chroyer)
- `VHeader_CSV` display the first column as Header similar to how
  `Header_CSV` works
- `HeaderToggle_CSV` and `VHeaderToggle_CSV` commands that toggle displaying
  the header lines/columns

## 0.10 Feb 23, 2011

- Only conceal real delimiters
- document g:csv_no_conceal variable
- document g:csv_nl variable
- document conceal feature and syntax highlighting
- Normal mode command <Up>/<Down> work like K/J
- More robust regular expression engine, that can also handle newlines inside
  quoted strings.
- Slightly adjusted syntax highlighting

## 0.9 Feb 19, 2011

- use conceal char depending on encoding
- Map normal mode keys also for visual/select and operator pending mode

## 0.8 Feb 17, 2011

- Better Error handling
- HiColumn! removes highlighting
- Enable NrColumns, that was deactivated in v.0.7
- a ColorScheme autocommand makes sure, that the syntax highlighting is
  reapplied, after changing the colorscheme.
- SearchInColumn now searches in the current column, if no column has been
  specified
- A lot more documentation
- Syntax Highlighting conceales delimiter
- small performance improvements for `ArrangeColumn_CSV`

## 0.7 Feb 16, 2011

- Make the motion commands 'W' and 'E' work more reliable
- Document how to setup filetype plugins
- Make `WhatColumn_CSV` work more reliable (report from
  http://vim.wikia.com/Script:3280)
- DeleteColumn deletes current column, if no argument given
- `ArrangeColumn_CSV` handles errors better
- Code cleanup
- Syntax highlighting
- 'H' and 'L' move forward/backwards between csv fields
- 'K' and 'J' move upwards/downwards within the same column
- `Sort_CSV` to sort on a certain column
- `csv-tips` on how to colorize the statusline

## 0.6 Feb 15, 2011

- Make `ArrangeColumn_CSV` work more reliable (had problems with multibyte
  chars before)
- Add `Header_CSV` function
- 'W' and 'E' move forward/backwards between csv fields
- provide a file ftdetect/csv.vim to detect csv files

## 0.5 Apr 20 2010

- documentation update
- switched to a public repository: http://github.com/chrisbra/csv.vim
- enabled GLVS (see `GLVS`)

## 0.4a Mar 11 2010

- fixed documentation

## 0.4  Mar 11 2010

- introduce `InitCSV`
- better Error handling
- HiColumn now by default highlights the current column, if no argument is
  specified.

## 0.3  Oct, 28 2010

- initial Version

# Introduction [![Say Thanks!](https://img.shields.io/badge/Say%20Thanks-!-1EAEDB.svg)](https://saythanks.io/to/cb%40256bit.org)

This plugin is used for handling column separated data with Vim. Usually those
files are called csv files and use the ',' as delimiter, though sometimes they
use e.g. the '|' or ';' as delimiter and there also exists fixedwidth columns.
The aim of this plugin is to ease handling these kinds of files.

This is a filetype plugin for CSV files. It was heavily influenced by
the [Vim Wiki Tip667](http://vim.wikia.com/wiki/VimTip667), though it
works differently.

It will make use of the [vartabs](https://vimhelp.org/options.txt.html#%27vartabstop%27) feature for tab delimited files.

By default, some remapings are done, including `E` to go back to the previous column (comma) which is obviously not the best option :
it'd be logical to use `B` to do so. Fortunately, you can set your favourite key to do this action just by setting a variable in your config.
Follow the indications [there](#map-b-instead-of-e-to-jump-back-to-previous-column) (also in the builtin docs).

![Screenshot](http://www.256bit.org/~chrisbra/csv.gif)

# Table of Contents
- [Installation](#installation)
  * [Using a Plugin Manager](#using-a-plugin-manager)
  * [Manual Installation](##manual-installation)
- [Commands](#commands)
  * [WhatColumn](#whatcolumn)
  * [NrColumns](#nrcolumns)
  * [SearchInColumn](#searchincolumn)
  * [HiColumn](#hicolumn)
  * [ArrangeColumn](#arrangecolumn)
  * [UnArrangeColumn](#unarrangecolumn)
  * [DeleteColumn](#deletecolumn)
  * [CSVInit](#csvinit)
  * [Header Lines](#header-lines)
  * [Sort](#sort)
  * [Copy Column](#copy-column)
  * [Move A Column](#move-a-column)
  * [Sum of a Column](#sum-of-a-column)
  * [Create new Records](#create-new-records)
  * [Change the delimiter](#change-the-delimiter)
  * [Check for duplicate records](#check-for-duplicate-records)
  * [Normal mode commands](#normal-mode-commands)
  * [Converting a CSV File](#converting-a-csv-file)
  * [Dynamic filters](#dynamic-filters)
  * [Analyze a Column](#analyze-a-column)
  * [Vertical Folding](#vertical-folding)
  * [Transposing a column](#transposing-a-column)
  * [Transforming into a table](#transforming-into-a-table)
  * [Add new empty columns](#add-new-empty-columns)
  * [Substitute in columns](#substitute-in-columns)
  * [Count Values inside a Column](#count-values-inside-a-column)
  * [Maximum/Minimum value of a Column](#maximumminimum-value-of-a-column)
  * [Average value of a Column](#average-value-of-a-column)
  * [Variance of a Column](#variance-of-a-column)
  * [Standard Deviation of a Column](#standard-deviation-of-a-column)
  * [Duplicate columns](#duplicate-columns)
  * [Column width](#column-width)
  * [Sum of Numbers in a row](#sum-of-numbers-in-a-row)
- [CSV Configuration](#csv-configuration)
  * [Delimiter](#delimiter)
  * [Column](#column)
  * [Highlighting Group](#highlighting-group)
  * [Strict Columns](#strict-columns)
  * [Concealing](#concealing)
  * [Newlines](#newlines)
  * [Highlight column automatically](#highlight-column-automatically)
  * [Fixed width columns](#fixed-width-columns)
    + [Manual setup](#manual-setup)
    + [Setup using a Wizard](#setup-using-a-wizard)
  * [CSV Header lines](#csv-header-lines)
  * [Number format](#number-format)
  * [Move folded lines](#move-folded-lines)
  * [Using comments](#using-comments)
  * [Size and performance considerations](#size-and-performance-considerations)
  * [Map `B` instead of `E` to jump back to previous column](#map-b-instead-of-e-to-jump-back-to-previous-column)
- [Functions](#functions)
  * [CSVPat()](#csvpat)
  * [CSVField(x,y[, orig])](#csvfieldxy-orig)
  * [CSVCol([name])](#csvcolname)
  * [CSVSum(col, fmt, startline, endline)](#csvsumcol-fmt-startline-endline)
  * [CSVCount(col, fmt, startline, endline[, distinct])](#csvcountcol-fmt-startline-endline-distinct)
  * [CSVMax(col, fmt, startline, endline)](#csvmaxcol-fmt-startline-endline)
  * [CSVMin(col, fmt, startline, endline)](#csvmincol-fmt-startline-endline)
  * [CSVAvg(col, fmt, startline, endline)](#csvavgcol-fmt-startline-endline)
  * [CSVWidth()](#csvwidth)
- [CSV Tips and Tricks](#csv-tips-and-tricks)
  * [Statusline](#statusline)
  * [Slow CSV plugin](#slow-csv-plugin)
  * [Defining custom aggregate functions](#defining-custom-aggregate-functions)
  * [Autocommand on opening/closing files](#autocommand-on-openingclosing-files)
  * [Syntax error when opening a CSV file](#syntax-error-when-opening-a-csv-file)
  * [Calculate new columns](#calculate-new-columns)
  * [Use the result of an evaluation in insert mode](#use-the-result-of-an-evaluation-in-insert-mode)

# Installation

## Using a plugin manager

This plugin follows the standard runtime path structure, and as such it can be installed with a variety of plugin managers:

| Plugin Manager | Install with... |
| ------------- | ------------- |
| [Pathogen][1] | `git clone https://github.com/chrisbra/csv.vim ~/.vim/bundle/csv`<br/>Remember to run `:Helptags` to generate help tags |
| [NeoBundle][2] | `NeoBundle 'chrisbra/csv.vim'` |
| [Vundle][3] | `Plugin 'chrisbra/csv.vim'` |
| [VAM][4] | `call vam#ActivateAddons([ 'csv' ])` |
| [Plug][5] | `Plug 'chrisbra/csv.vim'` |
| [Dein][6] | `call dein#add('chrisbra/csv.vim')` |
| [minpac][7] | `call minpac#add('chrisbra/csv.vim')` |
| pack feature (native Vim 8 package feature)| `git clone https://github.com/chrisbra/csv.vim ~/.vim/pack/dist/start/csv`<br/>Remember to run `:helptags` to generate help tags |
| manual | copy all of the files into your `~/.vim` directory (see below)|

## Manual installation

In order to have vim automatically detect csv files, you need to have
[`ftplugins`](http://vimhelp.appspot.com/usr_05.txt.html#ftplugins) enabled (e.g. by having this line in your [[`.vimrc`](http://vimhelp.appspot.com/starting.txt.html#.vimrc)](http://vimhelp.appspot.com/starting.txt.html#.vimrc) file:

```vim
:filetype plugin on
```

The plugin already sets up some logic to detect CSV files. By default,
the plugin recognizes `*.csv` and `*.dat` files as CSV filetype. In order that the
CSV filetype plugin is loaded correctly, vim needs to be enabled to load
[`filetype-plugins`](http://vimhelp.appspot.com/filetype.txt.html#filetype-plugins). This can be ensured by putting a line like this in your
[`.vimrc`](http://vimhelp.appspot.com/starting.txt.html#.vimrc):

```vim
:filetype plugin on
```
(see also [:filetype-plugin-on](http://vimhelp.appspot.com/filetype.txt.html#:filetype-plugin-on)).

In case this did not work, you need to setup vim like this:

To have Vim automatically detect csv files, you need to do the following.

   1. Create your user runtime directory if you do not have one yet. This
      directory needs to be in your 'runtime' path. In Unix this would
      typically the \~/.vim directory, while in Windows this is usually your
      \~/vimfiles directory. Use `:echo expand("~")` to find out what Vim thinks
      your user directory is.
      To create this directory, you can do:

      ```vim
      :!mkdir ~/.vim
      ```
      for Unix and
      ```vim
      :!mkdir ~/vimfiles
      ```
      for Windows.

   2. In that directory you create a file that will detect csv files.

      ```vim
      if exists("did_load_csvfiletype")
        finish
      endif
      let did_load_csvfiletype=1

      augroup filetypedetect
        au! BufRead,BufNewFile *.csv,*.dat	setfiletype csv
      augroup END
      ```

      You save this file as "filetype.vim" in your user runtime diretory:

      ```vim
      :w ~/.vim/filetype.vim
      ```
   3. To be able to use your new filetype.vim detection, you need to restart
	  Vim. Vim will then  load the csv filetype plugin for all files whose
	  names end with .csv.

# Commands

The CSV ftplugin provides several Commands. All commands are also provided
with the prefix :CSV (e.g. [:CSVNrColumns](#nrcolumns))

## WhatColumn

If you would like to know, on which column the cursor is, use

```vim
:WhatColumn
```
or

```vim
:CSVWhatColumn
```
Use the bang attribute, if you have a heading in the first line and you want
to know the name of the column in which the cursor is:

```vim
:WhatColumn!
```
## NrColumns

`:NrColumns` and `:CSVNrColumns` outputs the maximum number of columns
available. It does this by testing the first 10 lines for the number of
columns. This usually should be enough. If you use the '!' attribute, it
outputs the number of columns in the current line.

## SearchInColumn

Use `:SearchInColumn` or `:CSVSearchInColumn` to search for a pattern within a
specific column. The usage is:

```vim
:SearchInColumn [<nr>] /{pat}/
```

So if you would like to search in Column 1 for the word foobar, you enter

```vim
:SearchInColumn 1 /foobar/
```

Instead of / as delimiter, you can use any other delimiter you like. If you
don't enter a column, the current column will be used.

## HiColumn

`:HiColumn` or `:CSVHiColumn` `<nr>` can be used to highlight Column `<nr>`.
Currently the plugin uses the WildMenu Highlight Group. If you would like to
change this, you need to define the variable `g:csv_hiGroup`.

If you do not specify a `<nr>`, HiColumn will highlight the column on which the
cursor is. Use

```vim
:HiColumn!
```

to remove any highlighting.

If you want to automatically highlight a column, see [Highlight column automatically](#highlight-column-automatically)

## ArrangeColumn

If you would like all columns to be visually arranged, you can use the
`:ArrangeColumn` or `:CSVArrangeColumn` command:

```vim
:[range]ArrangeColumn[!] [<Row>]
```

Beware, that this will change your file and depending on the size of
your file may slow down Vim significantly. This is highly experimental.
:ArrangeColumn will try to vertically align all columns by their maximum
column size. While the command is run, a progressbar in the statusline 'stl'
will be shown.

Use the bang attribute to force recalculating the column width. This is
slower, but especially if you have modified the file, this will correctly
calculate the width of each column so that they can be correctly aligned. If
no column width has been calculated before, the width will be calculated, even
if the '!' has not been given.

If `<Row>` is given, will use the Row, to calculate the width, else will
calculate the maximum of at least the first 10,000 rows to calculate the
width. The limit of 10,000 is set to speed up the processing and can be
overriden by setting the "b:csv_arrange_use_all_rows" variable (see below).

If [range] is not given, it defaults to the current line.

By default, the columns will be right-aligned. If you want a different
alignment you need to specify this through the b:csv_arrange_align variable.
This is a string of flags ('r': right align, 'l': left align, 'c': center
alignment, '.': decimal alignment) where each flag defines the alignment for
a particular column (starting from left). Missing columns will be right aligned.
You can use '\*' to repeat the previous value until the end.
So this:

```vim
:let b:csv_arrange_align = 'lc.'
```
Will left-align the first column, center align the second column, decimal
align the third column and all following columns right align. (Note: decimal
aligning might slow down Vim and additionally, if the value is no decimal
number it will be right aligned).
And this:

```vim
:let b:csv_arrange_align = 'l*'
```
will left align all columns. The CSV plugin uses the `g:csv_arrange_align`
variable as a fallback, if `b:csv_arrange_align` does not exists. So if you
always want to have left alignment, you simply set this variable in your
.vimrc file:

```vim
:let g:csv_arrange_align='l*'
```

If you change the alignment parameter, you need to use the "!" attribute, the
next time you run the `:ArrangeCol` command, otherwise for performance
reasons, it won't be considered.

Note, arranging the columns can be very slow on large files or many columns (see
[Slow CSV plugin](#slow-csv-plugin) on how to increase performance for this command). For large files,
calculating the column width can take long and take a considerable amount of
memory. Therefore, the csv plugin will at most check 10.000 lines for the
width. Set the variable b:csv_arrange_use_all_rows to 1 to use all records:

```vim
:let b:csv_arrange_use_all_rows = 1
```
(this could however in the worst case lead to a crash).

To disable the statusline progressbar set the variable g:csv_no_progress:

```vim
:let g:csv_no_progress = 1
```
This will disable the progressbar and slightly improve performance (since no
additional redraws are needed).

Note: this command does not work for fixed width columns [Fixed width columns](#fixed-width-columns)

See also [Autocommand on opening/closing files](#autocommand-on-openingclosing-files) on how to have vim automatically arrange a CSV
file upon entering it.

## UnArrangeColumn

If you would like to undo a previous :ArrangeColumn command, you can use this
`:UnArrangeColumn` or `:CSVUnArrangeColumn` command:

```vim
:[range]UnArrangeColumn
```

Beware, that is no exact undo of the :ArrangeColumn command, since it strips
away all leading blanks for each column. So if previously a column contained
only some blanks, this command will strip all blanks.

If [range] is given, it defaults to the current line.

## DeleteColumn

The command `:DeleteColumn` or `:CSVDeleteColumn` can be used to delete a specific column.
```vim
:DeleteColumn 2
```

will delete column 2. If you use `:DeleteColumn 2-3` columns 2 and 3 will be
deleted.

If you don't specify a column number, it will delete the column on which the
cursor is. Alternatively, you can also specify a search string. The plugin
will then delete all columns that match the pattern:
```vim
:DeleteColumn /foobar
```
will delete all columns where the pattern "foobar" matches.

## CSVInit

Reinitialize the Plugin. Use this, if you have changed the configuration
of the plugin (see [CSV Configuration](#csv-configuration) ).
If you use the bang (!) attribute, it will keep the b:delimiter configuration
variable.

## Header Lines

The `:Header` or `:CSVHeader` command splits the csv-buffer and adds a window,
that holds a small fraction of the csv file. This is useful, if the first line
contains some kind of a heading and you want always to display it. This works
similar to fixing a certain line at the top. As optional argument, you can
give the number of columns from the top, that shall be displayed. By default,
1 is used (You can define your own default by setting the b:csv_headerline
variable, see [CSV Header lines](#csv-header-lines)). Use the '!' to close this window. So this

```vim
:Header 3
```

opens at the top a split window, that holds the first 3 lines, is fixed
and horizontally 'scrollbind'ed to the csv window and highlighted using the
CSVHeaderLine highlighting.
To close the header window, use

```vim
:Header!
```

Note, this won't work with linebreaks in the column.

Note also, that if you already have a horizontal header window (`VHeader_CSV`),
this command will close the horizontal Header window. This is because of a
limitation of Vim itself, which doesn't allow to sync the scrolling between
two windows horizontally and at the same time have another window only sync
its scrolling vertically.

Note: this command does not work for fixed width columns [Fixed width columns](#fixed-width-columns)

If you want a vertical header line, use `:VHeader` or `:CSVVHeader`. This works
similar to the `Header_CSV` command, except that it will open a vertical split
window with the first column always visible. It will always open the first
column in the new split window. Use the '!' to close the window. If you
specify a count, that many columns will be visible (default: the first). Add
the bang to the count, if you only want the specific column to be visible.

```vim
:VHeader 2
```
This will open a vertical split window containing the first 2 columns, while

```vim
:VHeader 2!
```
Opens a new vertical split window containing only the 2 second column.

Note, this won't work with linebreaks in the column.
Note also: this command does not work for fixed width columns [Fixed width columns](#fixed-width-columns)


Use the `:HeaderToggle` and `:VHeaderToggle` command to toggle displaying the
horizontal or vertical header line. Alternatively, use `:CSVHeaderToggle` or
`:CSVVHeaderToggle`

## Sort

The command `:Sort` or `:CSVSort` can be used to sort the csv file on a
certain column. If no range is given, is sorts the whole file. Specify the
column number to sort on as argument. Use the '!' attribute to reverse the
sort order. For example, the following command sorts line 1 til 10 on the 3
column

```vim
:1,10Sort 3
```

While this command

```vim
:1,10Sort! 3
```

reverses the order based on column 3. If you want numeric sort on floatng
points, you can use:
```vim
:2,$Sort 3f
```

The column number can be optionally followed by any of the flags [i], [n],
[x] and [o] for [i]gnoring case, sorting by [n]umeric, he[x]adecimal
[o]ctal or [f]loat value.

When no column number is given, it will sort by the column, on which the
cursor is currently.

## Copy Column

If you need to copy a specific column, you can use the command `:CSVColumn` or
`:Column`

```vim
:[N]Column[!] [a]
```

Copy column N into register a. This will copy all the values, that are
not folded-away ([Dynamic filters](#dynamic-filters)) and skip comments.
If the bang (`!`) attribute is given, skips the Header Lines.

If you don't specify N, the column of the current cursor position is used.
If no register is given, the default register
[`quotequote`](http://vimhelp.appspot.com/change.txt.html#quotequote) is used.

## Move A Column

You can move one column to the right of another column by using the
`:CSVMoveColumn` or `:MoveColumn` command

```vim
:[range]MoveColumn [source] [dest]
```

This moves the column number source to the right of column nr destination. If
both arguments are not given, move the column on which the cursor is to the
right of the current last column. If [range] is not given, MoveColumn moves
the entire column, otherwise, it moves the columns only for the lines within
the range, e.g. given that your first line is a header line, which you don't
want to change

```vim
:2,$MoveColumn 1 $
```

this would move column 1 behind the last column, while keeping the header line
as is.


## Sum of a Column

You can let Vim output the sum of a column using the `:CSVSumCol` or `:SumCol`
command

```vim
:[range]SumCol [nr] [/format/]
```

This outputs the result of the column `<nr>` within the range given. If no range
is given, this will calculate the sum of the whole column. If `<nr>` is not
given, this calculates the sum for the column the cursor is on. Note, that the
delimiter will be stripped away from each value and also empty values won't be
considered.

See also [Defining custom aggregate functions](#defining-custom-aggregate-functions)

## Create new Records

If you want to create one or several records, you can use the `:NewRecord` or
`:CSVNewRecord` command:

```vim
:[range]NewRecord [count]
```

This will create in each line given by range [count] number of new empty
records. If [range] is not specified, creates a new line below the line the
cursor is on and if count is not given, it defaults to 1.

## Change the delimiter

If you want to change the field delimiter of your file you can use the
`:CSVNewDelimiter` or `:NewDelimiter` command:

```vim
:NewDelimiter char
```

This changes the field delimiter of your file to the new delimiter "char".
Note: Will remove trailing delimiters.

## Check for duplicate records

If you want to check the file for duplicate records, use the command
`:Duplicate` or `:CSVDuplicate`:

```vim
:Duplicate [columnlist]
```

Columnlist needs to be a numeric comma-separated list of all columns that you
want to check. You can also use a range like '2-5' which means the plugin
should check columns 2,3,4 and 5. If no columnlist ist given, will use the
current column.

If the plugin finds a duplicate records, it outputs its line number (but it
only does that at most 10 times). You can find the message also in the message
history using `:mess`.

## Normal mode commands

The csv filetype plugin redefines the following keys as:

Key | Effect
--- | ---
`<C-Right>` or L or W | Move [count] field forwards
`<C-Left>` or E or H | Move [count] field backwards (but see below for the difference of E and H).
`<Up>` or K | Move [count] lines upwards within the same column
`<Down>` or J | Move [count] lines downwards within the same column
`<Enter>` | Dynamically fold all lines away, that don't match the value in the current column. See [Dynamic filters](#dynamic-filters) In [`Replace-mode`](http://vimhelp.appspot.com/insert.txt.html#Replace-mode) and [`Virtual-Replace-mode`](http://vimhelp.appspot.com/insert.txt.html#Virtual-Replace-mode) does not create a new row, but instead moves the cursor to the beginning of the same column, one more line below.
`<Space>` | Dynamically fold all lines away, that match the value in the current column. See [Dynamic filters](#dynamic-filters)
`<BS>` | Remove last item from the dynamic filter. See [Dynamic filters](#dynamic-filters)

The upwards and downwards motions try to keep the cursor in the relative
position within the cell when changing lines. That is not a guaranteed to work
and will fail if the upper/lower cell is of a different width than the
starting cell.

Note how the mapping of 'H' differs from 'E'

H step fields backwards but also stops at where the content of the columns
begins.

If you look into this example (with the cursor being '|')

```
aaa,   bbbb,|ccc
```

Pressing 'H' moves to

```
aaa,   |bbbb,ccc
```

Pressing 'H' again moves to

```
aaa,|	bbbb,ccc
```

Pressing 'H' again moves to

```
|aaa,	bbbb,ccc
```

While with 'E', the cursor moves to:

```
 aaa,|	bbbb,ccc
```

and pressing  'E' again, it would move directly to

```
|aaa,	bbbb,ccc
```

Also, the csv plugin defines these text-object:

Field | Meaning
--- | ---
if | Inner Field (contains everything up to the delimiter)
af | Outer Field (contains everything up to and including the delimiter)
iL | Inner Line (visually linewise select all lines, that has the same value at the cursor's column)

Note, that the `<BS>`, `<CR>`, K and J overlap Vim's default mapping for `<CR>`,
`<BS>`, `J` and `K` respectively. Therefore, this functionality has been
mapped to a sane default of `<Localleader>`J and `<LocalLeader>`K. If you haven't
changed the `<Leader>` or `<LocalLeader>` variables, those the `<Localleader>`
is equival to a single backslash '\', e.g. \K would run the lookup function on
the word under the cursor and \J would join this line with the previous line.

If you want to prevent the mapping of keys, simply set the global variable
`g:csv_nomap_<key>` to 1, e.g. to prevent mapping of `<CR>` in csv files, put

```vim
let g:csv_nomap_cr = 1
```
into your [`.vimrc`](http://vimhelp.appspot.com/starting.txt.html#.vimrc). Note, the keyname must be lower case.

Also the csv plugins follows the general consensus, that when the variable
`g:no_plugin_maps` or `g:no_csv_maps` is set, no key will be mapped.

## Converting a CSV File

You can convert your CSV file to a different format with the `:ConvertData`
or `:CSVConvertData` command

```vim
[range]ConvertData[!]
```

Use the the bang ("!") attribute, to convert your data without the delimiter.
If [range] is given, will only convert the lines in range.

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
call the

```vim
:ConvertData
```

At this point, Vim will ask you for input. First, you need to specify, what
needs to be done before processing the data:

```
Pre convert text: <html><body><table>
```

This would specify to put the HTML Header before the actual data can be
processed. If the variable g:csv_pre_convert is already defined, Vim will
already show you its' content as default value. Simply pressing Enter will use
this data. After that, Vim asks, what the end of the converted file needs to
look like:

```
Post convert text: </table></body></html>
```

So here you are defining how to finish up the HTML file. If the variable
g:csv_post_convert is already defined, Vim will already show you its' content
as default value which you can confirm by pressing Enter. Last, you define,
how your columns need to be converted. Again, Vim asks you for how to do that:

```
How to convert data (use %s for column input):
<tr><td>%s</td><td>%s</td><td>%s</td></tr>
```

This time, you can use '%s' expandos. They tell Vim, that they need to be
replaced by the actual content of your file. It does by going from the first
column in your file and replacing it with the corresponding %s in that order.
If there are less '%s' expandos then columns in your file, Vim will skip the
columns, that are not used. Again If the variable g:csv_convert is already
defined, Vim will already show you its' content as default value which you can
confirm by pressing Enter.

After you hit Enter, Vim will convert your data and put it into a new window.
It may look like this:

```html
<html><body><table>
<tr><td>1,</td><td>2,</td><td>3,</td></tr>
<tr><td>2,</td><td>2,</td><td>4,</td></tr>
</table></body></html>
```

Note, this is only a proof of concept. A better version of converting your
data to HTML is bundled with Vim ([`:TOhtml`](http://vimhelp.appspot.com/syntax.txt.html#%3ATOhtml)).

But may be you want your data converted into SQL-insert statements. That could
be done like this:

```vim
ConvertData!
```

```
Pre convert text:
```

(Leave this empty. It won't be used).

```
Post convert text: Commit;
```

After inserting the data, commit it into the database.

```
How to convert data (use %s for column input):
Insert into table foobar values ('%s', '%s', %s);
```

Note, that the last argument is not included within single quotation marks,
since in this case the data is assumed to be integer and won't need to be
quoted for the database.

After hitting Enter, a new Window will be opened, which might look like this:

```
Insert into table foobar values('Foobar', '2', 2011);
Insert into table foobar values('Bar', '1', 2011);
Commit;
```

Since the command was used with the bang attribute (!), the converted data
doesn't include the column delimiters.

Now you can copy it into your database, or further manipulate it.

## Dynamic filters

If you are on a value and only want to see lines that have the same value in
this column, you can dynamically filter the file and fold away all lines not
matching the value in the current column. To do so, simply press `<CR>` (Enter).
Now Vim will fold away all lines, that don't have the same value in this
particular row. Note, that leading blanks and the delimiter is removed and the
value is used literally when comparing with other values. If you press `<Space>`
on the value, all fields having the same value will be folded away.
Pressing `<BS>` will remove the last item from the dynamic filter. To remove all
filters, keep pressing `<BS>` until no more filters are present.

The way this is done is, that the value from the column is extracted and a
regular expression for that field is generated from it. In the end this
regular expression is used for folding the file.

A subsequent `<CR>` or `<Space>` on another value, will add this value to the
current applied filter (this is like using the logical AND between the
currently active filter and the new value). To remove the last item from the
filter, press `<BS>` (backspace). If all items from the filter are removed,
folding will be disabled.

If some command messes up the folding, you can use [`zX`](http://vimhelp.appspot.com/fold.txt.html#zX) to have the folding
being reinitialized.

By default, the first line is assumed to be the header and won't be folded
away. See also [CSV Header lines](#csv-header-lines).

If you have set the g:csv_move_folds variable and the file is modifiable, all
folded lines will be moved to the end of the file, so you can view all
non-folded lines as one consecutive area  (see also [Move folded lines](#move-folded-lines))

To see the active filters, you can use the `:Filter` or `:CSVFilter` command.
This will show you a small summary, of what filters are active and looks like
this:

Nr | Match | Col | Name | Value
--- | --- | --- | --- | ---
01 | - | 07 | Price | 23.10
02 | + | 08 | Qty | 10

This means, there are two filters active. The current active filter is on
column 7 (column name is Price) and all values that match 23.10 will be folded
away AND all values that don't match a value of 10 in the QTY column will also
be folded away.
When removing one item from the filter by pressing `<BS>`, it will always remove
the last item (highest number in NR column) from the active filter values.

Note, that depending on your csv file and the number of filters you used,
applying the filter might actually slow down vim, because a complex regular
expression is generated that is applied by the fold expression. Look into the
@/ ([`quote_/`](http://vimhelp.appspot.com/change.txt.html#quote_%2F)) register to see its value.

Use [`zX`](http://vimhelp.appspot.com/fold.txt.html#zX) to apply the current value of your search register as filter. Use

```vim
:Filters!
```

to reapply all values from the current active filter and fold non-matching
items away.

## Analyze a Column

If you'd like to know, how the values are distributed among a certain column,
you can use the `:CSVAnalyze` or `:Analyze` command. So

```vim
:Analyze 3
```

outputs the the distribution of the top 5 values in column 3. This looks like
this:

Nr | Count | % | Value
--- | --- | --- | ---
01 | 20 | 50% | 10
02 | 10 | 25% | 2
03 | 10 | 25% | 5

This tells you, that the the value '10' in column 3 occurs 50% of the time
(exactly 20 times) and the other 2 values '2' and '5' occur only 10 times, so
25% of the time.

In addition, a second argument may be used to specify the number of top values.
So

```vim
:Analyze 3 10
```

outputs the the distribution of the top 10 values in column 3, respectively.

## Vertical Folding

Sometimes, you want to hide away certain columns to better view only certain
columns without having to horizontally scroll. You can use the `:CSVVertFold`
or `:VertFold` command to hide certain columns:

```vim
:VertFold [<nr>]
```
This will hide all columns from the first until the number entered. It
currently can't hide single columns, because of the way, syntax highlighting
is used. This command uses the conceal-feature [`:syn-conceal`](http://vimhelp.appspot.com/syntax.txt.html#%3Asyn-conceal) to hide away
those columns. If no nr is given, hides all columns from the beginning till
the current column.

Use

``` vim
:VertFold!
```

to display all hidden columns again.

## Transposing a column

Transposing means to exchange rows and columns. You can transpose the csv
file, using the `:CSVTranspose` or `:Transpose`:

```vim
:[range]Transpose
```
command. If [range] is not given, it will transpose the complete file,
otherwise it will only transpose the lines in the range given. Note, comments
will be deleted and transposing does not work with fixed-width columns.

## Transforming into a table

You  can also transform your csv data into a visual table, using the
`:CSVTabularize` or `:CSVTable`:

```vim
:CSVTabularize
```
command. This will make a frame around your csv data and substitute all
delimiters by '|', so that it will look like a table.

e.g. consider this data:

```
First,Second,Third
10,5,2
5,2,10
2,10,5
10,5,2
```

This will be transformed into:
```
|---------------------|
| First| Second| Third|
|------|-------|------|
|	 10|	  5|	 2|
|	  5|	  2|	10|
|	  2|	 10|	 5|
|	 10|	  5|	 2|
|---------------------|
```

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

Set the variable `g:csv_table_leftalign=1` if you want the columns to be
leftaligned.

Set the variable `g:csv_table_use_ascii=1` if you do not want to use unicode
drawing characters.

Note: Each row must contain exactly as many fields as columns.

This command is available as default plugin. To disable this feature, set the
variable g:csv_disable_table_command to 1:
```vim
    :let g:csv_disable_table_command = 1
```

## Add new empty columns

If you want to add new empty columns to your file you can use the
`:CSVAddColumn` or `:AddColumn` command:

```vim
:[range]AddColumn [column] [count]
```

By default, this works for the whole file, but you can give a different range
to which the AddColumn command applies. If no arguments are given, the new
empty column will be added after the column on which the cursor is. You can
however add as first argument the column number after which the new column
needs to be added.

Additionally, you can also add a count number to add several columns at once
after the specified column number. You 0 for the column number, if you want to
add several columns after the current column.

## Substitute in columns

If you want to substitute only in specific columns, you can use the
`:CSVSubstitute` or `:Substitute` command:

```vim
:[range]Substitute [column/]pattern/string[/flags]
```

This means in the range and within the given columns replace pattern by
string. This works basically like the [`:s`](http://vimhelp.appspot.com/change.txt.html#%3As) command, except that you MUST use
forward slashes / to delimit the command. The optional part `[column/]` can
take either the form of an address or if you leave it out, substitution will
only happen in the current column. Additionally, you can use the `1,5/` form
to substitute within the columns 1 till 5 or you can even use `1,$` which
means to substitute in each column (so in fact this simplifies to a simple
[`:s`](http://vimhelp.appspot.com/change.txt.html#%3As) command whithin the given range. For the use of `[/flags]` see [`:s_flags`](http://vimhelp.appspot.com/change.txt.html#%3As_flags)
Here are some examples:

```vim
:%Substitute 1,4/foobar/baz/gce
```

Substitutes in the whole file in columns 1 till 4 the pattern foobar by baz
for every match ('g' flag) and asks for confirmation ('c' flag).

```vim
:%S 3,$/(\d\+)/\1 EUR/g
```

Substitutes in each column starting from the third each number and appends the
EURO suffix to it.

## Count Values inside a Column

You can let Vim output the number of values inside a column using the `:CSVCountCol`
command

```vim
:[range]CountCol [nr] [distinct]
```

This outputs the number of [distinct] values visible in the column [nr]
If [distinct] is not given, count's all values. Note, header rows and folded
rows won't be counted.

The result is also available in the buffer-local variable `b:csv_result`.

See also [Defining custom aggregate functions](#defining-custom-aggregate-functions)

## Maximum/Minimum value of a Column

You can let Vim output the 10 maximum/minimum values of a column using the
`:CSVMaxCol` command

```vim
:[range]MaxCol [nr][distinct] [/format/]
:[range]MinCol [nr][distinct] [/format/]
```

This outputs the result of the column `<nr>` within the range given. If no range
is given, this will calculate the max value of the whole column. If `<nr>` is not
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
separator and each one is optional. This means, that

```vim
:MaxCol 1 /:,/
```

uses the default thousands separator and ',' as the decimal separator and

```vim
:MaxCol 2 / :./
```

uses the Space as thousands separator and the '.' as decimal separator.

If [distinct] is given, only unique values are returned.

Note, if your Vim is compiled without floating point number format ([`+float`](http://vimhelp.appspot.com/various.txt.html#%2Bfloat)),
Vim will only aggregate the integer part and therefore won't use the 'y'
argument in the /format/ specifier.

The result is also available in the buffer-local variable `b:csv_result`.

See also [Defining custom aggregate functions](#defining-custom-aggregate-functions)

## Average value of a Column

You can let Vim output the value of a column using the `:CSVAvgCol` command

```vim
:[range]AvgCol [nr] [/format/]
```

This outputs the result of the column `<nr>` within the range given. If no range
is given, this will calculate the average value of the whole column. If `<nr>` is not
given, this calculates the average for the column the cursor is on. Note, that the
delimiter will be stripped away from each value and also empty values won't be
considered.

For the `[/format/]` part, see [Number format](#number-format).

The result is also available in the buffer-local variable `b:csv_result`.

See also [Defining custom aggregate functions](#defining-custom-aggregate-functions)

## Variance of a Column

```vim
:[range]PopVarianceCol [nr] [/format/]
```

```vim
:[range]SmplVarianceCol [nr] [/format/]
```

Calculate the Population or Sample Variance for the specified column.

This outputs the result of the column `<nr>` within the range given. If no range
is given, this will calculate the statistical variance of the whole column. If `<nr>` is not
given, this calculates the variance for the column the cursor is on. Note, that the delimiter
will be stripped away from each value and also empty values won't be considered.

The result is also available in the buffer-local variable `b:csv_result`.

For the `[/format/]` part, see [Number format](#number-format).

## Standard Deviation of a Column

```vim
:[range]PopStdCol [nr] [/format/]
```

```vim
:[range]SmplStdCol [nr] [/format/]
```

Calculate the Population or Sample Standard Deviation for the specified column.

This outputs the result of the column `<nr>` within the range given. If no range
is given, this will calculate the standard deviation of the whole column. If `<nr>` is not
given, this calculates the standard deviation for the column the cursor is on. Note, that
the delimiter will be stripped away from each value and also empty values won't be considered.

The result is also available in the buffer-local variable `b:csv_result`.

For the `[/format/]` part, see [Number format](#number-format).

## Duplicate columns

If you want to add duplicate an existing column you can use the
`:CSVDupColumn` or `:DupColumn` command:

```vim
:[range]DupColumn [column] [count]
```

By default, this works for the whole file, but you can give a different range
to which the command applies. By default it will duplicate the column on which
the cursor is, but you can add as first argument `<column>` which column will be duplicated.

Additionally, you can also provide a `<count>` to copy several columns at once.

## Column width

If you want to know the width of all columns, you can use the `:CSVColumnWidth` command:

```vim
:CSVColumnWidth
```
This will output the width of each column at the bottom. See also the [CSVWidth()](#csvwidth) function.

## Sum of Numbers in a row

You can let Vim output the sum of a field in a row using the `:CSVASumRow` command:

```vim
    :[line]SumRow [/format/]
```

This outputs the sum of the row `[line]`. If no line is given, this will
calculate the sum for the current row. Note, that the delimiter will be
stripped away from each value and also empty values won't be considered.

For the `[/format/]` part, see [Number format](#number-format).

# CSV Configuration

The CSV plugin tries to automatically detect the field delimiter for your
file, cause although often the file is called CSV (comma separated values), a
semicolon is actually used. The column separator is stored in the buffer-local
variable b:delimiter. This delimiter is heavily used, because you need
it to define a column. Almost all commands use this variable therefore.

## Delimiter

To override the automatic detection of the plugin and define the separator
manually, use:

```vim
:let g:csv_delim=','
```

to let the comma be the delimiter. This sets the buffer local delimiter
variable b:delimiter.

You can also set default delimiter to prevent a warning if no delimiter can
be detected:

```vim
:let g:csv_default_delim=','
```

If your file does not consist of delimited columns, but rather is a fixed
width csv file, see [Fixed width columns](#fixed-width-columns) for configuring the plugin appropriately.

If you changed the delimiter, you should reinitialize the plugin using
[CSVInit](#csvinit)

Note: the delimiter will be used to generate a regular expression that matches
a column. Internally the plugin uses the very-nomagic setting for the
delimiter, so escaping is not neccessary.

If you want to override which delimiters are probed automatically, set the
`g:csv_delim_test` variable like this:

```vim
:let g:csv_delim_test = ',;|'
```

This will only make the plugin test the possible delimiters ',', ';' and '|'.
This will also make the automatic detection a bit faster, since it does not
need to test that many delimiters.

## Column

The definition, of what a column is, is defined as buffer-local variable
b:col. By default this variable is initialized to:
```vim
let b:col='\%(\%([^' . b:delimiter . ']*"[^"]*"[^' . b:delimiter . ']*'
	\. b:delimiter . '\)\|\%([^' . b:delimiter . ']*\%(' . b:delimiter
	\. '\|$\)\)\)'
```

This should take care of quoted delimiters within a column. Those should
obviously not count as a delimiter. This regular expression is quite
complex and might not always work on some complex cases (e.g. linebreaks
within a field, see RFC4180 for some ugly cases that will probably not work
with this plugin).

If you changed the b:delimiter variable, you need to redefine the b:col
variable, cause otherwise it will not reflect the change. To change the
variable from the comma to a semicolon, you could call in your CSV-Buffer
this command:

```vim
:let b:col=substitute(b:col, ',', ';', 'g')
```

Check with :echo b:col, if the definition is correct afterwards.

You can also force the plugin to use your own defined regular expression as
column. That regular expression should include the delimiter for the columns.
To define your own regular expression, set the g:csv_col variable:

```vim
let g:csv_col='[^,]*,'
```

This defines a column as a field delimited by the comma (where no comma can be
contained inside a field), similar to how [Strict Columns](#strict-columns) works.

You should reinitialize the plugin afterwards [CSVInit](#csvinit)

## Highlighting Group

By default the csv ftplugin uses the WildMenu highlighting Group to define how
the [HiColumn](#hicolumn) command highlights columns. If you would like to define a
different highlighting group, you need to set this via the g:csv_hiGroup
variable. You can e.g. define it in your [`.vimrc`](http://vimhelp.appspot.com/starting.txt.html#.vimrc):

```vim
:let g:csv_hiGroup = "IncSearch"
```

You need to restart Vim, if you have changed this variable or use [CSVInit](#csvinit)

The [`hl-Title`](http://vimhelp.appspot.com/syntax.txt.html#hl-Title) highlighting is used for the Header line that is created by the
[Header Lines](#header-lines) command. If you prefer a different highlighting, set the
g:csv_hiHeader variable to the prefered highlighting:

```vim
let g:csv_hiHeader = 'Pmenu'
```

This would set the header window to the [`hl-Pmenu`](http://vimhelp.appspot.com/syntax.txt.html#hl-Pmenu) highlighting, that is used
for the popup menu. To disable the custom highlighting, simply [`:unlet`](http://vimhelp.appspot.com/eval.txt.html#%3Aunlet) the
variable:

```vim
unlet g:csv_hiHeader
```

You should reinitialize the plugin afterwards [CSVInit](#csvinit)

## Strict Columns

The default regular expression to define a column is quite complex
([Column](#column)). This slows down the processing and makes Vim use more memory
and it could still not fit to your specific use case.

If you know, that in your data file, the delimiter cannot be contained inside
the fields quoted or escaped, you can speed up processing (this is quite
noticeable when using the [ArrangeColumn](#arrangecolumn) command) by setting the
g:csv_strict_columns variable:

```vim
let g:csv_strict_columns = 1
```

This would define a column as this regex:

```vim
let b:col = '\%([^' . b:delimiter . ']*' . b:delimiter . '\`$\)'
```

Much simpler then the default column definition, isn't it?
See also [Column](#column) and [Delimiter](#delimiter)

You can disable the effect if you [`:unlet`](http://vimhelp.appspot.com/eval.txt.html#%3Aunlet) the variable:

```vim
unlet g:csv_strict_columns
```

You should reinitialize the plugin afterwards [CSVInit](#csvinit)

For example when opening a CSV file you get the Error [`E363`](http://vimhelp.appspot.com/options.txt.html#E363): pattern uses
more memory than [`'maxmempattern'`](http://vimhelp.appspot.com/options.txt.html#%27maxmempattern%27). In this case, either increase the
[`'maxmempattern'`](http://vimhelp.appspot.com/options.txt.html#%27maxmempattern%27) or set the g:csv_strict_columns variable.


## Concealing

The CSV plugin comes with a function to syntax highlight csv files. Basically
all it does is highlight the columns and the header line.

By default, the delimiter will not be displayed, if Vim supports [`conceal`](http://vimhelp.appspot.com/syntax.txt.html#conceal) of
syntax items and instead draws a vertical line. If you don't want that, simply
set the g:csv_noconceal variable in your .vimrc

```vim
let g:csv_no_conceal = 1
```

and to disable it, simply unlet the variable

```vim
unlet g:csv_no_conceal
```

You should reinitialize the plugin afterwards [CSVInit](#csvinit)
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
own syntax highlighting like this in your [`.vimrc`](http://vimhelp.appspot.com/starting.txt.html#.vimrc)

```vim
hi CSVColumnEven term=bold ctermbg=4 guibg=DarkBlue
hi CSVColumnOdd  term=bold ctermbg=5 guibg=DarkMagenta
hi CSVColumnHeaderEven ...
hi CSVColumnHeaderOdd ...
```

Alternatively, you can simply link those highlighting groups to some other
ones, you really like:

```vim
hi link CSVColumnOdd MoreMsg
hi link CSVColumnEven Question
```
If you do not want column highlighting, set the variable
g:csv_no_column_highlight to 1

```vim
:let g:csv_no_column_highlight = 1
```
Note, these changes won't take effect, until you restart Vim.


## Newlines

RFC4180 allows newlines in double quoted strings. By default, the csv-plugin
won't recognize newlines inside fields. It is however possible to make the
plugin aware of newlines within quoted strings. To enable this, set

```vim
let g:csv_nl = 1
```

and to disable it again, simply unset the variable

```vim
unlet g:csv_nl
```

It is a good idea to reinitialize the plugin afterwards [CSVInit](#csvinit)

Note, this might not work correctly in all cases. The syntax highlighting
seems to change on cursor movements. This could possibly be a bug in the
syntax highlighting engine of Vim. Also, [WhatColumn](#whatcolumn) can't handle
newlines inside fields and will most certainly be wrong.

## Highlight column automatically

You can let vim automatically highlight the column on which the cursor is.
This works by defining an [`CursorMoved`](http://vimhelp.appspot.com/autocmd.txt.html#CursorMoved) autocommand to always highlight the
column, when the cursor is moved in normal mode. Note, this does not update
the highlighting, if the Cursor is moved in Insert mode. To enable this,
define the g:csv_highlight_column variable like this

```vim
let g:csv_highlight_column = 'y'
```

and to disable it again, simply unset the variable

```vim
unlet g:csv_highlight_column
```

It is a good idea to reinitialize the plugin afterwards [CSVInit](#csvinit)

## Fixed width columns

Sometimes there are no real columns, but rather the file is fixed width with
no distinct delimiters between each column. The CSV plugin allows you to
handle such virtual columns like csv columns, if you define where each column
starts.

Note: Except for [ArrangeColumn](#arrangecolumn) and the [Header Lines](#header-lines) commands, all
commands work in either mode. Those two commands won't do anything in the case
of fixedwidth columns, since they don't really make sense here.

### Manual setup

You can do this, by setting the buffer-local variable
b:csv_fixed_width like this

```vim
let b:csv_fixed_width="1,5,9,13,17,21"
```

This defines that each column starts at multiples of 4. Be sure, to issue
this command in the buffer, that contains your file, otherwise, it won't
have an effect, since this is a buffer-local option ([`local-options`](http://vimhelp.appspot.com/options.txt.html#local-options))

After setting this variable, you should reinitialize the plugins using
[CSVInit](#csvinit)

### Setup using a Wizard

Alternatively, you can setup the fixed width columns using the :CSVFixed
command. This provides a simple wizard to select each column. If you enter
the command:

```vim
:CSVFixed
```
The first column will be highlighted and Vim outputs:
`<Cursor>`, `<Space>`, `<ESC>`, `<BS>`, `<CR>`
This means, you can now use those 5 keys to configure the fixed-width columns:

Key | Effect
--- | ---
`<Cursor>` | Use Cursor Left (`<Left>`) and Cursor Right (`<Right>`) to move the highlighting bar.
`<Space>` | If you press `<Space>`, this column will be fixed and remain highlighted and there will be another bar, you can move using the Cursor keys. This means this column will be considered to be the border between 2 fixed with columns.
`<ESC>` | Abort
`<BS>` | Press the backspace key, to remove the last column you fixed with the `<Space>` key.
`<CR>` | Use Enter to finish the wizard. This will use all fixed columns to define the fixed width columns of your csv file. The plugin will be initialized and syntax highlighting should appear.

Note: This only works, if your Vim has the 'colorcolumn' option available
(This won't work with Vim < 7.3 and also not with a Vim without +syntax
feature).

## CSV Header lines

By default, dynamic filtering [Dynamic filters](#dynamic-filters) will not fold away the first line.
If you don't like that, you can define your header line using the variable
b:csv_fold_headerline, e.g.

```vim
let b:csv_headerline = 0
```

to disable, that a header line won't be folded away. If your header line
instead is on line 5, simply set this variable to 5. This also applies to the
[Header Lines](#header-lines) command.

## Number format

By default, Vim uses the a numerical format that uses the '.' as decimal
separator while there is no thousands separator. If youre file contains
the numbers in a different format, you can use the /format/ option to specify
a different thousands separator or a different decimal separator. The format
needs to be specified like this:

```
/x:y/
```
where 'x' defines the thousands separator and y defines the decimal
separator and each one is optional. This means, that

```vim
:SumCol 1 /:,/
```

uses the default thousands separator and ',' as the decimal separator and

```vim
:SumCol 2 / :./
```

uses the Space as thousands separator and the '.' as decimal separator.

You can however also configure the plugin to detect a different number format
than the default number format (which does not support a thousands separator
and uses the '.' as decimal separator).

To specify a different thousands separator by default, use

```vim
let b:csv_thousands_sep = ' '
```
to have the space use as thousands separator and

```vim
let b:csv_decimal_sep = ','
```
to use the comma as decimal separator.

## Move folded lines

If you use dynamic filters (see [Dynamic filters](#dynamic-filters)), you can configure the plugin to
move all folded lines to the end of the file. This only happens if you set the
variable

```vim
let g:csv_move_folds = 1
```
and the file is modifiable. This let's you see all non-folded records as a
consecutive area without being disrupted by folded lines.

## Using comments

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
your own comment string, put this in your [`.vimrc`](http://vimhelp.appspot.com/starting.txt.html#.vimrc)

```vim
:let g:csv_comment = '#'
```
Which will use the '#' sign as comment leader like in many scripting
languages.

After setting this variable, you should reinitialize the plugins using
[CSVInit](#csvinit)

By default, the csv plugin sets the 'foldtext' option. If you don't want this,
set the variable `g:csv_disable_fdt` in your [`.vimrc`](http://vimhelp.appspot.com/starting.txt.html#.vimrc)

```vim
:let g:csv_disable_fdt = 1
```

## Size and performance considerations

By default, the csv plugin will analyze the whole file to determine which
delimiter to use. Beside specifying the the actual delimiter to use
(see also [Delimiter](#delimiter)) you can restrict analyzing the plugin to consider only a
certain part of the file. This should make loading huge csv files a lot
faster. To only consider the first 100 rows set the `g:csv_start` and
`g:csv_end` variables in your [`.vimrc`](http://vimhelp.appspot.com/starting.txt.html#.vimrc) like this

```vim
:let g:csv_start = 1
:let g:csv_end = 100
```

Also note, you can use the [Large File
plugin](http://www.drchip.org/astronaut/vim/index.html#LARGEFILE) which however
will disable syntax highlighting and the filetype commands for very large csv
files (by default larger than 100 MB).

See also [Slow CSV plugin](#slow-csv-plugin)

## Map `B` instead of `E` to jump back to previous column

Mapping E to go back a cell has no logic ; this feature lets the user choose
to map B instead with the `g:csv_bind_B` variable (boolean) defined anywhere
in his vim configuration. If it is not set, falls back to mapping E to
previous column. Added by @lapingenieur ([lapingenieur over github](https://github.com/lapingenieur),
email: lapingenieur@gmail.com).

Exemple : I want to remap `B` to go to the previous column (comma) instead of `E`.
Just put this in your counfig file :

```vim
    let g:csv_bind_B = 1
```

If you don't want this feature, you can just leave this variable without
defining it : the script will automatically map `E`.

# Functions

The csv plugins also defines some functions, that can be used for scripting
when a csv file is open

## CSVPat()

```
CSVPat({column}[, {pattern}])
```

This function returns the pattern for the selected column. If only columns is
given, returns the regular expression used to search for the pattern `.*` in
that column (which means the content of that column). Alternatively, an
optional pattern can be given, so the return string can be directly feeded to
the [`/`](http://vimhelp.appspot.com/pattern.txt.html#%2F) or [`:s`](http://vimhelp.appspot.com/change.txt.html#%3As) command, e.g. type:

```vim
:s/<C-R>=CSVPat(3, 'foobar')<cr>/baz
```

where the `<C-R>` means pressing Control followed by R followed by =
(see [`c_CTRL-R_=`](http://vimhelp.appspot.com/cmdline.txt.html#c_CTRL-R_%3D)). A prompt will apear, with the '=' as the first character
on which you can enter expressions.

In this case enter CSVPat(3, 'foobar') which returns the pattern to search for
the string 'foobar' in the third column. After you press enter, the returned
pattern will be put after the :s command so you can directly enter / and the
substitute string.

## CSVField(x,y[, orig])

This function returns the field at index (x,y) (starting from 1). If the
parameter orig is given, returns the column "as is" (e.g. including delimiter
and leading and trailing whitespace, otherwise that will be stripped.)

## CSVCol([name])

If the name parameter is given, returns the name of the column, else returns
the index of the current column, starting at 1.

## CSVSum(col, fmt, startline, endline)

Returns the sum for column col. Uses fmt to parse number format (see
[Sum of Numbers in a row](#sum-of-numbers-in-a-row)) startline and endline specify the lines to consider, if empty,
will be first and last line.

## CSVCount(col, fmt, startline, endline[, distinct])

Returns the count of values for column col. If the optional parameter
[distinct] is given, only returns the distinct number of values.

## CSVMax(col, fmt, startline, endline)

Returns the 10 largest values for column col.

## CSVMin(col, fmt, startline, endline)

Returns the 10 smallest values for column col.

## CSVAvg(col, fmt, startline, endline)

Returns the average value for column col.

## CSVWidth()

Returns a list with the width of each column.

# CSV Tips and Tricks

Here, there you'll find some small tips and tricks that might help when
working with CSV files.

## Statusline

Suppose you want to include the column, on which the cursor is, into your
statusline. You can do this, by defining in your .vimrc the 'statusline' like
this:

```vim
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
```

This will draw in your statusline right aligned the current column and max
column (like 1/10), if you are inside a CSV file. The column info will be
drawn using the User1 highlighting ([`hl-User1`](http://vimhelp.appspot.com/syntax.txt.html#hl-User1)), that has been defined in the
second line of the function. In the third line of your function, put your
desired 'statusline' settings as [`expression`](http://vimhelp.appspot.com/eval.txt.html#expression). Note the section starting with
'if exists(..)' guards against not having loaded the filetype plugin.

Note: [vim-airline](https://github.com/vim-airline/vim-airline) by default supports
the csv plugin and enables a nice little csv statusline which helps for
navigating within a csv file. For details, see the Vim-Airline documentation.

The CSV_WCol() function controls, what will be output. In the simplest case,
when no argument is given, it simply returns on which column the cursor is.
This would look like '1/10' which means the cursor is on the first of 10
columns. If you rather like to know the name of the column, simply give as
parameter to the function the string "Name". This will return the column name
as it is printed on the first line of that column. This can be adjusted, to
have the column name printed into the statusline (see `csv-stl` above) by
replacing the line

```vim
let csv = '%1*%{&ft=~"csv" ? CSV_WCol() : ""}%*'
```
by e.g.

```vim
let csv = '%1*%{&ft=~"csv" ? CSV_WCol("Name") . " " . CSV_WCol() : ""}%*'
```

which will output "Name 2/10" if the cursor is in the second column
which is named "Name".

## Slow CSV plugin

Processing a csv file using [ArrangeColumn](#arrangecolumn) can be quite slow, because Vim
needs to calculate the width for each column and then replace each column by
itself widened by spaces to the optimal length. Unfortunately, csv files tend
to be quite big. Remember, for a file with 10,000 lines and 50 columns Vim
needs to process each cell, which accumulates to 500,000 substitutions. It
might take some time, until Vim is finished.

You can speed up things a little bit, if you omit the '!' attribute to the
`ArrangeColumn` (but this will only work, if the width has been calculated
before, e.g. by issuing a :1ArrangeColumn command to arrange only the first
line. Additionally you can also configure how this command behaves by setting
some configuration variables.

Also note, using dynamic filters ([Dynamic filters](#dynamic-filters)), can slow down Vim
considerably, since they internally work with complex regular expressions, and
if you have a large file, containing many columns, you might hit a performance
penalty (especially, if you want to filter many columns). It's best to avoid
those functions if you are using a large csv file (so using strict columns
[Strict Columns](#strict-columns) might help a little and also setting 're' to 1 might also
alleviate it a little).

## Defining custom aggregate functions

The CSV plugin already defines the [Sum of Numbers in a row](#sum-of-numbers-in-a-row) command, to let you calculate
the sum of all values of a certain column within a given range. This will
consider all values within the range, that are not folded away ([Dynamic filters](#dynamic-filters)),
and also skip comments and the header lines. The delimiter will be deleted
from each field.

But it may be, that you don't need the sum, but would rather want to have the
average of all values within a certain column. You can define your own
function and let the plugin call it for a column like this:

1. You define your own custom function in the after directory of your
   vim runtime path [`after-directory`](http://vimhelp.appspot.com/options.txt.html#after-directory) (see also #2 below)
	```vim
	fun! My_CSV_Average(col)
		let sum=0
		for item in a:col
		let sum+=item
		endfor
		return sum/len(a:col)
	endfun
	```
   This function takes a list as argument, and calculates the average for
   all items in the list. You could also make use of Vim's [`eval()`](http://vimhelp.appspot.com/eval.txt.html#eval%28%29)
   function and write your own Product function like this

	```vim
	fun! My_CSV_Product(col)
		return eval(join(a:col, '*'))
	endfun
	```

2. Now define your own custom command, that calls your custom function for
a certain column
	```vim
	command! -buffer -nargs=? -range=% AvgCol
	\ :echo csv#EvalColumn(<q-args>,
	\ "My_CSV_Average", <line1>,<line2>)
	```
	This command should best be put into a file called csv.vim and save
	it into your ~/.vim/after/ftplugin/ directory. Create directories
	that don't exist yet. For Windows, this would be the
	$VIMRUNTIME/vimfiles/after/ftplugin directory.

3. Make sure, your [`.vimrc`](http://vimhelp.appspot.com/starting.txt.html#.vimrc) includes a filetype plugin setting like this
	```vim
	filetype plugin on
	```
   This should make sure, that all the necessary scripts are loaded by
   Vim.

After restarting Vim, you can now use your custom command definition
:AvgCol. Use a range, for the number of lines you want to evaluate and
optionally use an argument to specify which column you want to be
evaluated

```vim
:2,$AvgCol 7
```
This will evaluate the average of column seven (assuming, line 1 is the
header line, which should not be taken into account).

Note: this plugin already defines an average function.

## Autocommand on opening/closing files

If you want your CSV files to always be displayed like a table, you can
achieve this using the [ArrangeColumn](#arrangecolumn) command and some autocommands.
Define these autocommands in your [`.vimrc`](http://vimhelp.appspot.com/starting.txt.html#.vimrc)

```vim
aug CSV_Editing
		au!
		au BufRead,BufWritePost *.csv :%ArrangeColumn
		au BufWritePre *.csv :%UnArrangeColumn
aug end
```

Upon Entering a csv file, Vim will visually arrange all columns and before
writing, those columns will be collapsed again. The BufWritePost autocommand
makes sure, that after the file has been written successfully, the csv file
will again be visually arranged.

You can also simply set the variable

```vim
let g:csv_autocmd_arrange = 1
```
in your vimrc and an autocmd will be installed, that visually arranges your
csv file whenever you open them for editing. Alternatively, you can restrict
this setting to files below a certain size. For example, if you only want to
enable this feature for files smaller than 1 MB, put this into your [`.vimrc`](http://vimhelp.appspot.com/starting.txt.html#.vimrc)

```vim
let g:csv_autocmd_arrange	   = 1
let g:csv_autocmd_arrange_size = 1024*1024
```

Note, this is highly experimental and especially on big files, this might
slow down Vim considerably.

## Syntax error when opening a CSV file

If you see this error:

```vim
CSV Syntax:Invalid column pattern, using default pattern \%([^,]*,\|$\)
```
This happens usually, when the syntax script is read before the filetype
plugin, so the plugin did not have a chance to setup the column delimiter
correctly.

The easy way to fix it, is to make sure the :syntax on ([`:syn-on`](http://vimhelp.appspot.com/syntax.txt.html#%3Asyn-on)) statement
comes after the :filetype plugin ([`:filetype-plugin-on`](http://vimhelp.appspot.com/filetype.txt.html#%3Afiletype-plugin-on)) statement in your
[`.vimrc`](http://vimhelp.appspot.com/starting.txt.html#.vimrc)

Alternatively, you can simply call [CSVInit](#csvinit) and ignore the error.

Note: It could also be caused by lazy loading feature by a vim plugin
manager. For example this line might also cause it:

```vim
  Plug 'https://github.com/chrisbra/csv.vim',  { 'for' : 'csv' }
```
The fix would then be:
```vim
  Plug 'https://github.com/chrisbra/csv.vim'
```

## Calculate new columns

Suppose you have a table like this:

Index | Value | Value2
--- | --- | ---
1 | 100 | 3
2 | 20 | 4

And you need one more column, that is the calculated product of column 2 and
3, you can make use of the provided [CSVField()](#csvfieldxy-orig) function using a
[`sub-replace-expression`](http://vimhelp.appspot.com/change.txt.html#sub-replace-expression)
of an [`:s`](http://vimhelp.appspot.com/change.txt.html#%3As) command. In this case, you would do this:

```vim
:2,3s/$/\=printf("%s%.2f", b:delimiter,
	(CSVField(2,line('.'))+0.0)*(CSVField(3,line('.'))+0.0/
```

Note: Enter as single line. The result will be this:

Index | Value | Value2
--- | --- | ---
1 | 100 | 3 | 300.00
2 | 20 | 4 | 80.00

## Use the result of an evaluation in insert mode

The result of the last evaluation like e.g. `:SumCol` will be available in
the buffer-local variable `b:csv_result`. This allows to easily enter the
result in a new new cell while in insert mode, using `i_CTRL-R` (e.g. in insert
mode press Ctrl-R followed by "=b:csv_result".

You can also easily copy and paste it into e.g. the system clipboard using

```vim
  :let @+=b:csv_result
```

[1]: https://github.com/tpope/vim-pathogen
[2]: https://github.com/Shougo/neobundle.vim
[3]: https://github.com/VundleVim/Vundle.vim
[4]: https://github.com/MarcWeber/vim-addon-manager
[5]: https://github.com/junegunn/vim-plug
[6]: https://github.com/Shougo/dein.vim
[7]: https://github.com/k-takata/minpac/

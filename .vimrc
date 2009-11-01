set ruler
set incsearch
set nu
set ai
set autoread
set paste

set nocompatible 	" We're running Vim, not Vi!
syntax on 				" syntax
filetype on 			" Enable filetype detection
filetype indent on " Enable filetype-specific indenting
filetype plugin on " Enable filetype-specific plugins
compiler ruby 		" Enable compiler support for ruby

"set encoding=ISO-8859-15
set encoding=Unicode
"set enc=Unicode
"set tenc=Unicode

" vimspell
noremap <F8> :so `vimspell.sh %`<CR><CR>
noremap <F7> :syntax clear SpellErrors<CR>

highlight Comment       ctermfg=DarkGreen
highlight Constant      ctermfg=DarkMagenta
highlight Character     ctermfg=DarkRed
highlight Special       ctermfg=DarkBlue
highlight Identifier    ctermfg=DarkCyan
highlight Statement     ctermfg=DarkBlue
highlight PreProc       ctermfg=DarkBlue
highlight Type          ctermfg=DarkBlue
highlight Number        ctermfg=DarkRed
highlight Delimiter     ctermfg=Red
highlight Error         ctermfg=Black
highlight Todo          ctermfg=Red ctermbg=Black
"highlight FIXME		ctermfg=Red ctermbg=Black
highlight WarningMsg    term=NONE           ctermfg=DarkBlue ctermbg=NONE   
highlight ErrorMsg      term=NONE           ctermfg=DarkRed ctermbg=NONE 

" misc
set tw=72
"set tw=80
"set tw=180
"set tabstop=8
set tabstop=2

"set lisp
"set showmatch
"set autoindent
"set smartindent
"autocmd BufRead *.tex set tw=72

" aliasses
"map ,dt :r!date <CR>
"map ,ide :w<CR>:!ispell %<CR>:e<CR>
"map ,ien :w<CR>:!ispell -d american %<CR>:e<CR>

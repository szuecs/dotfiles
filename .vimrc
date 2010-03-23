" We're running Vim, not Vi!
set nocompatible
" Display line numbers on the left
set number

set ruler
set incsearch
set ai
set autoread
set paste
"set cursorline
set shell=/bin/zsh

syntax on           " syntax
filetype on         " Enable filetype detection
filetype indent on  " Enable filetype-specific indenting
filetype plugin on  " Enable filetype-specific plugins

" One of the most important options to activate. Allows you to switch from an
" unsaved buffer without saving it first. Also allows you to keep an undo
" history for multiple files. Vim will complain if you try to quit without
" saving, and swap files will keep you safe if your computer crashes.
set hidden

" Better command-line completion
set wildmenu

" Show partial commands in the last line of the screen
set showcmd

" Highlight searches (use <C-L> to temporarily turn off highlighting; see the
" mapping of <C-L> below)
set hlsearch

" Allow backspacing over autoindent, line breaks and start of insert action
set backspace=indent,eol,start

" When opening a new line and no filetype-specific indenting is enabled, keep
" the same indent as the line you're currently on. Useful for READMEs, etc.
set autoindent

" Stop certain movements from always going to the first character of a line.
" While this behaviour deviates from that of Vi, it does what most users
" coming from other editors would expect.
set nostartofline

" Always display the status line, even if only one window is displayed
set laststatus=2

" Use visual bell instead of beeping when doing something wrong
set visualbell

" Enable use of the mouse for all modes
set mouse=a

" Set the command window height to 2 lines, to avoid many cases of having to
" "press <Enter> to continue"
set cmdheight=2

" Quickly time out on keycodes, but never time out on mappings
set notimeout ttimeout ttimeoutlen=200


compiler ruby 		" Enable compiler support for ruby

"encodings: 
" latin1 Unicode utf-8
"set fileencodings=utf-8,big5,gbk,sjis,euc-jp,euc-kr,utf-bom,iso8859-1
"set fencs=utf-8,big5,euc-jp,utf-bom,iso8859-1,utf-16le
set enc=utf-8
set fenc=utf-8
set tenc=utf-8

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

"------------------------------------------------------------
" Indentation options {{{1
"
" Indentation settings according to personal preference.

" Indentation settings for using 2 spaces instead of tabs.
" Do not change 'tabstop' from its default value of 8 with this setup.
set shiftwidth=2
set softtabstop=2
set expandtab

" Indentation settings for using hard tabs for indent. Display tabs as
" two characters wide.
"set shiftwidth=2
"set tabstop=2

"------------------------------------------------------------

" Mappings {{{1
"
" Useful mappings

" Map Y to act like D and C, i.e. to yank until EOL, rather than act as yy,
" which is the default
map Y y$

" Map <C-L> (redraw screen) to also turn off search highlighting until the
" next search
nnoremap <C-L> :nohl<CR><C-L>

" faster scrolling (4 times instead of 1 time)
nnoremap <C-E> <C-E><C-E><C-E><C-E>
nnoremap <C-Y> <C-Y><C-Y><C-Y><C-Y>

"------------------------------------------------------------
" spellchecker
"
" enable spellchecker
":setlocal spell spelllang=en_us
" 
" vimspell plugin - must be installed 
"noremap <F7> :syntax clear SpellErrors<CR>
"noremap <F8> :so `vimspell.sh %`<CR><CR>

"------------------------------------------------------------


"set lisp
"set showmatch
"set autoindent
"set smartindent
"autocmd BufRead *.tex set tw=72

" aliasses
"map ,dt :r!date <CR>
"map ,ide :w<CR>:!ispell %<CR>:e<CR>
"map ,ien :w<CR>:!ispell -d american %<CR>:e<CR>

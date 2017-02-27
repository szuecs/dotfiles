" We're running Vim, not Vi! This must be first, because of side effects
set nocompatible

" pathogen bundle manager
" https://github.com/tpope/vim-pathogen
"call pathogen#infect()
"execute pathogen#infect('bundle/{}')

" Vundle bundle manager {{{1
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" Vundle Plugins
" completion plugins {{{
Plugin 'Shougo/neocomplete'
if has("lua")
	let g:neocomplete#enable_at_startup = 1
	" Disable AutoComplPop.
	let g:acp_enableAtStartup = 0
	" Use smartcase.
	let g:neocomplete#enable_smart_case = 1
	" Set minimum syntax keyword length.
	let g:neocomplete#sources#syntax#min_keyword_length = 3

	" Define dictionary.
	let g:neocomplete#sources#dictionary#dictionaries = {
	    \ 'default' : '',
	    \ 'vimshell' : $HOME.'/.vimshell_hist',
	    \ 'scheme' : $HOME.'/.gosh_completions'
	        \ }

	" Define keyword.
	if !exists('g:neocomplete#keyword_patterns')
	    let g:neocomplete#keyword_patterns = {}
	endif
	let g:neocomplete#keyword_patterns['default'] = '\h\w*'

	" Plugin key-mappings.
	inoremap <expr><C-g>     neocomplete#undo_completion()
	inoremap <expr><C-l>     neocomplete#complete_common_string()

	" Recommended key-mappings.
	" <CR>: close popup and save indent.
	inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
	function! s:my_cr_function()
	  return (pumvisible() ? "\<C-y>" : "" ) . "\<CR>"
	  " For no inserting <CR> key.
	  "return pumvisible() ? "\<C-y>" : "\<CR>"
	endfunction
	" <TAB>: completion.
	inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
	" <C-h>, <BS>: close popup and delete backword char.
	inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
	inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
	" Close popup by <Space>.
	"inoremap <expr><Space> pumvisible() ? "\<C-y>" : "\<Space>"
	
	" AutoComplPop like behavior.
	"let g:neocomplete#enable_auto_select = 1
	
	" Shell like behavior(not recommended).
	"set completeopt+=longest
	"let g:neocomplete#enable_auto_select = 1
	"let g:neocomplete#disable_auto_complete = 1
	"inoremap <expr><TAB>  pumvisible() ? "\<Down>" : "\<C-x>\<C-u>"
	
	" Enable omni completion.
	autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
	autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
	autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
	autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
	autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
	
	" Enable heavy omni completion.
	if !exists('g:neocomplete#sources#omni#input_patterns')
	  let g:neocomplete#sources#omni#input_patterns = {}
	endif
	"let g:neocomplete#sources#omni#input_patterns.php = '[^. \t]->\h\w*\|\h\w*::'
	"let g:neocomplete#sources#omni#input_patterns.c = '[^.[:digit:] *\t]\%(\.\|->\)'
	"let g:neocomplete#sources#omni#input_patterns.cpp = '[^.[:digit:] *\t]\%(\.\|->\)\|\h\w*::'
	
	" For perlomni.vim setting.
	" https://github.com/c9s/perlomni.vim
	let g:neocomplete#sources#omni#input_patterns.perl = '\h\w*->\h\w*\|\h\w*::'

endif
"------------------------------------------------------------
" snippets
Plugin 'Shougo/neosnippet'
Plugin 'Shougo/neosnippet-snippets'
" vim-go
Plugin 'fatih/vim-go'

"------------------------------------------------------------
" All of your Plugins must be added before the following line
call vundle#end()            " required
"------------------------------------------------------------

" Basic {{{1
set number
set ruler
set incsearch     " incremenatal search
set ai
set autoread
"set paste
set history=50    " keep 50 lines of command line history
set showcmd       " display incomplete commands
"set cursorline

" prevent vim from adding that stupid empty line at the end of every file
set noeol
set binary

syntax on           " syntax
compiler ruby       " Enable compiler support for ruby

" One of the most important options to activate. Allows you to switch from an
" unsaved buffer without saving it first. Also allows you to keep an undo
" history for multiple files. Vim will complain if you try to quit without
" saving, and swap files will keep you safe if your computer crashes.
set hidden

" case insensitive search and substitution
"set ignorecase

" enable folding open: zo close: zc
set foldmethod=marker

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

" Set the command window height to 2 lines, to avoid many cases of having
" to press <Enter> to continue
set cmdheight=2

" Quickly time out on keycodes, but never time out on mappings
set notimeout ttimeout ttimeoutlen=200

" toggle paste
set pastetoggle=<F2>

"------------------------------------------------------------
"
" Autocommands {{{1
"
if has("autocmd")
  " Enable filetype detection
  filetype plugin indent on

  " Restore cursor position
  autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif

  "remove trailing whitespaces"
  autocmd BufWritePre *{Makefile,go,org,rc,tmpl,py,rb,java,c,h,cpp,js,json,yaml,plist,r,pl,pp,el,xml,cfg,lisp,hs,rc,conf,sh,zsh,bash} :%s/\s\+$//e
endif

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

" faster scrolling (5 times instead of 1 time)
nnoremap <C-E> <C-E><C-E><C-E><C-E><C-E>
nnoremap <C-Y> <C-Y><C-Y><C-Y><C-Y><C-Y>

"" map <leader> key to ,
let mapleader=','
" edit mappings from http://vimcasts.org/episodes/the-edit-command/
" auto complete the path to your currently open file
" ,ew -> edit mode
" ,es -> split mode
" ,ev -> vertical split mode
" ,et -> tab
map <leader>ew :e <C-R>=expand("%:p:h") . "/" <CR>
map <leader>es :sp <C-R>=expand("%:p:h") . "/" <CR>
map <leader>ev :vsp <C-R>=expand("%:p:h") . "/" <CR>
map <leader>et :tabe <C-R>=expand("%:p:h") . "/" <CR>

"" cursor movement within long wrapped lines with CTRL-j and CTRL-k
vmap <C-j> gj
vmap <C-k> gk
nmap <C-j> gj
nmap <C-k> gk

" Plugins {{{1
" tagbar {{{2
"nmap <F8> :TagbarToggle<CR>
"------------------------------------------------------------
" NerdTree.vim {{{2
map <S-f> :NERDTreeToggle<CR>
"------------------------------------------------------------
" NerdCommenter.vim {{{2
""if has("gui_macvim")
""  macmenu &File.New\ Tab key=<nop>
""  map <D-t> :CommandT<CR> 
""else
""  map <S-t> :CommandT<CR>
""endif
"------------------------------------------------------------
" Encodings {{{1
" latin1 Unicode utf-8
"set fileencodings=utf-8,big5,gbk,sjis,euc-jp,euc-kr,utf-bom,iso8859-1
"set fencs=utf-8,big5,euc-jp,utf-bom,iso8859-1,utf-16le
set enc=utf-8
set fenc=utf-8
set tenc=utf-8

"------------------------------------------------------------
" Highlight  {{{1
" highlight colors for white bg
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
highlight FIXME	        ctermfg=Red ctermbg=Black
highlight WarningMsg    term=NONE   ctermfg=DarkBlue ctermbg=NONE
highlight ErrorMsg      term=NONE   ctermfg=DarkRed  ctermbg=NONE

" invisible character colors
highlight NonText ctermfg=gray
highlight SpecialKey ctermfg=gray

" ruby colors
highlight link rubyClass Keyword
highlight link rubyDefine Keyword
highlight link rubyConstant Type
highlight link rubySymbol Character
highlight link rubyStringDelimiter rubyString
highlight link rubyInclude Keyword
highlight link rubyAttribute Keyword
highlight link rubyInstanceVariable Keyword

" show trailing whitespaces as Todo highlight
match Todo /\s\+$/

"------------------------------------------------------------
" MISC {{{1
set tw=72
" Use visual bell instead of beeping when doing something wrong
set visualbell
" Enable use of the mouse for all modes
set mouse=a
" Use the same symbols as TextMate for tabstops and EOLs
set listchars=tab:▸\ ,eol:¬
" list invisible chars
set list

"------------------------------------------------------------
" Indentation options {{{1
"
" Indentation settings according to personal preference.

" Indentation settings for using 2 spaces instead of tabs.
" Do not change 'tabstop' from its default value of 8 with this setup.
"set shiftwidth=2
"set softtabstop=2
"set expandtab

" Indentation settings for using hard tabs for indent. Display tabs as
" two characters wide.
"set shiftwidth=2
"set tabstop=2

"------------------------------------------------------------
" Wrap {{{1
"" adds a :Wrap command to set the 3 options at once
command! -nargs=* Wrap set wrap linebreak nolist

"------------------------------------------------------------
" Tab completion {{{1
" will insert tab at beginning of line,
" will use completion if not at beginning
"set wildmode=list:longest,list:full
"function! InsertTabWrapper()
"    let col = col('.') - 1
"    if !col || getline('.')[col - 1] !~ '\k'
"        return "\<tab>"
"    else
"        return "\<c-p>"
"    endif
"endfunction
"inoremap <Tab> <c-r>=InsertTabWrapper()<cr>
"inoremap <S-Tab> <c-n>

"------------------------------------------------------------
" NeoComplete - Tab completion {{{1
" Plugin key-mappings.
" Note: It must be "imap" and "smap".  It uses <Plug> mappings.
imap <C-k>     <Plug>(neosnippet_expand_or_jump)
smap <C-k>     <Plug>(neosnippet_expand_or_jump)
xmap <C-k>     <Plug>(neosnippet_expand_target)

" SuperTab like snippets behavior.
" Note: It must be "imap" and "smap".  It uses <Plug> mappings.
imap <C-k>     <Plug>(neosnippet_expand_or_jump)
"imap <expr><TAB>
" \ pumvisible() ? "\<C-n>" :
" \ neosnippet#expandable_or_jumpable() ?
" \    "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"
smap <expr><TAB> neosnippet#expandable_or_jumpable() ?
\ "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"

" For conceal markers.
if has('conceal')
  set conceallevel=2 concealcursor=niv
endif

"------------------------------------------------------------

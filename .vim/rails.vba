" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
plugin/rails.vim
3568
" rails.vim - Detect a rails application
" Author:       Tim Pope <vimNOSPAM@tpope.info>
" GetLatestVimScripts: 1567 1 :AutoInstall: rails.vim
" URL:          http://svn.tpope.net/rails/vim/railsvim
" $Id: rails.vim 128 2006-08-17 03:26:00Z tpope $

" See doc/rails.txt for details. Grab it from the URL above if you don't have it
" To access it from Vim, see :help add-local-help (hint: :helptags ~/.vim/doc)
" Afterwards, you should be able to do :help rails

" ============================================================================

" Exit quickly when:
" - this plugin was already loaded (or disabled)
" - when 'compatible' is set
if exists("g:loaded_rails") && (g:loaded_rails && !g:rails_debug) || &cp
  finish
endif
let g:loaded_rails = 1

let s:cpo_save = &cpo
set cpo&vim

" Utility Functions {{{1

function! s:sub(str,pat,rep)
  return substitute(a:str,'\C'.a:pat,a:rep,'')
endfunction

function! s:gsub(str,pat,rep)
  return substitute(a:str,'\C'.a:pat,a:rep,'g')
endfunction

function! s:escpath(p)
  return s:gsub(a:p,'[ ,]','\\&')
endfunction

function! s:escarg(p)
  return s:gsub(a:p,'[ !%#]','\\&')
endfunction

function! s:esccmd(p)
  return s:gsub(a:p,'[!%#]','\\&')
endfunction

function! s:r()
  return RailsRoot()
endfunction

function! s:rp()
  " Rails root, escaped for use in &path
  return s:escpath(s:r())
endfunction

function! s:ra()
  " Rails root, escaped for use as single argument
  return s:escarg(s:r())
endfunction

function! s:rc()
  " Rails root, escaped for use with a command (spaces not escaped)
  return s:esccmd(s:r())
endfunction

function! s:escvar(r)
  let r = fnamemodify(a:r,':~')
  "let r = s:gsub(r,'^\~','0')
  let r = s:gsub(r,'\W','\="_".char2nr(submatch(0))."_"')
  let r = s:gsub(r,'^\d','_&')
  return r
endfunction

function! s:rv()
  " Rails root, escaped to be a variable name
  return s:escvar(RailsRoot())
endfunction

function! s:sname()
  return fnamemodify(s:file,':t:r')
endfunction

function! s:rquote(str)
  " Imperfect but adequate for Ruby arguments
  if a:str =~ '^[A-Za-z0-9_/.-]\+$'
    return a:str
  elseif &shell =~? 'cmd'
    return '"'.s:gsub(s:gsub(a:str,'\','\\'),'"','\\"').'"'
  else
    return "'".s:gsub(s:gsub(a:str,'\','\\'),"'","'\\\\''")."'"
  endif
endfunction

function! s:rubyexestr(cmd)
  if RailsRoot() =~ '://'
    return "ruby ".a:cmd
  else
    return "ruby -C ".s:rquote(RailsRoot())." ".a:cmd
  endif
endfunction

function! s:rubyexebg(cmd)
  if has("gui_win32")
    exe "!start ".s:esccmd(s:rubyexestr(a:cmd))
  elseif exists("$STY") && !has("gui_running") && s:getopt("gnu_screen","abg") && executable("screen")
    silent exe "!screen -ln -fn -t ".s:sub(a:cmd,'\s.*','').' '.s:esccmd(s:rubyexestr(a:cmd))
  else
    exe "!".s:esccmd(s:rubyexestr(a:cmd))
  endif
  return v:shell_error
endfunction

function! s:rubyexe(cmd,...)
  if a:0
    call s:rubyexebg(a:cmd)
  else
    exe "!".s:esccmd(s:rubyexestr(a:cmd))
  endif
  return v:shell_error
endfunction

function! s:rubyeval(ruby,...)
  if a:0 > 0
    let def = a:1
  else
    let def = ""
  endif
  if !executable("ruby")
    return def
  endif
  let cmd = s:rubyexestr('-e '.s:rquote('require %{rubygems} rescue nil; require %{active_support} rescue nil; '.a:ruby))
  "let g:rails_last_ruby_command = cmd
  " If the shell is messed up, this command could cause an error message
  silent! let results = system(cmd)
  "let g:rails_last_ruby_result = results
  if results =~ '-e:\d' || results =~ 'ruby:.*(fatal)'
    return def
  else
    return results
  endif
endfunction

function! s:endof(lnum)
  if a:lnum == 0
    return 0
  endif
  let cline = getline(a:lnum)
  let spc = matchstr(cline,'^\s*')
  let endpat = '\<end\>'
  if matchstr(getline(a:lnum+1),'^'.spc) && !matchstr(getline(a:lnum+1),'^'.spc.endpat) && matchstr(cline,endpat)
    return a:lnum
  endif
  let endl = a:lnum
  while endl <= line('$')
    let endl = endl + 1
    if getline(endl) =~ '^'.spc.endpat
      return endl
    elseif getline(endl) =~ '^=begin\>'
      while getline(endl) ~! '^=end\>' && endl <= line('$')
        let endl = endl + 1
      endwhile
      let endl = endl + 1
    elseif getline(endl) !~ '^'.spc && getline(endl) !~ '^\s*\%(#.*\)\=$'
      return 0
    endif
  endwhile
  return 0
endfunction

function! s:lastmethodline(...)
  if a:0
    let line = a:1
  else
    let line = line(".")
  endif
  while line > 0 && getline(line) !~ &l:define
    let line = line - 1
  endwhile
  let lend = s:endof(line)
  if lend >= line(".")
    return line
  else
    return 0
  endif
endfunction

function! s:lastmethod()
  let line = s:lastmethodline()
  if line
    return matchstr(getline(line),'\%('.&define.'\)\zs\k\%(\k\|[:.]\)*[?!=]\=')
  else
    return ""
  endif
endfunction

function! s:controller(...)
  let t = RailsFileType()
  let f = RailsFilePath()
  let o = s:getopt("controller","lb")
  if o != ""
    return o
  elseif f =~ '\<app/views/layouts/'
    return s:sub(f,'.*\<app/views/layouts/\(.\{-\}\)\.\k\+$','\1')
  elseif f =~ '\<app/views/'
    return s:sub(f,'.*\<app/views/\(.\{-\}\)/\k\+\.\k\+$','\1')
  elseif f =~ '\<app/helpers/.*_helper\.rb$'
    return s:sub(f,'.*\<app/helpers/\(.\{-\}\)_helper\.rb$','\1')
  elseif f =~ '\<app/controllers/.*_controller\.rb$'
    return s:sub(f,'.*\<app/controllers/\(.\{-\}\)_controller\.rb$','\1')
  elseif f =~ '\<app/apis/.*_api\.rb$'
    return s:sub(f,'.*\<app/apis/\(.\{-\}\)_api\.rb$','\1')
  elseif f =~ '\<test/functional/.*_controller_test\.rb$'
    return s:sub(f,'.*\<test/functional/\(.\{-\}\)_controller_test\.rb$','\1')
  elseif f =~ '\<components/.*_controller\.rb$'
    return s:sub(f,'.*\<components/\(.\{-\}\)_controller\.rb$','\1')
  elseif f =~ '\<components/.*\.\(rhtml\|rxml\|rjs\|mab\|liquid\)$'
    return s:sub(f,'.*\<components/\(.\{-\}\)/\k\+\.\k\+$','\1')
  elseif f =~ '\<app/models/.*\.rb$' && t =~ '^model-mailer\>'
    return s:sub(f,'.*\<app/models/\(.\{-\}\)\.rb$','\1')
  elseif a:0 && a:1
    return s:pluralize(s:model())
  endif
  return ""
endfunction

function! s:model(...)
  let f = RailsFilePath()
  let o = s:getopt("model","lb")
  if o != ""
    return o
  elseif f =~ '\<app/models/.*_observer.rb$'
    return s:sub(f,'.*\<app/models/\(.*\)_observer\.rb$','\1')
  elseif f =~ '\<app/models/.*\.rb$'
    return s:sub(f,'.*\<app/models/\(.*\)\.rb$','\1')
  elseif f =~ '\<test/unit/.*_observer_test\.rb$'
    return s:sub(f,'.*\<test/unit/\(.*\)_observer_test\.rb$','\1')
  elseif f =~ '\<test/unit/.*_test\.rb$'
    return s:sub(f,'.*\<test/unit/\(.*\)_test\.rb$','\1')
  elseif f =~ '\<test/fixtures/.*\.\w*\~\=$'
    return s:singularize(s:sub(f,'.*\<test/fixtures/\(.*\)\.\w*\~\=$','\1'))
  elseif a:0 && a:1
    return s:singularize(s:controller())
  endif
  return ""
endfunction

function! s:underscore(str)
  let str = s:gsub(a:str,'::','/')
  let str = s:gsub(str,'\(\u\+\)\(\u\l\)','\1_\2')
  let str = s:gsub(str,'\(\l\|\d\)\(\u\)','\1_\2')
  let str = s:gsub(str,'-','_')
  let str = tolower(str)
  return str
endfunction

function! s:singularize(word)
  " Probably not worth it to be as comprehensive as Rails but we can
  " still hit the common cases.
  let word = a:word
  if word =~? '\.js$' || word == ''
    return word
  endif
  let word = s:sub(word,'eople$','ersons')
  let word = s:sub(word,'[aeio]\@<!ies$','ys')
  let word = s:sub(word,'xe[ns]$','xs')
  let word = s:sub(word,'ves$','fs')
  let word = s:sub(word,'ss\%(es\)\=$','sss')
  let word = s:sub(word,'s$','')
  return word
endfunction

function! s:pluralize(word)
  let word = a:word
  if word == ''
    return word
  endif
  let word = s:sub(word,'[aeio]\@<!y$','ie')
  let word = s:sub(word,'[sx]$','&e')
  let word = s:sub(word,'f$','ve')
  let word = word."s"
  let word = s:sub(word,'ersons$','eople')
  return word
endfunction

function! s:usesubversion()
  if !exists("b:rails_use_subversion")
    let b:rails_use_subversion = s:getopt("subversion","abg") && (RailsRoot()!="") && isdirectory(RailsRoot()."/.svn")
  endif
  return b:rails_use_subversion
endfunction

function! s:environment()
  if exists('$RAILS_ENV')
    return $RAILS_ENV
  else
    return "development"
  endif
endfunction

function! s:environments(...)
  let e = s:getopt("environment","abg")
  if e == ''
    return "development\ntest\nproduction"
  else
    return s:gsub(e,'[:;,- ]',"\n")
  endif
endfunction

function! s:warn(str)
  echohl WarningMsg
  echomsg a:str
  echohl None
  " Sometimes required to flush output
  echo ""
  let v:warningmsg = a:str
endfunction

function! s:error(str)
  echohl ErrorMsg
  echomsg a:str
  echohl None
  let v:errmsg = a:str
endfunction

function! s:debug(str)
  if g:rails_debug
    echohl Debug
    echomsg a:str
    echohl None
  endif
endfunction

" }}}1
" "Public" Interface {{{1

" RailsRevision() and RailsRoot() the only official public functions

function! RailsRevision()
  return s:revision
endfunction

function! RailsRoot()
  if exists("b:rails_root")
    return b:rails_root
  else
    return ""
  endif
endfunction

function! RailsAppPath()
  " Deprecated
  call s:warn("RailsAppPath() is deprecated: use RailsRoot() instead.")
  return RailsRoot()
endfunction

function! RailsFilePath()
  if !exists("b:rails_root")
    return ""
  elseif exists("b:rails_file_path")
    return b:rails_file_path
  endif
  let f = s:gsub(expand("%:p"),'\\ \@!','/')
  if s:gsub(b:rails_root,'\\ \@!','/') == strpart(f,0,strlen(b:rails_root))
    return strpart(f,strlen(b:rails_root)+1)
  else
    return f
  endif
endfunction

function! RailsFile()
  return RailsFilePath()
endfunction

function! RailsFileType()
  if !exists("b:rails_root")
    return ""
  elseif exists("b:rails_type")
    return b:rails_type
  elseif exists("b:rails_file_type")
    return b:rails_file_type
  endif
  let f = RailsFilePath()
  let e = fnamemodify(RailsFilePath(),':e')
  let r = ""
  let top = getline(1)." ".getline(2)." ".getline(3)." ".getline(4)." ".getline(5).getline(6)." ".getline(7)." ".getline(8)." ".getline(9)." ".getline(10)
  if f == ""
    let r = f
  elseif f =~ '_controller\.rb$' || f =~ '\<app/controllers/application\.rb$'
    if top =~ '\<wsdl_service_name\>'
      let r = "controller-api"
    else
      let r = "controller"
    endif
  elseif f =~ '_api\.rb'
    let r = "api"
  elseif f =~ '\<test/test_helper\.rb$'
    let r = "test"
  elseif f =~ '_helper\.rb$'
    let r = "helper"
  elseif f =~ '\<app/models\>'
    let class = matchstr(top,'\<Acti\w\w\u\w\+\%(::\h\w*\)\+\>')
    if class != ''
      "let class = s:sub(class,'::Base$','')
      let class = tolower(s:gsub(class,'[^A-Z]',''))
      let r = "model-".s:sub(class,'^amb\>','mailer')
    elseif f =~ '_mailer\.rb$'
      let r = "model-mailer"
    elseif top =~ '\<\%(validates_\w\+_of\|set_\%(table_name\|primary_key\)\|has_one\|has_many\|belongs_to\)\>'
      let r = "model-arb"
    else
      let r = "model"
    endif
  elseif f =~ '\<app/views/layouts\>.*\.'
    let r = "view-layout-" . e
  elseif f =~ '\<\%(app/views\|components\)/.*/_\k\+\.\k\+$'
    let r = "view-partial-" . e
  elseif f =~ '\<app/views\>.*\.' || f =~ '\<components/.*/.*\.\(rhtml\|rxml\|rjs\|mab\|liquid\)'
    let r = "view-" . e
  elseif f =~ '\<test/unit/.*_test\.rb'
    let r = "test-unit"
  elseif f =~ '\<test/functional/.*_test\.rb'
    let r = "test-functional"
  elseif f =~ '\<test/integration/.*_test\.rb'
    let r = "test-integration"
  elseif f =~ '\<test/fixtures\>'
    if e == "yml"
      let r = "fixtures-yaml"
    else
      let r = "fixtures-" . e
    endif
  elseif f =~ '\<test/.*_test\.rb'
    let r = "test"
  elseif f =~ '\<db/migrate\>' || f=~ '\<db/schema\.rb$'
    let r = "migration"
  elseif f =~ '\<lib/tasks\>' || f=~ '\<Rakefile$'
    let r = "task"
  elseif f =~ '\<log/.*\.log$'
    let r = "log"
  elseif e == "css" || e == "js" || e == "html"
    let r = e
  endif
  return r
endfunction

function! RailsType()
  return RailsFileType()
endfunction

" }}}1
" Configuration {{{1

function! s:SetOptDefault(opt,val)
  if !exists("g:".a:opt)
    exe "let g:".a:opt." = '".a:val."'"
  endif
endfunction

function! s:InitConfig()
  call s:SetOptDefault("rails_level",3)
  let l = g:rails_level
  call s:SetOptDefault("rails_statusline",(l>2)+(l>3))
  call s:SetOptDefault("rails_syntax",l>1)
  call s:SetOptDefault("rails_isfname",0)
  call s:SetOptDefault("rails_mappings",l>2)
  call s:SetOptDefault("rails_abbreviations",l>2)
  call s:SetOptDefault("rails_expensive",l>2+(has("win32")||has("win32unix")))
  call s:SetOptDefault("rails_dbext",g:rails_expensive)
  call s:SetOptDefault("rails_subversion",l>3)
  call s:SetOptDefault("rails_tabstop",0)
  call s:SetOptDefault("rails_default_file","README")
  call s:SetOptDefault("rails_default_database","")
  call s:SetOptDefault("rails_leader","")
  call s:SetOptDefault("rails_root_url",'http://localhost:3000/')
  call s:SetOptDefault("rails_modelines",l>2)
  call s:SetOptDefault("rails_menu",(l>2)+(l>3))
  call s:SetOptDefault("rails_gnu_screen",1)
  call s:SetOptDefault("rails_debug",0)
  if l > 2
    if exists("g:loaded_dbext") && executable("sqlite3") && ! executable("sqlite")
      " Since dbext can't find it by itself
      call s:SetOptDefault("dbext_default_SQLITE_bin","sqlite3")
    endif
  endif
  if l > 3
    "call s:SetOptDefault("ruby_no_identifiers",1)
    call s:SetOptDefault("rubycomplete_rails",1)
  endif
endfunction

" }}}1
" Autocommand Functions {{{1

function! s:QuickFixCmdPre()
  if exists("b:rails_root")
    if strpart(getcwd(),0,strlen(RailsRoot())) != RailsRoot()
      let s:last_dir = getcwd()
      echo "lchdir ".s:ra()
      exe "lchdir ".s:ra()
    endif
  endif
endfunction

function! s:QuickFixCmdPost()
  if exists("s:last_dir")
    exe "lchdir ".s:escarg(s:last_dir)
    unlet s:last_dir
  endif
endfunction

function! s:BufEnter()
  if exists("b:rails_root")
    if g:rails_isfname
      let b:rails_restore_isfname=&isfname
      set isfname=@,48-57,/,-,_,\",',:
    endif
    if exists("+completefunc") && &completefunc == 'syntaxcomplete#Complete'
      if exists("g:loaded_syntax_completion")
        " Ugly but necessary, until we have our own completion
        unlet g:loaded_syntax_completion
        silent! delfunction syntaxcomplete#Complete
      endif
    endif
    call s:menuBufEnter()
    call s:BufDatabase(-1)
  else
    if isdirectory(expand('%;p'))
      call s:Detect(expand('%:p'))
    endif
  endif
endfunction

function! s:BufLeave()
  if exists("b:rails_restore_isfname")
    let &isfname=b:rails_restore_isfname
    unlet b:rails_restore_isfname
  endif
  call s:menuBufLeave()
endfunction

function! s:tabstop()
  if !exists("b:rails_root")
    return 0
  elseif &filetype != 'ruby' && &filetype != 'eruby' && &filetype != 'html' && &filetype != 'css' && &filetype != 'yaml'
    return 0
  elseif 1
    return s:getopt("tabstop","abg")
  elseif exists("b:rails_tabstop")
    return b:rails_tabstop
  else
    return g:rails_tabstop
  endif
endfunction

function! s:breaktabs()
  let ts = s:tabstop()
  if ts
    if exists("s:retab_in_process")
      unlet s:retab_in_process
      let line = line('.')
      lockmarks silent! undo
      lockmarks exe line
    else
      let &l:tabstop = 2
      setlocal noexpandtab
      let mod = &l:modifiable
      setlocal modifiable
      let line = line('.')
      " FIXME: when I say g/^\s/, only apply to those lines
      lockmarks g/^\s/retab!
      lockmarks exe line
      let &l:modifiable = mod
    endif
    let &l:tabstop = ts
    let &l:softtabstop = ts
    let &l:shiftwidth = ts
  endif
endfunction

function! s:fixtabs()
  let ts = s:tabstop()
  if ts && ! &l:expandtab && !exists("s:retab_in_process")
    let s:retab_in_process = 1
    let &l:tabstop = 2
    setlocal expandtab
    let line = line('.')
    lockmarks retab
    lockmarks exe line
    let &l:tabstop = ts
  endif
endfunction

" }}}1
" Commands {{{1

function! s:BufCommands()
  let rp = s:ra()
  call s:BufScriptWrappers()
  call s:BufNavCommands()
  command! -buffer -bar -nargs=? -bang -complete=custom,s:RakeComplete    Rake     :call s:Rake(<bang>0,<q-args>)
  command! -buffer -bar -nargs=? -bang -complete=custom,s:PreviewComplete Rpreview :call s:Preview(<bang>0,<q-args>)
  command! -buffer -bar -nargs=? -bang -complete=custom,s:environments    Rlog     :call s:Log(<bang>0,<q-args>)
  command! -buffer -bar -nargs=* -bang -complete=custom,s:SetComplete     Rset     :call s:Set(<bang>0,<f-args>)
  command! -buffer -bar -nargs=0 Rtags       :call s:Tags(<bang>0)
  command! -buffer -bar -nargs=0 -bang Rdoc  :if <bang>0 | call s:prephelp() | help rails | else | call s:Doc(<bang>0) | endif
  if exists(":Project")
    command! -buffer -bar -nargs=? -bang  Rproject :call s:Project(<bang>0,<q-args>)
  endif
  if exists("g:loaded_dbext")
    command! -buffer -bar -nargs=? -bang  Rdbext   :call s:BufDatabase(2,<q-args>,<bang>0)
  endif
  let ext = expand("%:e")
  if ext == "rhtml" || ext == "rxml" || ext == "rjs" || ext == "mab" || ext == "liquid"
    command! -buffer -bar -nargs=? -range Rextract :<line1>,<line2>call s:Partial(<bang>0,<f-args>)
    command! -buffer -bar -nargs=? -range Rpartial :call s:warn("Warning: :Rpartial has been deprecated in favor of :Rextract") | <line1>,<line2>Rextract<bang> <args>
  endif
  if RailsFileType() =~ '^\%(db-\)\=migration\>' && RailsFilePath() !~ '\<db/schema\.rb$'
    command! -buffer -bar                 Rinvert  :call s:Invert(<bang>0)
  endif
endfunction

function! s:Doc(bang)
  if isdirectory(RailsRoot()."/doc/api/classes")
    let url = RailsRoot()."/doc/api/index.html"
  elseif s:getpidfor("0.0.0.0","8808") > 0
    let url = "http://localhost:8808"
  else
    let url = "http://api.rubyonrails.org"
  endif
  call s:initOpenURL()
  if exists(":OpenURL")
    exe "OpenURL ".s:escarg(url)
  else
    return s:error("No :OpenURL command found")
  endif
endfunction

function! s:Log(bang,arg)
  if a:arg == ""
    let lf = "log/".s:environment().".log"
  else
    let lf = "log/".a:arg.".log"
  endif
  let size = getfsize(RailsRoot()."/".lf)
  if size >= 1048576
    call s:warn("Log file is ".((size+512)/1024)."KB.  Consider :Rake log:clear")
  endif
  if a:bang
    exe "cgetfile ".lf
    clast
  else
    if exists(":Tail")
      exe "Tail ".s:ra().'/'.lf
    else
      exe "pedit ".s:ra().'/'.lf
      "exe "sfind ".lf
    endif
  endif
endfunction

function! s:NewApp(bang,...)
  if a:0 == 0
    if a:bang
      echo "rails.vim revision ".s:revision
    else
      !rails
    endif
    return
  endif
  let dir = ""
  if a:1 !~ '^-'
    let dir = a:1
  elseif a:{a:0} =~ '[\/]'
    let dir = a:{a:0}
  else
    let dir = a:1
  endif
  let str = ""
  let c = 1
  while c <= a:0
    let str = str . " " . s:rquote(expand(a:{c}))
    let c = c + 1
  endwhile
  let dir = expand(dir)
  if isdirectory(fnamemodify(dir,':h')."/.svn") && g:rails_subversion
    let append = " -c"
  else
    let append = " "
  endif
  if g:rails_default_database != "" && str !~ '-d \|--database='
    let append = append." -d ".g:rails_default_database
  endif
  if a:bang
    let append = append." --force"
  endif
  exe "!rails".append.str
  if filereadable(dir."/".g:rails_default_file)
    exe "edit ".s:escarg(dir)."/".g:rails_default_file
  endif
endfunction

function! s:Tags(bang)
  if exists("g:Tlist_Ctags_Cmd")
    let cmd = g:Tlist_Ctags_Cmd
  elseif executable("exuberant-ctags")
    let cmd = "exuberant-ctags"
  elseif executable("ctags-exuberant")
    let cmd = "ctags-exuberant"
  elseif executable("ctags")
    let cmd = "ctags"
  elseif executable("ctags.exe")
    let cmd = "ctags.exe"
  else
    return s:error("ctags not found")
  endif
  exe "!".cmd." -R ".s:ra()
endfunction

" }}}1
" Rake {{{1

function! s:makewithruby(arg)
  let old_make = &makeprg
  let &l:makeprg = s:rubyexestr(a:arg)
  make
  let &l:makeprg = old_make
endfunction

function! s:Rake(bang,arg)
  let oldefm = ""
  if a:bang
    let oldefm = &efm
    "errorformat=%*[^"]"%f"%*\D%l: %m,"%f"%*\D%l: %m,%-G%f:%l: (Each undeclared identifier is reported only once,%-G%f:%l: for each function it appears in.),%f:%l:%c:%m,%f(%l):%m,%f:%l:%m,"%f"\, line %l%*\D%c%*[^ ] %m,%D%*\a[%*\d]: Entering directory `%f',%X%*\a[%*\d]: Leaving directory `%f',%D%*\a: Entering directory `%
    setlocal efm=\%+E%f:%l:\ parse\ error,%W%f:%l:\ warning:\ %m,%E%f:%l:in\ %*[^:]:\ %m,%E%f:%l:\ %m,%-C%\tfrom\ %f:%l:in\ %.%#,%-Z%\tfrom\ %f:%l,%-Z%p^,%-G%.%#
    " Need an error format for a full stack backtrace
  endif
  let t = RailsFileType()
  let arg = a:arg
  if &filetype == "ruby" && arg == '' && g:rails_modelines
    let lnum = s:lastmethodline()
    let str = getline(lnum)."\n".getline(lnum+1)."\n".getline(lnum+2)."\n"
    let pat = '\s\+\zs.\{-\}\ze\%(\n\|\s\s\|#{\@!\|$\)'
    let mat = matchstr(str,'#\s*rake'.pat)
    let mat = s:sub(mat,'\s\+$','')
    if mat != ""
      let arg = mat
    endif
  endif
  if arg == ''
    let opt = s:getopt('task','bl')
    if opt != ''
      let arg = opt
    endif
  endif
  if arg == "stats"
    " So you can see the output even with an inadequate redirect
    call s:QuickFixCmdPre()
    exe "!".&makeprg." stats"
    call s:QuickFixCmdPost()
  elseif arg =~ '^preview\>'
    exe 'R'.s:gsub(arg,':','/')
  elseif arg =~ '^runner:'
    " TODO: set a proper 'efm'
    let arg = s:sub(arg,'^runner:','')
    call s:makewithruby("script/runner ".s:rquote(s:esccmd(arg)))
  elseif arg == 'run'
    call s:makewithruby(expand("%"))
  elseif arg =~ '^run:'
    let arg = s:sub(arg,'^run:','')
    let arg = s:sub(arg,'^%:h',expand('%:h'))
    let arg = s:sub(arg,'^\%(%\|$\|[@#]\@=\)',expand('%'))
    let arg = s:sub(arg,'[@#]\(\w\+\)$',' -n\1')
    call s:makewithruby(arg)
  elseif arg != ''
    exe 'make '.arg
  elseif t =~ '^task\>'
    let lnum = s:lastmethodline()
    let line = getline(lnum)
    " We can't grab the namespace so only run tasks at the start of the line
    if line =~ '^\%(task\|file\)\>'
      exe 'make '.s:lastmethod()
    else
      make
    endif
  elseif t =~ '^test\>'
    let meth = s:lastmethod()
    if meth =~ '^test_'
      let call = " -n".meth.""
    else
      let call = ""
    endif
    if t =~ '^test-\%(unit\|functional\|integration\)$'
      exe "make ".s:sub(s:gsub(t,'-',':'),'unit$\|functional$','&s')." TEST=\"%:p\"".s:sub(call,'^ ',' TESTOPTS=')
    else
      call s:makewithruby("\"%:p\"".call)
    endif
  elseif t=~ '^\%(db-\)\=migration\>' && RailsFilePath() !~ '\<db/schema\.rb$'
    make db:migrate
  elseif t=~ '^model\>'
    make test:units TEST="%:p:r:s?[\/]app[\/]models[\/]?/test/unit/?_test.rb"
  elseif t=~ '^api\>'
    make test:units TEST="%:p:r:s?[\/]app[\/]apis[\/]?/test/functional/?_test.rb"
  elseif t=~ '^\<\%(controller\|helper\|view\)\>'
    if RailsFilePath() =~ '\<app/' && s:controller() != ""
      exe 'make test:functionals TEST="'.s:ra().'/test/functional/'.s:controller().'_controller_test.rb"'
    else
      make test:functionals
    endif
  else
    make
  endif
  if oldefm != ''
    let &efm = oldefm
  endif
endfunction

function! s:raketasks()
  return "db:fixtures:load\ndb:migrate\ndb:schema:dump\ndb:schema:load\ndb:sessions:clear\ndb:sessions:create\ndb:structure:dump\ndb:test:clone\ndb:test:clone_structure\ndb:test:prepare\ndb:test:purge\ndoc:app\ndoc:clobber_app\ndoc:clobber_plugins\ndoc:clobber_rails\ndoc:plugins\ndoc:rails\ndoc:reapp\ndoc:rerails\nlog:clear\nrails:freeze:edge\nrails:freeze:gems\nrails:unfreeze\nrails:update\nrails:update:configs\nrails:update:javascripts\nrails:update:scripts\nstats\ntest\ntest:functionals\ntest:integration\ntest:plugins\ntest:recent\ntest:uncommitted\ntest:units\ntmp:cache:clear\ntmp:clear\ntmp:create\ntmp:sessions:clear\ntmp:sockets:clear"
endfunction

function! s:RakeComplete(A,L,P)
  return s:raketasks()
endfunction

" }}}1
" Preview {{{1

function! s:initOpenURL()
  if !exists(":OpenURL")
    if has("gui_mac")
      command -bar -nargs=1 OpenURL :!open <args>
    elseif has("gui_win32")
      command -bar -nargs=1 OpenURL :!start cmd /cstart /b <args>
    elseif executable("sensible-browser")
      command -bar -nargs=1 OpenURL :!sensible-browser <args>
    endif
  endif
endfunction

function! s:Preview(bang,arg)
  let root = s:getopt("root_url")
  if root == ''
    let root = s:getopt("url")
  endif
  let root = s:sub(root,'/$','')
  if a:arg =~ '://'
    let uri = a:arg
  elseif a:arg != ''
    let uri = root.'/'.s:sub(a:arg,'^/','')
  else
    let uri = ''
    if s:getopt('preview','l') != ''
      let uri = s:getopt('preview','l')
    elseif s:controller() != '' && s:controller() != 'application'
      let uri = uri.s:controller().'/'
      if RailsFileType() =~ '^controller\>' && s:lastmethod() != ''
        let uri = uri.s:lastmethod().'/'
      elseif s:getopt('preview','b') != ''
        let uri = s:getopt('preview','b')
      elseif RailsFileType() =~ '^view\%(-partial\|-layout\)\@!'
        let uri = uri.expand('%:t:r').'/'
      endif
    elseif s:getopt('preview','b') != ''
      let uri = s:getopt('preview','b')
    elseif RailsFilePath() =~ '^public/'
      let uri = s:sub(RailsFilePath(),'^public/','')
    elseif s:getopt('preview','ag') != ''
      let uri = s:getopt('preview','ag')
    endif
    if uri !~ '://'
      let uri = root.'/'.s:sub(s:sub(uri,'^/',''),'/$','')
    endif
  endif
  call s:initOpenURL()
  if exists(':OpenURL') && !a:bang
    exe 'OpenURL '.uri
  else
    " Work around bug where URLs ending in / get handled as FTP
    let url = uri.(uri =~ '/$' ? '?' : '')
    silent exe 'pedit '.url
    wincmd w
    if &filetype == ''
      if uri =~ '\.css$'
        setlocal filetype=css
      elseif uri =~ '\.js$'
        setlocal filetype=javascript
      elseif getline(1) =~ '^\s*<'
        setlocal filetype=xhtml
      endif
    endif
    call s:Detect(RailsRoot())
    map <buffer> <silent> q :bwipe<CR>
    wincmd p
    if !a:bang
      call s:warn("Define a :OpenURL command to use a browser")
    endif
  endif
endfunction

function! s:PreviewComplete(A,L,P)
  let ret = ''
  if s:controller() != '' && s:controller() != 'application'
    let ret = s:controller().'/'
    if RailsFileType() =~ '^view\%(-partial\|-layout\)\@!'
      let ret = ret.expand('%:t:r').'/'
    elseif RailsFileType() =~ '^controller\>' && s:lastmethod() != ''
      let ret = ret.s:lastmethod().'/'
    endif
  endif
  return ret
endfunction

" }}}1
" Script Wrappers {{{1

function! s:BufScriptWrappers()
  command! -buffer -bar -nargs=+       -complete=custom,s:ScriptComplete   Rscript       :call s:Script(<bang>0,<f-args>)
  command! -buffer -bar -nargs=*       -complete=custom,s:ConsoleComplete  Rconsole      :call s:Console(<bang>0,"console",<f-args>)
  command! -buffer -bar -nargs=*                                           Rbreakpointer :call s:Console(<bang>0,"breakpointer",<f-args>)
  command! -buffer -bar -nargs=*       -complete=custom,s:GenerateComplete Rgenerate     :call s:Generate(<bang>0,<f-args>)
  command! -buffer -bar -nargs=*       -complete=custom,s:DestroyComplete  Rdestroy      :call s:Destroy(<bang>0,<f-args>)
  command! -buffer -bar -nargs=*       -complete=custom,s:PluginComplete   Rplugin       :call s:Plugin(<bang>0,<f-args>)
  command! -buffer -bar -nargs=? -bang -complete=custom,s:ServerComplete   Rserver       :call s:Server(<bang>0,<q-args>)
  command! -buffer      -nargs=1 -bang                                     Rrunner       :call s:Runner(<bang>0,<f-args>)
  command! -buffer      -nargs=1                                           Rp            :call s:Runner(<bang>0,"p begin ".<f-args>." end")
endfunction

function! s:Script(bang,cmd,...)
  let str = ""
  let c = 1
  while c <= a:0
    let str = str . " " . s:rquote(a:{c})
    let c = c + 1
  endwhile
  if a:bang
    call s:rubyexebg(s:rquote("script/".a:cmd).str)
  else
    call s:rubyexe(s:rquote("script/".a:cmd).str)
  endif
endfunction

function! s:Runner(bang,args)
  if a:bang
    call s:Script(a:bang,"runner",a:args)
  else
    let str = s:rubyexestr(s:rquote("script/runner")." ".s:rquote(a:args))
    let res = s:sub(system(str),'\n$','')
    echo res
  endif
endfunction

function! s:Console(bang,cmd,...)
  let str = ""
  let c = 1
  while c <= a:0
    let str = str . " " . s:rquote(a:{c})
    let c = c + 1
  endwhile
  call s:rubyexebg(s:rquote("script/".a:cmd).str)
endfunction

function! s:getpidfor(bind,port)
    if has("win32") || has("win64")
      let netstat = system("netstat -anop tcp")
      let pid = matchstr(netstat,'\<'.a:bind.':'.a:port.'\>.\{-\}LISTENING\s\+\zs\d\+')
    elseif executable('lsof')
      let pid = system("lsof -ti 4tcp@".a:bind.":".a:port)
      let pid = s:sub(pid,'\n','')
    else
      let pid = ""
    endif
    return pid
endfunction

function! s:Server(bang,arg)
  let port = matchstr(a:arg,'\%(-p\|--port=\=\)\s*\zs\d\+')
  if port == ''
    let port = "3000"
  endif
  " TODO: Extract bind argument
  let bind = "0.0.0.0"
  if a:bang && executable("ruby")
    let pid = s:getpidfor(bind,port)
    if pid =~ '^\d\+$'
      echo "Killing server with pid ".pid
      if !has("win32")
        call system("ruby -e 'Process.kill(:TERM,".pid.")'")
        sleep 100m
      endif
      call system("ruby -e 'Process.kill(9,".pid.")'")
      sleep 100m
    endif
    if a:arg == "-"
      return
    endif
  endif
  if has("win32") || has("win64") || (exists("$STY") && !has("gui_running") && s:getopt("gnu_screen","abg") && executable("screen"))
    call s:rubyexebg(s:rquote("script/server")." ".a:arg)
  else
    call s:rubyexe(s:rquote("script/server")." ".a:arg." --daemon")
  endif
  call s:setopt('a:root_url','http://'.(bind=='0.0.0.0'?'localhost': bind).':'.port.'/')
endfunction

function! s:Plugin(bang,...)
  if a:0 == 1 && !(a:1 =~ '^\%(discover\|list\|install\|update\|remove\|source\|unsource\|sources\)$')
    if filereadable(RailsRoot()."/vendor/plugins/".a:1."/init.rb")
      return s:findedit(a:bang?'!':'',"vendor/plugins/".a:1."/init.rb")
    endif
  endif
  let str = ""
  let c = 1
  while c <= a:0
    let str = str . " " . s:rquote(a:{c})
    let c = c + 1
  endwhile
  if s:usesubversion() && a:0 && a:1 == 'install'
    call s:rubyexe(s:rquote("script/plugin").str.' -x')
  else
    call s:rubyexe(s:rquote("script/plugin").str)
  endif
endfunction

function! s:Destroy(bang,...)
  if a:0 == 0
    call s:rubyexe("script/destroy")
    return
  elseif a:0 == 1
    call s:rubyexe("script/destroy ".s:rquote(a:1))
    return
  endif
  let str = ""
  let c = 1
  while c <= a:0
    let str = str . " " . s:rquote(a:{c})
    let c = c + 1
  endwhile
  call s:rubyexe(s:rquote("script/destroy").str.(s:usesubversion()?' -c':''))
endfunction

function! s:Generate(bang,...)
  if a:0 == 0
    call s:rubyexe("script/generate")
    return
  elseif a:0 == 1
    call s:rubyexe("script/generate ".s:rquote(a:1))
    return
  endif
  let target = s:rquote(a:1)
  let str = ""
  let c = 2
  while c <= a:0
    let str = str . " " . s:rquote(a:{c})
    let c = c + 1
  endwhile
  if str !~ '-p\>'
    let execstr = s:rubyexestr("script/generate ".target." -p -f".str)
    let res = system(execstr)
    let file = matchstr(res,'\s\+\%(create\|force\)\s\+\zs\f\+\.rb\ze\n')
    if file == ""
      let file = matchstr(res,'\s\+\%(exists\)\s\+\zs\f\+\.rb\ze\n')
    endif
    "echo file
  else
    let file = ""
  endif
  if !s:rubyexe("script/generate ".target.(s:usesubversion()?' -c':'').str) && file != ""
    exe "edit ".s:ra()."/".file
  endif
endfunction

function! s:generators()
  return "controller\nintegration_test\nmailer\nmigration\nmodel\nobserver\nplugin\nscaffold\nsession_migration\nweb_service"
endfunction

function! s:ScriptComplete(ArgLead,CmdLine,P)
  "  return s:gsub(glob(RailsRoot()."/script/**"),'\%(.\%(\n\)\@<!\)*[\/]script[\/]','')
  let cmd = s:sub(a:CmdLine,'^\u\w*\s\+','')
  let P = a:P - strlen(a:CmdLine)+strlen(cmd)
  let g:A = a:ArgLead
  let g:L = cmd
  let g:P = P
  let g:foo = strlen(cmd)-P
  if cmd !~ '^[ A-Za-z0-9_=-]*$'
    " You're on your own, bud
    return ""
  elseif cmd =~ '^\w*$'
    return "about\nbreakpointer\nconsole\ndestroy\ngenerate\nperformance/benchmarker\nperformance/profiler\nplugin\nproccess/reaper\nprocess/spawner\nrunner\nserver"
  elseif cmd =~ '^\%(plugin\)\s\+'.a:ArgLead.'$'
    return "discover\nlist\ninstall\nupdate\nremove\nsource\nunsource\nsources"
  elseif cmd =~ '\%(plugin\)\s\+\%(install\|remove\)\s\+'.a:ArgLead.'$' || cmd =~ '\%(generate\|destroy\)\s\+plugin\s\+'.a:ArgLead.'$'
      return s:relglob('vendor/plugins/',"*","/init.rb")
  elseif cmd =~ '^\%(generate\|destroy\)\s\+'.a:ArgLead.'$'
    return s:generators()
  elseif cmd =~ '^\%(generate\|destroy\)\s\+\w\+\s\+'.a:ArgLead.'$'
    let target = matchstr(cmd,'^\w\+\s\+\zs\w\+\ze\s\+')
    let pattern = "" " TODO
    if target == 'controller'
      return s:sub(s:controllerList(pattern,"",""),'^application\n\=','')
    elseif target == 'model' || target == 'scaffold' || target == 'mailer'
      return s:modelList(pattern,"","")
    elseif target == 'migration' || target == 'session_migration'
      return s:migrationList(pattern,"","")
    elseif target == 'integration_test'
      return s:integrationtestList(pattern,"","")
    elseif target == 'observer'
      " script/generate observer is in Edge Rails
      let observers = s:observerList(pattern,"","")
      let models = s:modelList(pattern,"","")
      if cmd =~ '^destroy\>'
        let models = ""
      endif
      while strlen(models) > 0
        let tmp = matchstr(models."\n",'.\{-\}\ze\n')
        let models = s:sub(models,'.\{-\}\%(\n\|$\)','')
        if stridx("\n".observers."\n","\n".tmp."\n") == -1 && tmp !~'_observer$'
          let observers = observers."\n".tmp
        endif
      endwhile
      return s:sub(observers,'^\n','')
    elseif target == 'web_service'
      return s:apiList(pattern,"","")
    else
      return ""
    endif
  elseif cmd =~ '^\%(generate\|destroy\)\s\+scaffold\s\+\w\+\s\+'.a:ArgLead.'$'
    return s:sub(s:controllerList("","",""),'^application\n\=','')
  elseif cmd =~ '^\%(console\)\s\+\(--\=\w\+\s\+\)\='.a:ArgLead."$"
    return s:environments()."\n-s\n--sandbox"
  elseif cmd =~ '^\%(server\)\s\+.*-e\s\+'.a:ArgLead."$"
    return s:environments()
  elseif cmd =~ '^\%(server\)\s\+'
    return "-p\n-b\n-e\n-m\n-d\n-c\n-h\n--port=\n--binding=\n--environment=\n--mime-types=\n--daemon\n--charset=\n--help\n"
  endif
  return ""
"  return s:relglob(RailsRoot()."/script/",a:ArgLead."*")
endfunction

function! s:CustomComplete(A,L,P,cmd)
  let L = "Script ".a:cmd." ".s:sub(a:L,'^\h\w*\s\+','')
  let P = a:P - strlen(a:L) + strlen(L)
  return s:ScriptComplete(a:A,L,P)
endfunction

function! s:ServerComplete(A,L,P)
  return s:CustomComplete(a:A,a:L,a:P,"server")
endfunction

function! s:ConsoleComplete(A,L,P)
  return s:CustomComplete(a:A,a:L,a:P,"console")
endfunction

function! s:GenerateComplete(A,L,P)
  return s:CustomComplete(a:A,a:L,a:P,"generate")
endfunction

function! s:DestroyComplete(A,L,P)
  return s:CustomComplete(a:A,a:L,a:P,"destroy")
endfunction

function! s:PluginComplete(A,L,P)
  return s:CustomComplete(a:A,a:L,a:P,"plugin")
endfunction

" }}}1
" Navigation {{{1

function! s:BufNavCommands()
  " TODO: completion
  silent exe "command! -bar -buffer -nargs=? Rcd :cd ".s:rp()."/<args>"
  silent exe "command! -bar -buffer -nargs=? Rlcd :lcd ".s:rp()."/<args>"
  command!   -buffer -bar -nargs=* -count=1 -complete=custom,s:FindList Rfind       :call s:Find(<bang>0,<count>,"" ,<f-args>)
  command!   -buffer -bar -nargs=* -count=1 -complete=custom,s:FindList REfind      :call s:Find(<bang>0,<count>,"E",<f-args>)
  command!   -buffer -bar -nargs=* -count=1 -complete=custom,s:FindList RSfind      :call s:Find(<bang>0,<count>,"S",<f-args>)
  command!   -buffer -bar -nargs=* -count=1 -complete=custom,s:FindList RVfind      :call s:Find(<bang>0,<count>,"V",<f-args>)
  command!   -buffer -bar -nargs=* -count=1 -complete=custom,s:FindList RTfind      :call s:Find(<bang>0,<count>,"T",<f-args>)
  command!   -buffer -bar -nargs=* -count=1 -complete=custom,s:FindList Rsfind      :<count>RSfind<bang> <args>
  command!   -buffer -bar -nargs=* -count=1 -complete=custom,s:FindList Rvsfind     :<count>RVfind<bang> <args>
  command!   -buffer -bar -nargs=* -count=1 -complete=custom,s:FindList Rtabfind    :<count>RTfind<bang> <args>
  command!   -buffer -bar -nargs=* -bang    -complete=custom,s:EditList Redit       :call s:Edit(<bang>0,<count>,"" ,<f-args>)
  command!   -buffer -bar -nargs=* -bang    -complete=custom,s:EditList REedit      :call s:Edit(<bang>0,<count>,"E",<f-args>)
  command!   -buffer -bar -nargs=* -bang    -complete=custom,s:EditList RSedit      :call s:Edit(<bang>0,<count>,"S",<f-args>)
  command!   -buffer -bar -nargs=* -bang    -complete=custom,s:EditList RVedit      :call s:Edit(<bang>0,<count>,"V",<f-args>)
  command!   -buffer -bar -nargs=* -bang    -complete=custom,s:EditList RTedit      :call s:Edit(<bang>0,<count>,"T",<f-args>)
  command! -buffer -bar -nargs=0 A  :call s:Alternate(<bang>0,"")
  command! -buffer -bar -nargs=0 AE :call s:Alternate(<bang>0,"E")
  command! -buffer -bar -nargs=0 AS :call s:Alternate(<bang>0,"S")
  command! -buffer -bar -nargs=0 AV :call s:Alternate(<bang>0,"V")
  command! -buffer -bar -nargs=0 AT :call s:Alternate(<bang>0,"T")
  command! -buffer -bar -nargs=0 AN :call s:Related(<bang>0,"")
  command! -buffer -bar -nargs=0 R  :call s:Related(<bang>0,"")
  command! -buffer -bar -nargs=0 RE :call s:Related(<bang>0,"E")
  command! -buffer -bar -nargs=0 RS :call s:Related(<bang>0,"S")
  command! -buffer -bar -nargs=0 RV :call s:Related(<bang>0,"V")
  command! -buffer -bar -nargs=0 RT :call s:Related(<bang>0,"T")
  "command! -buffer -bar -nargs=0 RN :call s:Alternate(<bang>0,"")
  call s:BufFinderCommands()
endfunction

function! s:Find(bang,count,arg,...)
  let cmd = a:arg . (a:bang ? '!' : '')
  let str = ""
  if a:0
    let i = 1
    while i < a:0
      let str = str . s:escarg(a:{i}) . " "
      let i = i + 1
    endwhile
    let file = a:{i}
    let tail = matchstr(file,'[@#].*$')
    if tail != ""
      let file = s:sub(file,'[@#].*$','')
    endif
    if file != ""
      let file = s:RailsIncludefind(file,1)
    endif
  else
    let file = s:RailsFind()
    let tail = ""
  endif
  if file =~ '^\%(app\|components\|config\|db\|public\|test\|vendor\)/.*\.' || !a:0 || 1
    call s:findedit((a:count==1?'' : a:count).cmd,file.tail,str)
  else
    " Old way
    let fcmd = (a:count==1?'' : a:count).s:findcmdfor(cmd)
    let fcmd = s:sub(fcmd,'\(\d\+\)vert ','vert \1')
    if file != ""
      exe fcmd.' '.str.s:escarg(file)
    endif
    if tail != ""
      silent! exe "djump ".matchstr(tail,'[@#]\zs.*$')
    endif
  endif
endfunction

function! s:Edit(bang,count,arg,...)
  let cmd = a:arg . (a:bang ? '!' : '')
  let str = ""
  if a:0
    let i = 1
    while i < a:0
      let str = str . s:escarg(a:{i}) . " "
      let i = i + 1
    endwhile
    let file = a:{i}
    call s:findedit(cmd,file,str)
  else
    exe s:editcmdfor(cmd)
  endif
endfunction

function! s:FindList(ArgLead, CmdLine, CursorPos)
  if exists("*UserFileComplete") " genutils.vim
    return UserFileComplete(s:RailsIncludefind(a:ArgLead), a:CmdLine, a:CursorPos, 1, &path)
  else
    return ""
  endif
endfunction

function! s:EditList(ArgLead, CmdLine, CursorPos)
  if exists("*UserFileComplete") " genutils.vim
    return UserFileComplete(s:RailsIncludefind(a:ArgLead), a:CmdLine, a:CursorPos, 1, s:rp())
  else
    return ""
  endif
endfunction

function! RailsIncludeexpr()
  " Is this foolproof?
  if mode() =~ '[iR]' || expand("<cfile>") != v:fname
    return s:RailsIncludefind(v:fname)
  else
    return s:RailsIncludefind(v:fname,1)
  endif
endfunction

function! s:linepeak()
  let line = getline(line("."))
  let line = s:sub(line,'^\(.\{'.col(".").'\}\).*','\1')
  let line = s:sub(line,'\([:"'."'".']\|%[qQ]\=[[({<]\)\=\f*$','')
  return line
endfunction

function! s:matchcursor(pat)
  let line = getline(".")
  let lastend = 0
  while lastend >= 0
    let beg = match(line,'\C'.a:pat,lastend)
    let end = matchend(line,'\C'.a:pat,lastend)
    if beg < col(".") && end >= col(".")
      return matchstr(line,'\C'.a:pat,lastend)
    endif
    let lastend = end
  endwhile
  return ""
endfunction

function! s:findit(pat,repl)
  let res = s:matchcursor(a:pat)
  if res != ""
    return s:sub(res,a:pat,a:repl)
  else
    return ""
  endif
endfunction

function! s:findamethod(func,repl)
  return s:findit('\s*\<\%('.a:func.'\)\s*(\=\s*[:'."'".'"]\(\f\+\)\>.\=',a:repl)
endfunction

function! s:findasymbol(sym,repl)
  return s:findit('\s*:\%('.a:sym.'\)\s*=>\s*(\=\s*[:'."'".'"]\(\f\+\)\>.\=',a:repl)
endfunction

function! s:findfromview(func,repl)
  return s:findit('\s*\%(<%=\=\)\=\s*\<\%('.a:func.'\)\s*(\=\s*[:'."'".'"]\(\f\+\)\>['."'".'"]\=\s*\%(%>\s*\)\=',a:repl)
endfunction

function! s:RailsFind()
  " UGH
  let res = s:findit('\s*\<require\s*(\=\s*File.dirname(__FILE__)\s*+\s*[:'."'".'"]\(\f\+\)\>.\=',expand('%:h').'/\1')
  if res != ""|return res.(fnamemodify(res,':e') == '' ? '.rb' : '')|endif
  let res = s:findit('\<File.dirname(__FILE__)\s*+\s*[:'."'".'"]\(\f\+\)\>['."'".'"]\=',expand('%:h').'\1')
  if res != ""|return res|endif
  let res = s:findamethod('require','\1')
  if res != ""|return res.(fnamemodify(res,':e') == '' ? '.rb' : '')|endif
  let res = s:findamethod('belongs_to\|has_one\|composed_of\|validates_associated','app/models/\1.rb')
  if res != ""|return res|endif
  let res = s:singularize(s:findamethod('has_many\|has_and_belongs_to_many','app/models/\1'))
  if res != ""|return res.".rb"|endif
  let res = s:singularize(s:findamethod('create_table\|drop_table\|add_column\|rename_column\|remove_column\|add_index','app/models/\1'))
  if res != ""|return res.".rb"|endif
  let res = s:singularize(s:findasymbol('through','app/models/\1'))
  if res != ""|return res.".rb"|endif
  let res = s:findamethod('fixtures','test/fixtures/\1')
  if res != ""|return res|endif
  let res = s:findamethod('layout','app/views/layouts/\1')
  if res != ""|return res|endif
  let res = s:findasymbol('layout','app/views/layouts/\1')
  if res != ""|return res|endif
  let res = s:findamethod('helper','app/helpers/\1_helper.rb')
  if res != ""|return res|endif
  let res = s:findasymbol('controller','app/controllers/\1_controller.rb')
  if res != ""|return res|endif
  let res = s:findasymbol('action','\1')
  if res != ""|return res|endif
  let res = s:sub(s:findasymbol('partial','\1'),'\k\+$','_&')
  if res != ""|return res|endif
  let res = s:sub(s:findfromview('render\s*(\=\s*:partial\s\+=>\s*','\1'),'\k\+$','_&')
  if res != ""|return res|endif
  let res = s:findamethod('render\s*:\%(template\|action\)\s\+=>\s*','\1')
  if res != ""|return res|endif
  let res = s:findamethod('redirect_to\s*(\=\s*:action\s\+=>\s*','\1')
  if res != ""|return res|endif
  let res = s:findfromview('stylesheet_link_tag','public/stylesheets/\1.css')
  if res != ""|return res|endif
  let res = s:sub(s:findfromview('javascript_include_tag','public/javascripts/\1.js'),'/defaults\>','/application')
  if res != ""|return res|endif
  if RailsFileType() =~ '^controller\>'
    let res = s:findit('\s*\<def\s\+\(\k\+\)\>(\=',s:sub(s:sub(RailsFilePath(),'/controllers/','/views/'),'_controller\.rb$','').'/\1')
    if res != ""|return res|endif
  endif
  let isf_keep = &isfname
  set isfname=@,48-57,/,-,_,: ",\",'
  " TODO: grab visual selection in visual mode
  let cfile = expand("<cfile>")
  let res = s:RailsIncludefind(cfile,1)
  let &isfname = isf_keep
  return res
endfunction

function! s:RailsIncludefind(str,...)
  if a:str == "ApplicationController"
    return "app/controllers/application.rb"
  elseif a:str == "Test::Unit::TestCase"
    return "test/unit/testcase.rb"
  elseif a:str == "<%="
    " Probably a silly idea
    return "action_view.rb"
  endif
  let g:mymode = mode()
  let str = a:str
  if a:0 == 1
    " Get the text before the filename under the cursor.
    " We'll cheat and peak at this in a bit
    let line = s:linepeak()
    let line = s:sub(line,'\([:"'."'".']\|%[qQ]\=[[({<]\)\=\f*$','')
  else
    let line = ""
  endif
  let str = s:sub(str,'^\s*','')
  let str = s:sub(str,'\s*$','')
  let str = s:sub(str,'^[:@]','')
  "let str = s:sub(str,"\\([\"']\\)\\(.*\\)\\1",'\2')
  let str = s:sub(str,':0x\x\+$','') " For #<Object:0x...> style output
  let str = s:gsub(str,"[\"']",'')
  if line =~ '\<\(require\|load\)\s*(\s*$'
    return str
  endif
  let str = s:underscore(str)
  let fpat = '\(\s*\%("\f*"\|:\f*\|'."'\\f*'".'\)\s*,\s*\)*'
  if a:str =~ '\u'
    " Classes should always be in .rb files
    let str = str . '.rb'
  elseif line =~ '\(:partial\|"partial"\|'."'partial'".'\)\s*=>\s*'
    let str = s:sub(str,'\([^/]\+\)$','_\1')
    if str =~ '^\./'
    elseif str =~ '/'
      let str = 'app/views/' . s:sub(str,'^/','')
    else
      let str = 'app/views/' . s:controller() . str
    endif
  elseif line =~ '\<layout\s*(\=\s*' || line =~ '\(:layout\|"layout"\|'."'layout'".'\)\s*=>\s*'
    let str = s:sub(str,'^/\=','views/layouts/')
  elseif line =~ '\(:controller\|"controller"\|'."'controller'".'\)\s*=>\s*'
    let str = 'controllers/'.str.'_controller.rb'
  elseif line =~ '\<helper\s*(\=\s*'
    let str = 'helpers/'.str.'_helper.rb'
  elseif line =~ '\<fixtures\s*(\='.fpat
    let str = s:sub(str,'^/\@!','test/fixtures/')
  elseif line =~ '\<stylesheet_\(link_tag\|path\)\s*(\='.fpat
    let str = s:sub(str,'^/\@!','/stylesheets/')
    let str = 'public'.s:sub(str,'^[^.]*$','&.css')
  elseif line =~ '\<javascript_\(include_tag\|path\)\s*(\='.fpat
    if str == "defaults"
      let str = "application"
    endif
    let str = s:sub(str,'^/\@!','/javascripts/')
    let str = 'public'.s:sub(str,'^[^.]*$','&.js')
  elseif line =~ '\<\(has_one\|belongs_to\)\s*(\=\s*'
    let str = 'models/'.str.'.rb'
  elseif line =~ '\<has_\(and_belongs_to_\)\=many\s*(\=\s*'
    let str = 'models/'.s:singularize(str).'.rb'
  elseif line =~ '\<def\s\+' && expand("%:t") =~ '_controller\.rb'
    let str = s:sub(s:sub(RailsFilePath(),'/controllers/','/views/'),'_controller\.rb$','/'.str)
    "let str = s:sub(expand("%:p"),'.*[\/]app[\/]controllers[\/]\(.\{-\}\)_controller.rb','views/\1').'/'.str
    if filereadable(str.".rhtml")
      let str = str . ".rhtml"
    elseif filereadable(str.".rxml")
      let str = str . ".rxml"
    elseif filereadable(str.".rjs")
      let str = str . ".rjs"
    endif
  else
    " If we made it this far, we'll risk making it singular.
    let str = s:singularize(str)
    let str = s:sub(str,'_id$','')
  endif
  if str =~ '^/' && !filereadable(str)
    let str = s:sub(str,'^/','')
  endif
  if str =~ '^lib/' && !filereadable(str)
    let str = s:sub(str,'^lib/','')
  endif
  return str
endfunction

" }}}1
" File Finders {{{1

function! s:addfilecmds(type)
  let l = s:sub(a:type,'^.','\l&')
  let cmds = 'ESVT'
  let cmd = ''
  while cmds != ''
    exe "command! -buffer -bar -nargs=* -complete=custom,s:".l."List R".cmd.l." :call s:".l.'Edit(<bang>0,"'.cmd.'",<f-args>)'
    let cmd = strpart(cmds,0,1)
    let cmds = strpart(cmds,1)
  endwhile
endfunction

function! s:BufFinderCommands()
  call s:addfilecmds("model")
  call s:addfilecmds("view")
  call s:addfilecmds("controller")
  call s:addfilecmds("migration")
  call s:addfilecmds("observer")
  call s:addfilecmds("helper")
  call s:addfilecmds("api")
  call s:addfilecmds("layout")
  call s:addfilecmds("fixtures")
  call s:addfilecmds("unittest")
  call s:addfilecmds("functionaltest")
  call s:addfilecmds("integrationtest")
endfunction

function! s:relglob(path,glob,...)
  " How could such a simple operation be so complicated?
  if a:path =~ '[\/]$'
    let path = a:path
  else
    let path = a:path . ''
  endif
  if path !~ '^/' && path !~ '^\w:' && RailsRoot() != ''
    let path = RailsRoot() . '/' . path
  endif
  let suffix = a:0 ? a:1 : ''
  let badres = glob(path.a:glob.suffix)."\n"
  let goodres = ""
  let striplen = strlen(path)
  let stripend = strlen(suffix)
  while strlen(badres) > 0
    let idx = stridx(badres,"\n")
    "if idx == -1
      "let idx = strlen(badres)
    "endif
    let tmp = strpart(badres,0,idx)
    let badres = strpart(badres,idx+1)
    let goodres = goodres.strpart(tmp,striplen,strlen(tmp)-striplen-stripend)
    if suffix == '' && isdirectory(tmp)
      let goodres = goodres."/"
    endif
    let goodres = goodres."\n"
  endwhile
  return s:sub(goodres,'\n$','')
endfunction

function! s:helperList(A,L,P)
  return s:relglob("app/helpers/",a:A."**","_helper.rb")
endfunction

function! s:controllerList(A,L,P)
  let con = s:relglob("app/controllers/",a:A."*","_controller.rb")
  if con != ''
    return "application\n".con
  else
    return "application"
  endif
endfunction

function! s:viewList(A,L,P)
  let c = s:controller(1)
  let top = s:relglob("app/views/",a:A."*")
  if c != ''
    let local = s:relglob("app/views/".c."/",a:A."*.*[^~]")
    if local != ''
      return local."\n".top
    endif
  endif
  return top
endfunction

function! s:layoutList(A,L,P)
  return s:relglob("app/views/layouts/",a:A."*")
endfunction

function! s:modelList(A,L,P)
  let models = s:relglob("app/models/",a:A."**",".rb")."\n"
  let models = s:gsub(models,'\n.\{-\}_observer\%(\n\@=\|$\)',"")
  return s:sub(models,'^\n','')
endfunction

function! s:observerList(A,L,P)
  return s:relglob("app/models/",a:A."**","_observer.rb")
endfunction

function! s:fixturesList(A,L,P)
  return s:relglob("test/fixtures/",a:A."*[^~]")
endfunction

function! s:migrationList(A,L,P)
  return s:relglob("db/migrate/???_",a:A."*",".rb")
endfunction

function! s:apiList(A,L,P)
  return s:relglob("app/apis/",a:A."**","_api.rb")
endfunction

function! s:unittestList(A,L,P)
  return s:relglob("test/unit/",a:A."**","_test.rb")
endfunction

function! s:functionaltestList(A,L,P)
  return s:relglob("test/functional/",a:A."**","_test.rb")
endfunction

function! s:integrationtestList(A,L,P)
  return s:relglob("test/integration/",a:A."**","_test.rb")
endfunction

function! s:EditSimpleRb(bang,cmd,name,target,prefix,suffix)
  let cmd = s:findcmdfor(a:cmd.(a:bang?'!':''))
  if a:target == ""
    " Good idea to emulate error numbers like this?
    return s:error("E471: Argument required") " : R',a:name)
  endif
  let f = a:prefix.s:underscore(a:target).a:suffix.".rb"
  return s:findedit(cmd,f)
endfunction

function! s:migrationfor(file)
  let tryagain = 0
  let arg = a:file
  if arg =~ '^\d$'
    let glob = '00'.arg.'_*.rb'
  elseif arg =~ '^\d\d$'
    let glob = '0'.arg.'_*.rb'
  elseif arg =~ '^\d\d\d$'
    let glob = ''.arg.'_*.rb'
  elseif arg == ''
    if s:model(1) != ''
      let glob = '*_'.s:pluralize(s:model(1)).'.rb'
      let tryagain = 1
    else
      let glob = '*.rb'
    endif
  else
    let glob = '*'.arg.'*.rb'
  endif
  let migr = s:sub(glob(RailsRoot().'/db/migrate/'.glob),'.*\n','')
  if migr == '' && tryagain
    let migr = s:sub(glob(RailsRoot().'/db/migrate/*.rb'),'.*\n','')
  endif
  return migr
endfunction

function! s:migrationEdit(bang,cmd,...)
  let cmd = s:findcmdfor(a:cmd.(a:bang?'!':''))
  let arg = a:0 ? a:1 : ''
  let migr = s:migrationfor(arg)
  if migr != ''
    call s:findedit(cmd,migr)
  else
    return s:error("Migration not found".(arg=='' ? '' : ': '.arg))
  endif
endfunction

function! s:fixturesEdit(bang,cmd,...)
  if a:0
    let c = s:underscore(a:1)
  else
    let c = s:pluralize(s:model(1))
  endif
  if c == ""
    return s:error("E471: Argument required")
  endif
  let e = fnamemodify(c,':e')
  let e = e == '' ? e : '.'.e
  let c = fnamemodify(c,':r')
  let file = 'test/fixtures/'.c.e
  if file =~ '\.\w\+$'
    call s:edit(a:cmd.(a:bang?'!':''),file)
  else
    call s:findedit(a:cmd.(a:bang?'!':''),file)
  endif
endfunction

function! s:modelEdit(bang,cmd,...)
  call s:EditSimpleRb(a:bang,a:cmd,"model",a:0? a:1 : s:model(1),"app/models/","")
endfunction

function! s:observerEdit(bang,cmd,...)
  call s:EditSimpleRb(a:bang,a:cmd,"observer",a:0? a:1 : s:model(1),"app/models/","_observer")
endfunction

function! s:viewEdit(bang,cmd,...)
  if a:0
    let view = a:1
  elseif RailsFileType() == 'controller'
    let view = s:lastmethod()
  else
    let view = ''
  endif
  if view == ''
    return s:error("No view name given")
  elseif view !~ '/' && s:controller(1) != ''
    let view = s:controller(1) . '/' . view
  endif
  if view !~ '/'
    return s:error("Cannot find view without controller")
  endif
  let file = "app/views/".view
  if file =~ '\.\w\+$'
    call s:edit(a:cmd.(a:bang?'!':''),file)
  else
    call s:findedit(a:cmd.(a:bang?'!':''),file)
  endif
endfunction

function! s:findlayout(name)
  let c = a:name
  let pre = "app/views/layouts/"
  if c =~ '\.'
    return pre.c
  elseif filereadable(RailsRoot(). pre.c.".rhtml")
    let file = pre.c.".rhtml"
  elseif filereadable(RailsRoot(). pre.c.".rxml")
    let file = pre.c.".rxml"
  elseif filereadable(RailsRoot(). pre.c.".mab")
    let file = pre.c.".mab"
  elseif filereadable(RailsRoot(). pre.c.".liquid")
    let file = pre.c.".liquid"
  else
    let file = ""
  endif
  return file
endfunction

function! s:layoutEdit(bang,cmd,...)
  if a:0
    let c = s:underscore(a:1)
  else
    let c = s:controller(1)
  endif
  if c == ""
    return s:error("No layout name given")
  endif
  let file = s:findlayout(c)
  if file == ""
    let file = s:findlayout("application")
  endif
  if file == ""
    let file = "app/views/layouts/application.rhtml"
  endif
  call s:edit(a:cmd.(a:bang?'!':''),s:sub(file,'^/',''))
endfunction

function! s:controllerEdit(bang,cmd,...)
  let controller = a:0 ? a:1 : s:controller(1)
  return s:EditSimpleRb(a:bang,a:cmd,"controller",controller,"app/controllers/",controller == "application" ? "" : "_controller")
endfunction

function! s:helperEdit(bang,cmd,...)
  return s:EditSimpleRb(a:bang,a:cmd,"helper",a:0? a:1 : s:controller(1),"app/helpers/","_helper")
endfunction

function! s:apiEdit(bang,cmd,...)
  return s:EditSimpleRb(a:bang,a:cmd,"api",a:0 ? a:1 : s:controller(1),"app/apis/","_api")
endfunction

function! s:unittestEdit(bang,cmd,...)
  let f = a:0 ? a:1 : s:model(1)
  if !a:0 && RailsFileType() =~ '^model-aro\>' && f != '' && f !~ '_observer$'
    if filereadable(RailsRoot()."/test/unit/".f."_observer.rb") || !filereadable(RailsRoot()."/test/unit/".f.".rb")
      let f = f . "_observer"
    endif
  endif
  return s:EditSimpleRb(a:bang,a:cmd,"unittest",f,"test/unit/","_test")
endfunction

function! s:functionaltestEdit(bang,cmd,...)
  if a:0
    let f = a:1
  else
    let f = s:controller()
  endif
  if f != '' && !filereadable(RailsRoot()."/test/functional/".f."_test.rb")
    if filereadable(RailsRoot()."/test/functional/".f."_controller_test.rb")
      let f = f . "_controller"
    elseif filereadable(RailsRoot()."/test/functional/".f."_api_test.rb")
      let f = f . "_api"
    endif
  endif
  return s:EditSimpleRb(a:bang,a:cmd,"functionaltest",f,"test/functional/","_test")
endfunction

function! s:integrationtestEdit(bang,cmd,...)
  if a:0
    let f = a:1
  elseif s:model() != ''
    let f = s:model()
  else
    let f = s:controller()
  endif
  return s:EditSimpleRb(a:bang,a:cmd,"integrationtest",f,"test/integration/","_test")
endfunction

" }}}1
" Alternate/Related {{{1

function! s:findcmdfor(cmd)
  let bang = ''
  if a:cmd =~ '!$'
    let bang = '!'
    let cmd = s:sub(a:cmd,'!$','')
  else
    let cmd = a:cmd
  endif
  if cmd =~ '^\d'
    let num = matchstr(cmd,'^\d\+')
    let cmd = s:sub(cmd,'^\d\+','')
  else
    let num = ''
  endif
  if cmd == '' || cmd == 'E' || cmd == 'F'
    return num.'find'.bang
  elseif cmd == 'S'
    return num.'sfind'.bang
  elseif cmd == 'V'
    return 'vert '.num.'sfind'.bang
  elseif cmd == 'T'
    return num.'tabfind'.bang
  else
    return num.cmd.bang
  endif
endfunction

function! s:editcmdfor(cmd)
  let cmd = s:findcmdfor(a:cmd)
  let cmd = s:sub(cmd,'\<sfind\>','split')
  let cmd = s:sub(cmd,'find\>','edit')
  return cmd
endfunction

function! s:try(cmd) abort
  if !exists(":try")
    " I've seen at least one weird setup without :try
    exe a:cmd
  else
    try
      exe a:cmd
    catch
      call s:error(s:sub(v:exception,'^.\{-\}:\zeE',''))
      return 0
    endtry
  endif
  return 1
endfunction

function! s:findedit(cmd,file,...) abort
  " TODO: consider rewriting for components
  let cmd = s:findcmdfor(a:cmd)
  let file = a:file
  if file =~ '[@#]'
    let djump = matchstr(file,'[@#]\zs.*')
    let file = matchstr(file,'.*\ze[@#]')
  else
    let djump = ''
  endif
  if file == ''
    let testcmd = "edit"
  elseif RailsRoot() =~ '://'
    if file !~ '^/' && file !~ '^\w:' && file !~ '://'
      let file = s:ra().'/'.file
    endif
    let testcmd = s:editcmdfor(cmd).' '.(a:0 ? a:1 . ' ' : '').file
  else
    let testcmd = cmd.' '.(a:0 ? a:1 . ' ' : '').file
  endif
  if s:try(testcmd) && djump != ''
    silent! exe 'djump '.djump
  endif
endfunction

function! s:edit(cmd,file,...)
  let cmd = s:editcmdfor(a:cmd)
  let file = a:file
  if file !~ '^/' && file !~ '^\w:' && file !~ '://'
    let file = s:ra().'/'.file
  endif
    exe cmd.' '.(a:0 ? a:1 . ' ' : '').file
endfunction

function! s:Alternate(bang,cmd)
  let cmd = a:cmd.(a:bang?"!":"")
  let file = s:AlternateFile()
  if file != ""
    call s:findedit(cmd,file)
  else
    call s:warn("No alternate file is defined")
  endif
endfunction

function! s:AlternateFile()
  let f = RailsFilePath()
  let t = RailsFileType()
  let altopt = s:getopt("alternate","bl")
  if altopt != ""
    return altopt
  elseif f =~ '\<config/environments/'
    return "config/environment.rb"
  elseif f == 'README'
    return "config/database.yml"
  elseif f =~ '\<config/database\.yml$'   | return "config/routes.rb"
  elseif f =~ '\<config/routes\.rb$'      | return "config/environment.rb"
  elseif f =~ '\<config/environment\.rb$' | return "config/database.yml"
  elseif f =~ '\<db/migrate/\d\d\d_'
    let num = matchstr(f,'\<db/migrate/0*\zs\d\+\ze_')-1
    return num ? s:migrationfor(num) : "db/schema.rb"
  elseif f =~ '\<application\.js$'
    return "app/helpers/application_helper.rb"
  elseif t =~ '^js\>'
    return "public/javascripts/application.js"
  elseif f =~ '\<db/schema\.rb$'
    return s:migrationfor("")
  elseif t =~ '^view\>'
    if t =~ '\<layout\>'
      let dest = fnamemodify(f,':r:s?/layouts\>??').'/layout'
    else
      let dest = f
    endif
    " Go to the helper, controller, or (mailer) model
    let helper     = fnamemodify(dest,":h:s?/views/?/helpers/?")."_helper.rb"
    let controller = fnamemodify(dest,":h:s?/views/?/controllers/?")."_controller.rb"
    let model      = fnamemodify(dest,":h:s?/views/?/models/?").".rb"
    if filereadable(RailsRoot()."/".helper)
      return helper
    elseif filereadable(RailsRoot()."/".controller)
      let jumpto = expand("%:t:r")
      return controller.'@'.jumpto
      "exe "silent! djump ".jumpto
    elseif filereadable(RailsRoot()."/".model)
      return model
    else
      return helper
    endif
  elseif t =~ '^controller-api\>'
    let api = s:sub(s:sub(f,'/controllers/','/apis/'),'_controller\.rb$','_api.rb')
    return api
  elseif t =~ '^helper\>'
    let controller = s:sub(s:sub(f,'/helpers/','/controllers/'),'_helper\.rb$','_controller.rb')
    let controller = s:sub(controller,'application_controller','application')
    return controller
  elseif t =~ '\<fixtures\>'
    let file = s:singularize(expand("%:t:r")).'_test.rb' " .expand('%:e')
    return file
  elseif f == ''
    call s:warn("No filename present")
  elseif fnamemodify(f,":e") == "rb"
    let file = fnamemodify(f,":r")
    if file =~ '_test$'
      let file = s:sub(file,'_test$','.rb')
    else
      let file = file.'_test.rb'
    endif
    if t =~ '^model\>'
      return s:sub(file,'app/models/','test/unit/')
    elseif t =~ '^controller\>'
      return s:sub(file,'app/controllers/','test/functional/')
    elseif t =~ '^test-unit\>'
      return s:sub(file,'test/unit/','app/models/')
    elseif t =~ '^test-functional\>'
      if file =~ '_api\.rb'
        return s:sub(file,'test/functional/','app/apis/')
      elseif file =~ '_controller\.rb'
        return s:sub(file,'test/functional/','app/controllers/')
      else
        return s:sub(file,'test/functional/','')
      endif
    elseif file =~ '\<vendor/.*/lib/'
      return s:sub(file,'\<vendor/.\{-\}/\zslib/','test/')
    elseif file =~ '\<vendor/.*/test/'
      return s:sub(file,'\<vendor/.\{-\}/\zstest/','lib/')
    else
      return fnamemodify(file,":t")
    endif
  else
    return ""
  endif
endfunction

function! s:Related(bang,cmd)
  let cmd = a:cmd.(a:bang?"!":"")
  let file = s:RelatedFile()
  if file != ""
    call s:findedit(cmd,file)
  else
    call s:warn("No related file is defined")
  endif
endfunction

function! s:RelatedFile()
  let f = RailsFilePath()
  let t = RailsFileType()
  if s:getopt("related","l") != ""
    return s:getopt("related","l")
  elseif t =~ '^\%(controller\|model-mailer\)\>' && s:lastmethod() != ""
    return s:sub(s:sub(s:sub(f,'/application\.rb$','/shared_controller.rb'),'/\%(controllers\|models\)/','/views/'),'\%(_controller\)\=\.rb$','/'.s:lastmethod())
  elseif s:getopt("related","b") != ""
    return s:getopt("related","b")
  elseif f =~ '\<config/environments/'
    return "config/environment.rb"
  elseif f == 'README'
    return "config/database.yml"
  elseif f =~ '\<config/database\.yml$'   | return "config/environment.rb"
  elseif f =~ '\<config/routes\.rb$'      | return "config/database.yml"
  elseif f =~ '\<config/environment\.rb$' | return "config/routes.rb"
  elseif f =~ '\<db/migrate/\d\d\d_'
    let num = matchstr(f,'\<db/migrate/0*\zs\d\+\ze_')+1
    let migr = s:migrationfor(num)
    return migr == '' ? "db/schema.rb" : migr
  elseif t =~ '^test\>' && f =~ '\<test/\w\+/'
    let target = s:sub(f,'.*\<test/\w\+/','test/mocks/test/')
    let target = s:sub(target,'_test\.rb$','.rb')
    return target
  elseif f =~ '\<application\.js$'
    return "app/helpers/application_helper.rb"
  elseif t =~ '^js\>'
    return "public/javascripts/application.js"
  elseif t =~ '^view-layout\>'
    return s:sub(s:sub(s:sub(f,'/views/','/controllers/'),'/layouts/\(\k\+\)\..*$','/\1_controller.rb'),'application_controller\.rb$','application.rb')
  elseif t=~ '^view-partial\>'
    call s:warn("No related file is defined")
  elseif t =~ '^view\>'
    let controller = s:sub(s:sub(f,'/views/','/controllers/'),'/\(\k\+\)\..*$','_controller.rb@\1')
    let model      = s:sub(s:sub(f,'/views/','/models/'),'/\(\k\+\)\..*$','.rb@\1')
    if filereadable(s:sub(controller,'@.\{-\}$',''))
      return controller
    elseif filereadable(s:sub(model,'@.\{-\}$','')) || model =~ '_mailer\.rb@'
      return model
    else
      return controller
    endif
  elseif t =~ '^controller-api\>'
    return s:sub(s:sub(f,'/controllers/','/apis/'),'_controller\.rb$','_api.rb')
  elseif t =~ '^controller\>'
    if s:lastmethod() != ""
      return s:sub(s:sub(s:sub(f,'/application\.rb$','/shared_controller.rb'),'/controllers/','/views/'),'_controller\.rb$','/'.s:lastmethod())
    else
      return s:sub(s:sub(f,'/controllers/','/helpers/'),'\%(_controller\)\=\.rb$','_helper.rb')
    endif
  elseif t=~ '^helper\>'
      return s:sub(s:sub(f,'/helpers/','/views/layouts/'),'\%(_helper\)\=\.rb$','')
  elseif t =~ '^model-arb\=\>'
    "call s:migrationEdit(0,cmd,'create_'.s:pluralize(expand('%:t:r')))
    return s:migrationfor('create_'.s:pluralize(expand('%:t:r')))
  elseif t =~ '^model-aro\>'
    return s:sub(f,'_observer\.rb$','.rb')
  elseif t =~ '^api\>'
    return s:sub(s:sub(f,'/apis/','/controllers/'),'_api\.rb$','_controller.rb')
  elseif f =~ '\<db/schema\.rb$'
    return s:migrationfor(1)
  else
    call s:warn("No related file is defined")
    return ""
  endif
endfunction

" }}}1
" Partials {{{1

function! s:Partial(bang,...) range abort
  if a:0 == 0 || a:0 > 1
    return s:error("Incorrect number of arguments")
  endif
  if a:1 =~ '[^a-z0-9_/]'
    return s:error("Invalid partial name")
  endif
  let file = a:1
  let first = a:firstline
  let last = a:lastline
  let range = first.",".last
  if RailsFileType() =~ '^view-layout\>'
    if RailsFilePath() =~ '\<app/views/layouts/application\>'
      let curdir = 'app/views/shared'
      if file !~ '/'
        let file = "shared/" .file
      endif
    else
      let curdir = s:sub(RailsFilePath(),'.*\<app/views/layouts/\(.*\)\%(\.\w*\)$','app/views/\1')
    endif
  else
    let curdir = fnamemodify(RailsFilePath(),':h')
  endif
  let curdir = RailsRoot()."/".curdir
  let dir = fnamemodify(file,":h")
  let fname = fnamemodify(file,":t")
  if fnamemodify(fname,":e") == ""
    let name = fname
    let fname = fname.".".expand("%:e")
  else
    let name = fnamemodify(name,":r")
  endif
  let var = "@".name
  let collection = ""
  if dir =~ '^/'
    let out = (RailsRoot()).dir."/_".fname
  elseif dir == ""
    let out = (curdir)."/_".fname
  elseif isdirectory(curdir."/".dir)
    let out = (curdir)."/".dir."/_".fname
  else
    let out = (RailsRoot())."/app/views/".dir."/_".fname
  endif
  if filereadable(out)
    let partial_warn = 1
    "echoerr "Partial exists"
    "return
  endif
  if bufnr(out) > 0
    if bufloaded(out)
      return s:error("Partial already open in buffer ".bufnr(out))
    else
      exe "bwipeout ".bufnr(out)
    endif
  endif
  " No tabs, they'll just complicate things
  if expand("%:e") == "rhtml"
    let erub1 = '<%\s*'
    let erub2 = '\s*-\=%>'
  else
    let erub1 = ''
    let erub2 = ''
  endif
  let spaces = matchstr(getline(first),"^ *")
  if getline(last+1) =~ '^\s*'.erub1.'end'.erub2.'\s*$'
    let fspaces = matchstr(getline(last+1),"^ *")
    if getline(first-1) =~ '^'.fspaces.erub1.'for\s\+\(\k\+\)\s\+in\s\+\([^ %>]\+\)'.erub2.'\s*$'
      let collection = s:sub(getline(first-1),'^'.fspaces.erub1.'for\s\+\(\k\+\)\s\+in\s\+\([^ >]\+\)'.erub2.'\s*$','\1>\2')
    elseif getline(first-1) =~ '^'.fspaces.erub1.'\([^ %>]\+\)\.each\s\+do\s\+|\s*\(\k\+\)\s*|'.erub2.'\s*$'
      let collection = s:sub(getline(first-1),'^'.fspaces.erub1.'\([^ %>]\+\)\.each\s\+do\s\+|\s*\(\k\+\)\s*|'.erub2.'\s*$','\2>\1')
    endif
    if collection != ''
      let var = matchstr(collection,'^\k\+')
      let collection = s:sub(collection,'^\k\+>','')
      let first = first - 1
      let last = last + 1
    endif
  else
    let fspaces = spaces
  endif
  "silent exe range."write ".out
  let renderstr = "render :partial => '".fnamemodify(file,":r")."'"
  if collection != ""
    let renderstr = renderstr.", :collection => ".collection
  elseif "@".name != var
    let renderstr = renderstr.", :object => ".var
  endif
  if expand("%:e") == "rhtml"
    let renderstr = "<%= ".renderstr." %>"
  endif
  let buf = @@
  silent exe range."yank"
  let partial = @@
  let @@ = buf
  silent exe "norm :".first.",".last."change\<CR>".fspaces.renderstr."\<CR>.\<CR>"
  if renderstr =~ '<%'
    norm ^6w
  else
    norm ^5w
  endif
  let ft = &ft
  if &hidden
    enew
  else
    new
  endif
  exe "silent file ".s:escarg(fnamemodify(out,':~:.'))
  let &ft = ft
  let @@ = partial
  silent put
  0delete
  let @@ = buf
  if spaces != ""
    silent! exe '%sub/^'.spaces.'//'
  endif
  silent! exe '%sub?\%(\w\|[@:]\)\@<!'.var.'\>?'.name.'?g'
  1
  call s:Detect(out)
  if exists("l:partial_warn")
    call s:warn("Warning: partial exists!")
  endif
endfunction

" }}}1
" Migration Inversion {{{1

function! s:mkeep(str)
  " Things to keep (like comments) from a migration statement
  return matchstr(a:str,' #[^{].*')
endfunction

function! s:mextargs(str,num)
  if a:str =~ '^\s*\w\+\s*('
    return s:sub(matchstr(a:str,'^\s*\w\+\s*\zs(\%([^,)]\+[,)]\)\{,'.a:num.'\}'),',$',')')
  else
    return s:sub(s:sub(matchstr(a:str,'\w\+\>\zs\s*\%([^,){ ]*[, ]*\)\{,'.a:num.'\}'),'[, ]*$',''),'^\s\+',' ')
  endif
endfunction

function! s:spc(line)
  return matchstr(a:line,'^\s*')
endfunction

function! s:invertrange(beg,end)
  let str = ""
  let lnum = a:beg
  while lnum <= a:end
    let line = getline(lnum)
    let add = ""
    if line == ''
      let add = ' '
    elseif line =~ '^\s*\(#[^{].*\)\=$'
      let add = line
    elseif line =~ '\<create_table\>'
      "let add = s:sub(line,'\<create_table\>\s*(\=\s*\([^,){ ]*\).*','drop_table \1').s:mkeep(line)
      let add = s:spc(line)."drop_table".s:mextargs(line,1).s:mkeep(line)
      let lnum = s:endof(lnum)
    elseif line =~ '\<drop_table\>'
      let add = s:sub(line,'\<drop_table\>\s*(\=\s*\([^,){ ]*\).*','create_table \1 do |t|'."\n".matchstr(line,'^\s*').'end').s:mkeep(line)
    elseif line =~ '\<add_column\>'
      let add = s:spc(line).'remove_column'.s:mextargs(line,2).s:mkeep(line)
    elseif line =~ '\<remove_column\>'
      let add = s:sub(line,'\<remove_column\>','add_column')
    elseif line =~ '\<add_index\>'
      let add = s:spc(line).'remove_index'.s:mextargs(line,1)
      let mat = matchstr(line,':name\s*=>\s*\zs[^ ,)]*')
      if mat != ''
        let add = s:sub(add,')\=$',', :name => '.mat.'&')
      else
        let mat = matchstr(line,'\<add_index\>[^,]*,\s*\zs\%(\[[^]]*\]\|[:"'."'".']\w*["'."'".']\=\)')
        if mat != ''
          let add = s:sub(add,')\=$',', :columns => '.mat.'&')
        endif
      endif
      let add = add.s:mkeep(line)
    elseif line =~ '\<remove_index\>'
      let add = s:sub(s:sub(line,'\<remove_index','add_index'),':columns\s*=>\s*','')
    elseif line =~ '\<rename_\%(table\|column\)\>'
      let add = s:sub(line,'\<rename_\%(table\s*(\=\s*\|column\s*(\=\s*[^,]*,\s*\)\zs\([^,]*\)\(,\s*\)\([^,]*\)','\3\2\1')
    elseif line =~ '\<change_column\>'
      let add = s:spc(line).'change_column'.s:mextargs(line,2).s:mkeep(line)
    elseif line =~ '\<change_column_default\>'
      let add = s:spc(line).'change_column_default'.s:mextargs(line,2).s:mkeep(line)
    elseif line =~ '\.update_all(\(["'."'".']\).*\1)$' || line =~ '\.update_all \(["'."'".']\).*\1$'
      " .update_all('a = b') => .update_all('b = a')
      let pre = matchstr(line,'^.*\.update_all[( ][}'."'".']')
      let post = matchstr(line,'["'."'".'])\=$')
      let mat = strpart(line,strlen(pre),strlen(line)-strlen(pre)-strlen(post))
      let mat = s:gsub(','.mat.',',',\s*\([^,=]\{-\}\)\(\s*=\s*\)\([^,=]\{-\}\)\s*,','\3\2\1')
      let add = pre.s:sub(s:sub(mat,'^,',''),',$','').post
    elseif line =~ '^s\*\%(if\|unless\|while\|until\|for\)\>'
      let lnum = s:endof(lnum)
    endif
    if lnum == 0
      return -1
    endif
    if add == ""
      let add = s:sub(line,'^\s*\zs.*','raise ActiveRecord::IrreversableMigration')
    elseif add == " "
      let add = ""
    endif
    let str = add."\n".str
    let lnum = lnum + 1
  endwhile
  let str = s:gsub(str,'\(\s*raise ActiveRecord::IrreversableMigration\n\)\+','\1')
  return str
endfunction

function! s:Invert(bang)
  let err = "Could not parse method"
  let src = "up"
  let dst = "down"
  let beg = search('\%('.&l:define.'\).*'.src.'\>',"w")
  let end = s:endof(beg)
  if beg + 1 == end
    let src = "down"
    let dst = "up"
    let beg = search('\%('.&l:define.'\).*'.src.'\>',"w")
    let end = s:endof(beg)
  endif
  if !beg || !end
    return s:error(err)
  endif
  let str = s:invertrange(beg+1,end-1)
  if str == -1
    return s:error(err)
  endif
  let beg = search('\%('.&l:define.'\).*'.dst.'\>',"w")
  let end = s:endof(beg)
  if !beg || !end
    return s:error(err)
  endif
  if beg + 1 < end
    exe (beg+1).",".(end-1)."delete _"
  endif
  if str != ""
    let reg_keep = @"
    let @" = str
    exe beg."put"
    let @" = reg_keep
  endif
endfunction

" }}}1
" Syntax {{{1

function! s:BufSyntax()
  if (!exists("g:rails_syntax") || g:rails_syntax)
    let t = RailsFileType()
    if !exists("s:rails_view_helpers")
      if g:rails_expensive
        let s:rails_view_helpers = s:rubyeval('require %{action_view}; puts ActionView::Helpers.constants.grep(/Helper$/).collect {|c|ActionView::Helpers.const_get c}.collect {|c| c.public_instance_methods(false)}.flatten.sort.uniq.reject {|m| m =~ /[=?]$/}.join(%{ })',"link_to")
      else
        let s:rails_view_helpers = "link_to"
      endif
    endif
    "let g:rails_view_helpers = s:rails_view_helpers
    let rails_view_helpers = '+\.\@<!\<\('.s:gsub(s:rails_view_helpers,'\s\+','\\|').'\)\>+'
    if &syntax == 'ruby'
      syn keyword rubyRailsMethod breakpoint
      if t != ''
        syn match rubyRailsError ':order_by\>'
      endif
      if t == ''
        syn keyword rubyRailsMethod params request response session headers template cookies flash
      endif
      if t =~ '^api\>'
        syn keyword rubyRailsAPIMethod api_method inflect_names
      endif
      if t =~ '^model$' || t =~ '^model-arb\=\>'
        syn keyword rubyRailsARMethod acts_as_list acts_as_nested_set acts_as_tree composed_of serialize
        syn keyword rubyRailsARAssociationMethod belongs_to has_one has_many has_and_belongs_to_many
        "syn match rubyRailsARCallbackMethod '\<\(before\|after\)_\(create\|destroy\|save\|update\|validation\|validation_on_create\|validation_on_update\)\>'
        syn keyword rubyRailsARCallbackMethod before_create before_destroy before_save before_update before_validation before_validation_on_create before_validation_on_update
        syn keyword rubyRailsARCallbackMethod after_create after_destroy after_save after_update after_validation after_validation_on_create after_validation_on_update
        syn keyword rubyRailsARClassMethod attr_accessible attr_protected establish_connection set_inheritance_column set_locking_column set_primary_key set_sequence_name set_table_name
        "syn keyword rubyRailsARCallbackMethod after_find after_initialize
        syn keyword rubyRailsARValidationMethod validate validate_on_create validate_on_update validates_acceptance_of validates_associated validates_confirmation_of validates_each validates_exclusion_of validates_format_of validates_inclusion_of validates_length_of validates_numericality_of validates_presence_of validates_size_of validates_uniqueness_of
        syn keyword rubyRailsMethod logger
      endif
      if t =~ '^model-aro\>'
        syn keyword rubyRailsARMethod observe
      endif
      if t =~ '^model-mailer\>'
        syn keyword rubyRailsMethod logger
        " Misnomer but who cares
        syn keyword rubyRailsControllerMethod helper helper_attr helper_method
      endif
      if t =~ '^controller\>' || t =~ '^view\>' || t=~ '^helper\>'
        syn keyword rubyRailsMethod params request response session headers template cookies flash
        syn match rubyRailsError '[@:]\@<!@\%(params\|request\|response\|session\|headers\|template\|cookies\|flash\)\>'
        syn match rubyRailsError '\<\%(render_partial\|puts\)\>'
        syn keyword rubyRailsRenderMethod render render_component
        syn keyword rubyRailsMethod logger
      endif
      if t =~ '^helper\>' || t=~ '^view\>'
        "exe "syn match rubyRailsHelperMethod ".rails_view_helpers
        exe "syn keyword rubyRailsHelperMethod ".s:sub(s:rails_view_helpers,'\<select\s\+','')
        syn match rubyRailsHelperMethod '\<select\>\%(\s*{\|\s*do\>\|\s*(\=\s*&\)\@!'
      elseif t =~ '^controller\>'
        syn keyword rubyRailsControllerMethod helper helper_attr helper_method filter layout url_for scaffold observer service model serialize
        syn match rubyRailsControllerDeprecatedMethod '\<render_\%(action\|text\|file\|template\|nothing\|without_layout\)\>'
        syn keyword rubyRailsRenderMethod render_to_string render_component_as_string redirect_to
        syn keyword rubyRailsFilterMethod before_filter append_before_filter prepend_before_filter after_filter append_after_filter prepend_after_filter around_filter append_around_filter prepend_around_filter skip_before_filter skip_after_filter
        syn keyword rubyRailsFilterMethod verify
      endif
      if t =~ '^\%(db-\)\=\%(migration\|schema\)\>'
        syn keyword rubyRailsMigrationMethod create_table drop_table rename_table add_column rename_column change_column change_column_default remove_column add_index remove_index
      endif
      if t =~ '^test\>'
        syn keyword rubyRailsTestMethod add_assertion assert assert_block assert_equal assert_in_delta assert_instance_of assert_kind_of assert_match assert_nil assert_no_match assert_not_equal assert_not_nil assert_not_same assert_nothing_raised assert_nothing_thrown assert_operator assert_raise assert_respond_to assert_same assert_send assert_throws flunk fixtures use_transactional_fixtures use_instantiated_fixtures
        if t !~ '^test-unit\>'
          syn match   rubyRailsTestControllerMethod  '\.\@<!\<\%(get\|post\|put\|delete\|head\|process\)\>'
          syn keyword rubyRailsTestControllerMethod assert_response assert_redirected_to assert_template assert_recognizes assert_generates assert_routing assert_tag assert_no_tag assert_dom_equal assert_dom_not_equal assert_valid
        endif
      endif
      if t =~ '^task\>'
        syn match rubyRailsRakeMethod '^\s*\zs\%(task\|file\|desc\)\>\%(\s*=\)\@!'
      endif
      if t =~ '^model-awss\>'
        syn keyword rubyRailsMethod member
      endif
      syn keyword rubyRailsMethod cattr_accessor mattr_accessor
      syn keyword rubyRailsInclude require_dependency require_gem
    elseif &syntax == "eruby" " && t =~ '^view\>'
      syn match rubyRailsError ':order_by\>'
      "syn match rubyRailsError '@content_for_\w*\>'
      syn cluster erubyRailsRegions contains=erubyOneLiner,erubyBlock,erubyExpression
      "exe "syn match erubyRailsHelperMethod ".rails_view_helpers." contained containedin=@erubyRailsRegions"
        exe "syn keyword erubyRailsHelperMethod ".s:sub(s:rails_view_helpers,'\<select\s\+','')." contained containedin=@erubyRailsRegions"
        syn match erubyRailsHelperMethod '\<select\>\%(\s*{\|\s*do\>\|\s*(\=\s*&\)\@!' contained containedin=@erubyRailsRegions
      syn keyword erubyRailsMethod breakpoint logger
      syn keyword erubyRailsMethod params request response session headers template cookies flash contained containedin=@erubyRailsRegions
      syn match erubyRailsMethod '\.\@<!\<\(h\|html_escape\|u\|url_encode\)\>' contained containedin=@erubyRailsRegions
        syn keyword erubyRailsRenderMethod render render_component contained containedin=@erubyRailsRegions
      syn match rubyRailsError '[^@:]\@<!@\%(params\|request\|response\|session\|headers\|template\|cookies\|flash\)\>' contained containedin=@erubyRailsRegions
      syn match rubyRailsError '\<\%(render_partial\|puts\)\>' contained containedin=@erubyRailsRegions
    elseif &syntax == "yaml"
      " Modeled after syntax/eruby.vim
      unlet b:current_syntax
      let g:main_syntax = 'eruby'
      syn include @rubyTop syntax/ruby.vim
      unlet g:main_syntax
      syn cluster erubyRegions contains=yamlRailsOneLiner,yamlRailsBlock,yamlRailsExpression,yamlRailsComment
      syn cluster erubyRailsRegions contains=yamlRailsOneLiner,yamlRailsBlock,yamlRailsExpression
      syn region  yamlRailsOneLiner   matchgroup=yamlRailsDelimiter start="^%%\@!" end="$"  contains=@rubyRailsTop	containedin=ALLBUT,@yamlRailsRegions keepend oneline
      syn region  yamlRailsBlock      matchgroup=yamlRailsDelimiter start="<%%\@!" end="%>" contains=@rubyTop		containedin=ALLBUT,@yamlRailsRegions
      syn region  yamlRailsExpression matchgroup=yamlRailsDelimiter start="<%="    end="%>" contains=@rubyTop		containedin=ALLBUT,@yamlRailsRegions
      syn region  yamlRailsComment    matchgroup=yamlRailsDelimiter start="<%#"    end="%>" contains=rubyTodo,@Spell	containedin=ALLBUT,@yamlRailsRegions keepend
        syn match yamlRailsMethod '\.\@<!\<\(h\|html_escape\|u\|url_encode\)\>' containedin=@erubyRailsRegions
      let b:current_syntax = "yaml"
    endif
  endif
  call s:HiDefaults()
endfunction

function! s:HiDefaults()
  hi def link rubyRailsAPIMethod              rubyRailsMethod
  hi def link rubyRailsARAssociationMethod    rubyRailsARMethod
  hi def link rubyRailsARCallbackMethod       rubyRailsARMethod
  hi def link rubyRailsARClassMethod          rubyRailsARMethod
  hi def link rubyRailsARValidationMethod     rubyRailsARMethod
  hi def link rubyRailsARMethod               rubyRailsMethod
  hi def link rubyRailsRenderMethod           rubyRailsMethod
  hi def link rubyRailsHelperMethod           rubyRailsMethod
  hi def link rubyRailsMigrationMethod        rubyRailsMethod
  hi def link rubyRailsControllerMethod       rubyRailsMethod
  hi def link rubyRailsControllerDeprecatedMethod rubyRailsError
  hi def link rubyRailsFilterMethod           rubyRailsMethod
  hi def link rubyRailsTestControllerMethod   rubyRailsTestMethod
  hi def link rubyRailsTestMethod             rubyRailsMethod
  hi def link rubyRailsRakeMethod             rubyRailsMethod
  hi def link rubyRailsMethod                 railsMethod
  hi def link rubyRailsError                  rubyError
  hi def link rubyRailsInclude                rubyInclude
  hi def link railsMethod                     Function
  hi def link erubyRailsHelperMethod          erubyRailsMethod
  hi def link erubyRailsRenderMethod          erubyRailsMethod
  hi def link erubyRailsMethod                railsMethod
  hi def link yamlRailsDelimiter              Delimiter
  hi def link yamlRailsMethod                 railsMethod
  hi def link yamlRailsComment                Comment
endfunction

function! s:RailslogSyntax()
  syn match   railslogRender      '^\s*\<\%(Processing\|Rendering\|Rendered\|Redirected\|Completed\)\>'
  syn match   railslogComment     '^\s*# .*'
  syn match   railslogModel       '^\s*\u\%(\w\|:\)* \%(Load\%( Including Associations\| IDs For Limited Eager Loading\)\=\|Columns\|Count\|Update\|Destroy\|Delete all\)\>' skipwhite nextgroup=railslogModelNum
  syn match   railslogModel       '^\s*SQL\>' skipwhite nextgroup=railslogModelNum
  syn region  railslogModelNum    start='(' end=')' contains=railslogNumber contained skipwhite nextgroup=railslogSQL
  syn match   railslogSQL         '\u.*$' contained
  " Destroy generates multiline SQL, ugh
  syn match   railslogSQL         '^ WHERE .*$'
  syn match   railslogNumber      '\<\d\+\>%'
  syn match   railslogNumber      '[ (]\@<=\<\d\+\.\d\+\>'
  syn region  railslogString      start='"' skip='\\"' end='"' oneline contained
  syn region  railslogHash        start='{' end='}' oneline contains=railslogHash,railslogString
  syn match   railslogIP          '\<\d\{1,3\}\%(\.\d\{1,3}\)\{3\}\>'
  syn match   railslogTimestamp   '\<\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\>'
  syn match   railslogSessionID   '\<\x\{32\}\>'
  syn match   railslogIdentifier  '^\s*\%(Session ID\|Parameters\)\ze:'
  syn match   railslogSuccess     '\<2\d\d \u[A-Za-z0-9 ]*\>'
  syn match   railslogRedirect    '\<3\d\d \u[A-Za-z0-9 ]*\>'
  syn match   railslogError       '\<[45]\d\d \u[A-Za-z0-9 ]*\>'
  syn keyword railslogHTTP        OPTIONS GET HEAD POST PUT DELETE TRACE CONNECT
  syn region  railslogStackTrace  start=":\d\+:in `\w\+'$" end="^\s*$" keepend fold
  hi def link railslogComment     Comment
  hi def link railslogRender      Keyword
  hi def link railslogModel       Type
  hi def link railslogSQL         PreProc
  hi def link railslogNumber      Number
  hi def link railslogString      String
  hi def link railslogSessionID   Constant
  hi def link railslogIdentifier  Identifier
  hi def link railslogRedirect    railslogSuccess
  hi def link railslogSuccess     Special
  hi def link railslogError       Error
  hi def link railslogHTTP        Special
endfunction

" }}}1
" Statusline {{{1

function! s:addtostatus(letter)
  if &statusline !~ 'Rails' && g:rails_statusline
    let   &statusline=substitute(&statusline,'\C%'.tolower(a:letter),'%'.tolower(a:letter).'%{RailsStatusline()}','')
    if &statusline !~ 'Rails'
      let &statusline=substitute(&statusline,'\C%'.toupper(a:letter),'%'.toupper(a:letter).'%{RailsSTATUSLINE()}','')
    endif
  endif
endfunction

function! s:InitStatusline()
  if &statusline == '' && g:rails_statusline
    let &statusline='%<%f %h%m%r%='
    if &ruler
      let &statusline = &statusline . '%-16( %l,%c-%v %)%P'
    endif
  endif
  if &statusline !~ 'Rails' && g:rails_statusline
    call s:addtostatus('y')
    call s:addtostatus('r')
    call s:addtostatus('m')
    call s:addtostatus('w')
    call s:addtostatus('h')
    if &statusline !~ 'Rails'
      let &statusline=substitute(&statusline,'%=','%{RailsStatusline()}%=','')
    endif
    if &statusline !~ 'Rails' && &statusline != ''
      let &statusline=&statusline.'%{RailsStatusline()}'
    endif
  endif
endfunction

function! RailsStatusline()
  if exists("b:rails_root")
    let t = RailsFileType()
    if t != ""
      return "[Rails-".t."]"
    else
      return "[Rails]"
    endif
  else
    return ""
  endif
endfunction

function! RailsSTATUSLINE()
  if exists("b:rails_root")
    let t = RailsFileType()
    if t != ""
      return ",RAILS-".toupper(t)
    else
      return ",RAILS"
    endif
  else
    return ""
  endif
endfunction

" }}}1
" Mappings {{{1

function! s:leaderunmap(key,...)
  silent! exe "unmap <buffer> ".g:rails_leader.a:key
endfunction

function! s:leadermap(key,mapping)
  if g:rails_leader != ''
    exe "map <buffer> ".g:rails_leader.a:key." ".a:mapping
  endif
endfunction

function! s:BufMappings()
  map <buffer> <silent> <Plug>RailsAlternate  :A<CR>
  map <buffer> <silent> <Plug>RailsRelated    :R<CR>
  map <buffer> <silent> <Plug>RailsFind       :REfind<CR>
  map <buffer> <silent> <Plug>RailsSplitFind  :RSfind<CR>
  map <buffer> <silent> <Plug>RailsVSplitFind :RVfind<CR>
  map <buffer> <silent> <Plug>RailsTabFind    :RTfind<CR>
  if g:rails_mappings
    " Unmap so hasmapto doesn't get confused by stale bindings
    call s:leaderunmap('f','<Plug>RailsFind')
    call s:leaderunmap('a','<Plug>RailsAlternate')
    call s:leaderunmap('r','<Plug>RailsRelated')
    call s:leaderunmap('m',':Rake<CR>')
    silent! unmap <buffer> <Plug>RailsMagicM
    if !hasmapto("<Plug>RailsFind")
      nmap <buffer> gf              <Plug>RailsFind
    endif
    if !hasmapto("<Plug>RailsSplitFind")
      nmap <buffer> <C-W>f          <Plug>RailsSplitFind
    endif
    if !hasmapto("<Plug>RailsTabFind")
      nmap <buffer> <C-W>gf         <Plug>RailsTabFind
    endif
    if !hasmapto("<Plug>RailsAlternate")
      nmap <buffer> [f              <Plug>RailsAlternate
    endif
    if !hasmapto("<Plug>RailsRelated")
      nmap <buffer> ]f              <Plug>RailsRelated
    endif
    if exists("$CREAM")
      imap <buffer> <C-CR> <C-O><Plug>RailsFind
      " Are these a good idea?
      imap <buffer> <M-[>  <C-O><Plug>RailsAlternate
      imap <buffer> <M-]>  <C-O><Plug>RailsRelated
    endif
    map <buffer> <silent> <Plug>RailsMagicM    :echoerr "Obsolete: Use <Plug>RailsRelated instead"<CR>
    let g:rails_leader = "<LocalLeader>r"
    call s:leadermap('f','<Plug>RailsFind')
    call s:leadermap('a',':A<CR>')
    call s:leadermap('r',':R<CR>')
    call s:leadermap('m',':Rake<CR>')
  endif
endfunction

" }}}1
" Menus {{{1

function! s:CreateMenus() abort
  if exists("g:rails_installed_menu") && g:rails_installed_menu != ""
    exe "aunmenu ".s:gsub(g:rails_installed_menu,'&','')
    unlet g:rails_installed_menu
  endif
  if has("menu") && (exists("g:did_install_default_menus") || exists("$CREAM")) && g:rails_menu
    if g:rails_menu > 1
      let g:rails_installed_menu = '&Rails'
    else
      let g:rails_installed_menu = '&Plugin.&Rails'
    endif
    if exists("$CREAM")
      let menucmd = '87anoremenu <script> '
      exe menucmd.g:rails_installed_menu.'.&Related\ file\	:R\ /\ Alt+] :R<CR>'
      exe menucmd.g:rails_installed_menu.'.&Alternate\ file\	:A\ /\ Alt+[ :A<CR>'
      exe menucmd.g:rails_installed_menu.'.&File\ under\ cursor\	Ctrl+Enter :Rfind<CR>'
    else
      let menucmd = 'anoremenu <script> '
      "exe menucmd.g:rails_installed_menu.'.&Related\ file\	:R :R<CR>'
      "exe menucmd.g:rails_installed_menu.'.&Alternate\ file\	:A :A<CR>'
      exe menucmd.g:rails_installed_menu.'.&Related\ file\	:R\ /\ ]f :R<CR>'
      exe menucmd.g:rails_installed_menu.'.&Alternate\ file\	:A\ /\ [f :A<CR>'
      exe menucmd.g:rails_installed_menu.'.&File\ under\ cursor\	gf :Rfind<CR>'
    endif
    exe menucmd.g:rails_installed_menu.'.&Other\ files.Application\ &Controller :find app/controllers/application.rb<CR>'
    exe menucmd.g:rails_installed_menu.'.&Other\ files.Application\ &Helper :find app/helpers/application_helper.rb<CR>'
    exe menucmd.g:rails_installed_menu.'.&Other\ files.Application\ &Javascript :find public/javascripts/application.js<CR>'
    exe menucmd.g:rails_installed_menu.'.&Other\ files.Application\ &Layout :Rlayout application<CR>'
    exe menucmd.g:rails_installed_menu.'.&Other\ files.Application\ &README :find doc/README_FOR_APP<CR>'
    exe menucmd.g:rails_installed_menu.'.&Other\ files.&Environment :find config/environment.rb<CR>'
    exe menucmd.g:rails_installed_menu.'.&Other\ files.&Database\ Configuration :find config/database.yml<CR>'
    exe menucmd.g:rails_installed_menu.'.&Other\ files.Database\ &Schema :call <SID>findschema()<CR>'
    exe menucmd.g:rails_installed_menu.'.&Other\ files.R&outes :find config/routes.rb<CR>'
    exe menucmd.g:rails_installed_menu.'.&Other\ files.&Test\ Helper :find test/test_helper.rb<CR>'
    exe menucmd.g:rails_installed_menu.'.-FSep- :'
    exe menucmd.g:rails_installed_menu.'.Ra&ke\	:Rake :Rake<CR>'
    let tasks = s:raketasks()
    while tasks != ''
      let task = matchstr(tasks,'.\{-\}\ze\%(\n\|$\)')
      let tasks = s:sub(tasks,'.\{-\}\%(\n\|$\)','')
      exe menucmd.g:rails_installed_menu.'.Rake\ &tasks\	:Rake.'.s:sub(s:sub(task,'^[^:]*$','&:all'),':','.').' :Rake '.task.'<CR>'
    endwhile
    let tasks = s:generators()
    while tasks != ''
      let task = matchstr(tasks,'.\{-\}\ze\%(\n\|$\)')
      let tasks = s:sub(tasks,'.\{-\}\%(\n\|$\)','')
      exe menucmd.'<silent> '.g:rails_installed_menu.'.&Generate\	:Rgen.'.s:gsub(task,'_','\\ ').' :call <SID>menuprompt("Rgenerate '.task.'","Arguments for script/generate '.task.': ")<CR>'
      exe menucmd.'<silent> '.g:rails_installed_menu.'.&Destroy\	:Rdestroy.'.s:gsub(task,'_','\\ ').' :call <SID>menuprompt("Rdestroy '.task.'","Arguments for script/destroy '.task.': ")<CR>'
    endwhile
    exe menucmd.g:rails_installed_menu.'.&Server\	:Rserver.&Start\	:Rserver :Rserver<CR>'
    exe menucmd.g:rails_installed_menu.'.&Server\	:Rserver.&Force\ start\	:Rserver! :Rserver!<CR>'
    exe menucmd.g:rails_installed_menu.'.&Server\	:Rserver.&Kill\	:Rserver!\ - :Rserver! -<CR>'
    exe menucmd.'<silent> '.g:rails_installed_menu.'.&Evaluate\ Ruby\.\.\.\	:Rp :call <SID>menuprompt("Rp","Code to execute and output: ")<CR>'
    exe menucmd.g:rails_installed_menu.'.&Console\	:Rconsole :Rconsole<CR>'
    exe menucmd.g:rails_installed_menu.'.&Breakpointer\	:Rbreak :Rbreakpointer<CR>'
    exe menucmd.g:rails_installed_menu.'.&Preview\	:Rpreview :Rpreview<CR>'
    exe menucmd.g:rails_installed_menu.'.&Log\ file\	:Rlog :Rlog<CR>'
    exe s:sub(menucmd,'anoremenu','vnoremenu').' <silent> '.g:rails_installed_menu.'.E&xtract\ as\ partial\	:Rextract :call <SID>menuprompt("'."'".'<,'."'".'>Rextract","Partial name (e.g., template or /controller/template): ")<CR>'
    exe menucmd.g:rails_installed_menu.'.&Migration\ writer\	:Rinvert :Rinvert<CR>'
    exe menucmd.'         '.g:rails_installed_menu.'.-HSep- :'
    exe menucmd.'<silent> '.g:rails_installed_menu.'.&Help\	:help\ rails :call <SID>prephelp()<Bar>help rails<CR>'
    exe menucmd.'<silent> '.g:rails_installed_menu.'.Abo&ut\	 :call <SID>prephelp()<Bar>help rails-about<CR>'
    let g:rails_did_menus = 1
    call s:menuBufLeave()
    if exists("b:rails_root")
      call s:menuBufEnter()
    endif
  endif
endfunction

function! s:menuBufEnter()
  if exists("g:rails_installed_menu") && g:rails_installed_menu != ""
    let menu = s:gsub(g:rails_installed_menu,'&','')
    exe 'amenu enable '.menu.'.*'
    if RailsFileType() !~ '^view\>'
      exe 'vmenu disable '.menu.'.Extract\ as\ partial'
    endif
    if RailsFileType() !~ '^\%(db-\)\=migration$' || RailsFilePath() =~ '\<db/schema\.rb$'
      exe 'amenu disable '.menu.'.Migration\ writer'
    endif
  endif
endfunction

function! s:menuBufLeave()
  if exists("g:rails_installed_menu") && g:rails_installed_menu != ""
    let menu = s:gsub(g:rails_installed_menu,'&','')
    exe 'amenu disable '.menu.'.*'
    exe 'amenu enable  '.menu.'.Help\	'
    exe 'amenu enable  '.menu.'.About\	'
  endif
endfunction

function! s:menuprompt(vimcmd,prompt)
  let res = inputdialog(a:prompt,'','!!!')
  if res == '!!!'
    return ""
  endif
  exe a:vimcmd." ".res
endfunction

function! s:prephelp()
  let fn = fnamemodify(s:file,':h:h').'/doc/'
  if filereadable(fn.'rails.txt')
    if !filereadable(fn.'tags') || getftime(fn.'tags') <= getftime(fn.'rails.txt')
      silent! exe "helptags ".s:escarg(fn)
    endif
  endif
endfunction

function! s:findschema()
  if filereadable(RailsRoot()."/db/schema.rb")
    exe "edit ".s:ra()."/db/schema.rb"
  elseif filereadable(RailsRoot()."/db/".s:environment()."_structure.sql")
    exe "edit ".s:ra()."/db/".s:environment()."_structure.sql"
  else
    return s:error("Schema not found: try :Rake db:schema:dump")
  endif
endfunction

" }}}1
" Balloons {{{1

function! RailsBalloonexpr()
  if executable('ri')
    let line = getline(v:beval_lnum)
    let b = matchstr(strpart(line,0,v:beval_col),'\%(\w\|[:.]\)*$')
    let a = s:gsub(matchstr(strpart(line,v:beval_col),'^\w*\%([?!]\|\s*=\)\?'),'\s\+','')
    let str = b.a
    let before = strpart(line,0,v:beval_col-strlen(b))
    let after  = strpart(line,v:beval_col+strlen(a))
    if str =~ '^\.'
      let str = s:gsub(str,'^\.','#')
      if before =~ '\]\s*$'
        let str = 'Array'.str
      elseif before =~ '}\s*$'
        let str = 'Hash'.str
      elseif before =~ "[\"'`]\\s*$" || before =~ '\$\d\+\s*$'
        let str = 'String'.str
      elseif before =~ '\$\d\+\.\d\+\s*$'
        let str = 'Float'.str
      elseif before =~ '\$\d\+\s*$'
        let str = 'Integer'.str
      elseif before =~ '/\s*$'
        let str = 'Regexp'.str
      else
        let str = s:sub(str,'^#','.')
      endif
    endif
    let str = s:sub(str,'.*\.\s*to_f\s*\.\s*','Float#')
    let str = s:sub(str,'.*\.\s*to_i\%(nt\)\=\s*\.\s*','Integer#')
    let str = s:sub(str,'.*\.\s*to_s\%(tr\)\=\s*\.\s*','String#')
    let str = s:sub(str,'.*\.\s*to_sym\s*\.\s*','Symbol#')
    let str = s:sub(str,'.*\.\s*to_a\%(ry\)\=\s*\.\s*','Array#')
    let str = s:sub(str,'.*\.\s*to_proc\s*\.\s*','Proc#')
    if str !~ '^\u'
      return ""
    endif
    silent! let res = s:sub(system("ri -f simple -T ".s:rquote(str)),'\n$','')
    if res =~ '^Nothing known about'
      return ''
    endif
    return res
  else
    return ""
  endif
endfunction

" }}}1
" Project {{{1

function! s:Project(bang,arg)
  let rr = RailsRoot()
  exe "Project ".a:arg
  let line = search('^[^ =]*="'.s:gsub(rr,'[\/]','[\\/]').'"')
  let projname = s:gsub(fnamemodify(rr,':t'),'=','-') " .'_on_rails'
  if line && a:bang
    let projname = matchstr(getline('.'),'^[^=]*')
    " Most of this would be unnecessary if the project.vim author had just put
    " the newlines AFTER each project rather than before.  Ugh.
    norm zR0"_d%
    if line('.') > 2
      delete _
    endif
    if line('.') != line('$')
      .-2
    endif
    let line = 0
  elseif !line
    $
  endif
  if !line
    if line('.') > 1
      append

.
    endif
    let line = line('.')+1
    call s:NewProject(projname,rr,a:bang)
  endif
  normal! zMzo
  if search("^ app=app {","W",line+10)
    normal! zo
    exe line
  endif
  normal! 0zt
endfunction

function! s:NewProject(proj,rr,fancy)
    let line = line('.')+1
    let template = s:NewProjectTemplate(a:proj,a:rr,a:fancy)
    silent put =template
    exe line
    " Ugh. how else can I force detecting folds?
    setlocal foldmethod=manual
    norm! $%
    silent exe "doautocmd User ".s:escarg(a:rr)."/Rproject"
    let newline = line('.')
    exe line
    norm! $%
    if line('.') != newline
      call s:warn("Warning: Rproject autocommand failed to leave cursor at end of project")
    endif
    exe line
    setlocal foldmethod=marker
    setlocal nomodified
    " FIXME: make undo stop here
    if !exists("g:maplocalleader")
      silent! normal \R
    else " Needs to be tested
      exe 'silent! normal '.g:maplocalleader.'R'
    endif
endfunction

function! s:NewProjectTemplate(proj,rr,fancy)
  let str = a:proj.'="'.a:rr."\" CD=. filter=\"*\" {\n"
  let str = str." app=app {\n"
  if isdirectory(a:rr.'/app/apis')
    let str = str."  apis=apis {\n  }\n"
  endif
  let str = str."  controllers=controllers filter=\"**\" {\n  }\n"
  let str = str."  helpers=helpers filter=\"**\" {\n  }\n"
  let str = str."  models=models filter=\"**\" {\n  }\n"
  if a:fancy
    let str = str."  views=views {\n"
    let views = s:relglob(a:rr.'/app/views/','*')."\n"
    while views != ''
      let dir = matchstr(views,'^.\{-\}\ze\n')
      let views = s:sub(views,'^.\{-\}\n','')
      let str = str."   ".dir."=".dir.' glob="**" {'."\n   }\n"
    endwhile
    let str = str."  }\n"
  else
    let str = str."  views=views filter=\"**\" {\n  }\n"
  endif
  let str = str . " }\n components=components filter=\"**\" {\n }\n"
  let str = str . " config=config {\n  environments=environments {\n  }\n }\n"
  let str = str . " db=db {\n"
  if isdirectory(a:rr.'/db/migrate')
    let str = str . "  migrate=migrate {\n  }\n"
  endif
  let str = str . " }\n"
  let str = str . " lib=lib {\n  tasks=tasks {\n  }\n }\n"
  let str = str . " public=public {\n  images=images {\n  }\n  javascripts=javascripts {\n  }\n  stylesheets=stylesheets {\n  }\n }\n"
  let str = str . " test=test {\n  fixtures=fixtures filter=\"**\" {\n  }\n  functional=functional filter=\"**\" {\n  }\n"
  if isdirectory(a:rr.'/test/integration')
    let str = str . "  integration=integration filter=\"**\" {\n  }\n"
  endif
  let str = str . "  mocks=mocks filter=\"**\" {\n  }\n  unit=unit filter=\"**\" {\n  }\n }\n}\n"
  if exists("*RailsProcessProject")
    let str = call RailsProcessProject(a:rr,str)
  endif
  return str
endfunction

" }}}1
" Database {{{1

function! s:extractvar(str,arg)
  return matchstr("\n".a:str."\n",'\n'.a:arg.'=\zs.\{-\}\ze\n')
endfunction

function! s:BufDatabase(...)
  if (a:0 && a:1 > 1) || !exists("s:dbext_last_root")
    let s:dbext_last_root = '*'
  endif
  if (a:0 > 1 && a:2 != '')
    let env = a:2
  else
    let env = s:environment()
  endif
  " Crude caching mechanism
  if s:dbext_last_root != RailsRoot()
    if exists("g:loaded_dbext") && (g:rails_dbext + (a:0 ? a:1 : 0)) > 0
      " Ideally we would filter this through ERB but that could be insecure.
      " It might be possible to make use of taint checking.
      let cmdb = 'require %{yaml}; y = File.open(%q{'.RailsRoot().'/config/database.yml}) {|f| YAML::load(f)}; e = y[%{'
      let cmde = '}]; i=0; e=y[e] while e.respond_to?(:to_str) && (i+=1)<16; e.each{|k,v|puts k+%{=}+v if v}'
      let out = s:rubyeval(cmdb.env.cmde,'')
      let adapter = s:extractvar(out,'adapter')
      let s:dbext_bin = ''
      let s:dbext_integratedlogin = ''
      if adapter == 'postgresql'
        let adapter = 'pgsql'
      elseif adapter == 'sqlite3'
        let adapter = 'sqlite'
        " Does not appear to work
        let s:dbext_bin = 'sqlite3'
      elseif adapter == 'sqlserver'
        let adapter = 'sqlsrv'
      elseif adapter == 'sybase'
        let adapter = 'asa'
      elseif adapter == 'oci'
        let adapter = 'ora'
      endif
      let s:dbext_type = toupper(adapter)
      let s:dbext_user = s:extractvar(out,'username')
      let s:dbext_passwd = s:extractvar(out,'password')
      let s:dbext_dbname = s:extractvar(out,'database')
      if s:dbext_dbname != '' && s:dbext_dbname !~ '^:' && adapter =~? '^sqlite'
        let s:dbext_dbname = RailsRoot().'/'.s:dbext_dbname
      endif
      let s:dbext_profile = ''
      let s:dbext_host = s:extractvar(out,'host')
      let s:dbext_port = s:extractvar(out,'port')
      let s:dbext_dsnname = s:extractvar(out,'dsn')
      if s:dbext_host =~? '^\cDBI:'
        if s:dbext_host =~? '\c\<Trusted[_ ]Connection\s*=\s*yes\>'
          let s:dbext_integratedlogin = 1
        endif
        let s:dbext_host = matchstr(s:dbext_host,'\c\<\%(Server\|Data Source\)\s*=\s*\zs[^;]*')
      endif
      let s:dbext_last_root = RailsRoot()
    endif
  endif
  if s:dbext_last_root == RailsRoot()
    silent! let b:dbext_type    = s:dbext_type
    silent! let b:dbext_profile = s:dbext_profile
    silent! let b:dbext_bin     = s:dbext_bin
    silent! let b:dbext_user    = s:dbext_user
    silent! let b:dbext_passwd  = s:dbext_passwd
    silent! let b:dbext_dbname  = s:dbext_dbname
    silent! let b:dbext_host    = s:dbext_host
    silent! let b:dbext_port    = s:dbext_port
    silent! let b:dbext_dsnname = s:dbext_dsnname
    silent! let b:dbext_integratedlogin = s:dbext_integratedlogin
  endif
  if a:0 >= 3 && a:3 && exists(":Create")
    if exists("b:dbext_dbname") && exists("b:dbext_type") && b:dbext_type !~? 'sqlite'
      let db = b:dbext_dbname
      let b:dbext_dbname = ''
      exe "Create database ".db
      let b:dbext_dbname = db
    endif
  endif
endfunction

" }}}1
" Abbreviations {{{1

function! s:RailsSelectiveExpand(pat,good,default,...)
  if a:0 > 0
    let nd = a:1
  else
    let nd = ""
  endif
  let c = nr2char(getchar(0))
  "let good = s:gsub(a:good,'\\<Esc>',"\<Esc>")
  let good = a:good
  if c == "" " ^]
    return s:sub(good.(a:0 ? " ".a:1 : ''),'\s\+$','')
  elseif c == "\t"
    return good.(a:0 ? " ".a:1 : '')
  elseif c =~ a:pat
    return good.c.(a:0 ? a:1 : '')
  else
    return a:default.c
  endif
endfunction

function! s:DiscretionaryComma()
  let c = nr2char(getchar(0))
  if c =~ '[\r,;]'
    return c
  else
    return ",".c
  endif
endfunction

function! s:TheMagicC()
  let l = s:linepeak()
  if l =~ '\<find\s*\((\|:first,\|:all,\)' || l =~ '\<paginate\>'
    return <SID>RailsSelectiveExpand('..',':conditions => ',':c')
  elseif l =~ '\<render\s*(\=\s*:partial\s\*=>\s*'
    return <SID>RailsSelectiveExpand('..',':collection => ',':c')
  elseif RailsFileType() =~ '^model\>'
    return <SID>RailsSelectiveExpand('..',':conditions => ',':c')
  else
    return <SID>RailsSelectiveExpand('..',':controller => ',':c')
  endif
endfunction

function! s:string(str)
  if exists("*string")
    return string(a:str)
  else
    return "'" . s:gsub(a:str,"'","'.\"'\".'") . "'"
  endif
endfunction

function! s:AddSelectiveExpand(abbr,pat,expn,...)
  let expn  = s:gsub(s:gsub(a:expn        ,'[\"|]','\\&'),'<','\\<Lt>')
  let expn2 = s:gsub(s:gsub(a:0 ? a:1 : '','[\"|]','\\&'),'<','\\<Lt>')
  if a:0
    exe "inoreabbrev <buffer> <silent> ".a:abbr." <C-R>=<SID>RailsSelectiveExpand(".s:string(a:pat).",\"".expn."\",".s:string(a:abbr).",\"".expn2."\")<CR>"
  else
    exe "inoreabbrev <buffer> <silent> ".a:abbr." <C-R>=<SID>RailsSelectiveExpand(".s:string(a:pat).",\"".expn."\",".s:string(a:abbr).")<CR>"
  endif
endfunction

function! s:AddTabExpand(abbr,expn)
  call s:AddSelectiveExpand(a:abbr,'..',a:expn)
endfunction

function! s:AddBracketExpand(abbr,expn)
  call s:AddSelectiveExpand(a:abbr,'[[.]',a:expn)
endfunction

function! s:AddColonExpand(abbr,expn)
  call s:AddSelectiveExpand(a:abbr,':',a:expn)
endfunction

function! s:AddParenExpand(abbr,expn,...)
  if a:0
    call s:AddSelectiveExpand(a:abbr,'(',a:expn,a:1)
  else
    call s:AddSelectiveExpand(a:abbr,'(',a:expn,'')
  endif
endfunction

function! s:BufAbbreviations()
  command! -buffer -bar -nargs=* -bang Rabbrev :call s:Abbrev(<bang>0,<f-args>)
  " Some of these were cherry picked from the TextMate snippets
  if g:rails_abbreviations
    " Limit to the right filetypes.  But error on the liberal side
    if RailsFileType() =~ '^\(controller\|view\|helper\|test-functional\|test-integration\)\>'
      iabbr <buffer> render_partial render :partial =>
      iabbr <buffer> render_action render :action =>
      iabbr <buffer> render_text render :text =>
      iabbr <buffer> render_file render :file =>
      iabbr <buffer> render_template render :template =>
      iabbr <buffer> <silent> render_nothing render :nothing => true<C-R>=<SID>DiscretionaryComma()<CR>
      iabbr <buffer> <silent> render_without_layout render :layout => false<C-R>=<SID>DiscretionaryComma()<CR>
      Rabbrev pa[ params
      Rabbrev rq[ request
      Rabbrev rs[ response
      Rabbrev se[ session
      Rabbrev hd[ headers
      Rabbrev te[ template
      Rabbrev co[ cookies
      Rabbrev fl[ flash
      Rabbrev rr(   render
      Rabbrev rp(   render :partial\ =>\ 
      Rabbrev ri(   render :inline\ =>\ 
      Rabbrev rt(   render :text\ =>\ 
      "Rabbrev rtlt( render :layout\ =>\ true,\ :text\ =>\ 
      Rabbrev rl(   render :layout\ =>\ 
      Rabbrev ra(   render :action\ =>\ 
      Rabbrev rc(   render :controller\ =>\ 
      Rabbrev rf(   render :file\ =>\ 
    endif
    if RailsFileType() =~ '^\%(view\|helper\)\>'
      Rabbrev dotiw distance_of_time_in_words
      Rabbrev taiw  time_ago_in_words
    endif
    if RailsFileType() =~ '^controller\>'
      "call s:AddSelectiveExpand('rn','[,\r]','render :nothing => true')
      "let b:rails_abbreviations = b:rails_abbreviations . "rn\trender :nothing => true\n"
      Rabbrev rea( redirect_to :action\ =>\ 
      Rabbrev rec( redirect_to :controller\ =>\ 
    endif
    if RailsFileType() =~ '^model-arb\=\>' || RailsFileType() =~ '^model$'
      Rabbrev bt(    belongs_to
      Rabbrev ho(    has_one
      Rabbrev hm(    has_many
      Rabbrev habtm( has_and_belongs_to_many
      Rabbrev co(    composed_of
      Rabbrev va(    validates_associated
      Rabbrev vb(    validates_acceptance_of
      Rabbrev vc(    validates_confirmation_of
      Rabbrev ve(    validates_exclusion_of
      Rabbrev vf(    validates_format_of
      Rabbrev vi(    validates_inclusion_of
      Rabbrev vl(    validates_length_of
      Rabbrev vn(    validates_numericality_of
      Rabbrev vp(    validates_presence_of
      Rabbrev vu(    validates_uniqueness_of
    endif
    if RailsFileType() =~ '^\%(db-\)\=\%(migration\|schema\)\>'
      Rabbrev mac(  add_column
      Rabbrev mrnc( rename_column
      Rabbrev mrc(  remove_column
      Rabbrev mct( create_table
      "Rabbrev mct   create_table\ :\ do\ <Bar>t<Bar><CR>end<Esc>k$6hi
      Rabbrev mrnt( rename_table
      Rabbrev mdt(  drop_table
      Rabbrev mcc(  t.column
    endif
    if RailsFileType() =~ '^test\>'
      Rabbrev ae(  assert_equal
      Rabbrev ako( assert_kind_of
      Rabbrev ann( assert_not_nil
      Rabbrev ar(  assert_raise
      Rabbrev art( assert_redirected_to
      Rabbrev are( assert_response
    endif
    inoreabbrev <buffer> <silent> :c <C-R>=<SID>TheMagicC()<CR>
    " Lie a little
    Rabbrev :a    :action\ =>\ 
    if RailsFileType() =~ '^view\>'
      let b:rails_abbreviations = b:rails_abbreviations . ":c\t:collection => \n"
    elseif s:controller() != ''
      let b:rails_abbreviations = b:rails_abbreviations . ":c\t:controller => \n"
    else
      let b:rails_abbreviations = b:rails_abbreviations . ":c\t:conditions => \n"
    endif
    Rabbrev :i    :id\ =>\ 
    Rabbrev :o    :object\ =>\ 
    Rabbrev :p    :partial\ =>\ 
    Rabbrev logd( logger.debug
    Rabbrev logi( logger.info
    Rabbrev logw( logger.warn
    Rabbrev loge( logger.error
    Rabbrev logf( logger.fatal
    Rabbrev fi(   find
    Rabbrev AR::  ActiveRecord
    Rabbrev AV::  ActionView
    Rabbrev AC::  ActionController
    Rabbrev AS::  ActiveSupport
    Rabbrev AM::  ActionMailer
    Rabbrev AWS:: ActionWebService
  endif
endfunction

function! s:Abbrev(bang,...) abort
  if !exists("b:rails_abbreviations")
    let b:rails_abbreviations = "\n"
  endif
  if a:0 > 3 || (a:bang && (a:0 != 1))
    return s:error("Rabbrev: invalid arguments")
  endif
  if a:bang
    return s:unabbrev(a:1)
  endif
  if a:0 == 0
    echo s:sub(b:rails_abbreviations,'^\n','')
    return
  endif
  let lhs = a:1
  if a:0 > 3 || a:0 < 2
    return s:error("Rabbrev: invalid arguments")
  endif
  let rhs = a:2
  silent! call s:unabbrev(lhs)
  if lhs =~ '($'
    let b:rails_abbreviations = b:rails_abbreviations . lhs . "\t" . rhs . "" . (a:0 > 2 ? "\t".a:3 : ""). "\n"
    let llhs = s:sub(lhs,'($','')
    if a:0 > 2
      call s:AddParenExpand(llhs,rhs,a:3)
    else
      call s:AddParenExpand(llhs,rhs)
    endif
    return
  endif
  if a:0 > 2
    return s:error("Rabbrev: invalid arguments")
  endif
  if lhs =~ ':$'
    let llhs = s:sub(lhs,':\=:$','')
    call s:AddColonExpand(llhs,rhs)
  elseif lhs =~ '\[$'
    let llhs = s:sub(lhs,'\[$','')
    call s:AddBracketExpand(llhs,rhs)
  elseif lhs =~ '\w$'
    call s:AddTabExpand(lhs,rhs)
  else
    return s:error("Rabbrev: unimplemented")
  endif
  let b:rails_abbreviations = b:rails_abbreviations . lhs . "\t" . rhs . "\n"
endfunction

function! s:unabbrev(abbr)
  let abbr = s:sub(a:abbr,'\%(::\|(\|\[\)$','')
  let pat  = s:sub(abbr,'\','\\')
  if !exists("b:rails_abbreviations")
    let b:rails_abbreviations = "\n"
  endif
  let b:rails_abbreviations = substitute(b:rails_abbreviations,'\V\C\n'.pat.'\(\t\|::\t\|(\t\|[\t\)\.\{-\}\n','\n','')
  exe "iunabbrev <buffer> ".abbr
endfunction

" }}}1
" Settings {{{1

function! s:Set(bang,...)
  let c = 1
  let defscope = ''
  while c <= a:0
    let arg = a:{c}
    let c = c + 1
    if arg =~? '^<[abgl]\=>$'
      let defscope = (matchstr(arg,'<\zs.*\ze>'))
    elseif arg !~ '='
      if defscope != '' && arg !~ '^\w:'
        let arg = defscope.':'.opt
      endif
      let val = s:getopt(arg)
      if val == '' && s:opts() !~ '\<'.arg.'\n'
        call s:error("No such rails.vim option: ".arg)
      else
        echo arg."=".val
      endif
    else
      let opt = matchstr(arg,'[^=]*')
      let val = s:sub(arg,'^[^=]*=','')
      if defscope != '' && opt !~ '^\w:'
        let opt = defscope.':'.opt
      endif
      call s:setopt(opt,val)
    endif
  endwhile
endfunction

function! s:getopt(opt,...)
  let opt = a:opt
  if a:0
    let scope = a:1
  elseif opt =~ '^[abgl]:'
    let scope = tolower(matchstr(opt,'^\w'))
    let opt = s:sub(opt,'^\w:','')
  else
    let scope = 'abgl'
  endif
  if scope =~ 'l' && &filetype != 'ruby'
    let scope = s:sub(scope,'l','b')
  endif
  if scope =~ 'l'
    call s:LocalModelines()
  endif
  let opt = s:sub(opt,'\<\%(rake\|rake_task\|rake_target\)$','task')
  " Get buffer option
  if scope =~ 'l' && exists("b:_".s:sname()."_".s:escvar(s:lastmethod())."_".opt)
    return b:_{s:sname()}_{s:escvar(s:lastmethod())}_{opt}
  elseif exists("b:".s:sname()."_".opt) && (scope =~ 'b' || (scope =~ 'l' && s:lastmethod() == ''))
    return b:{s:sname()}_{opt}
  elseif scope =~ 'a' && exists("s:_".s:rv()."_".s:environment()."_".opt)
    return s:_{s:rv()}_{s:environment()}_{opt}
  elseif scope =~ 'g' && exists("g:".s:sname()."_".opt)
    return g:{s:sname()}_{opt}
  else
    return ""
  endif
endfunction

function! s:setopt(opt,val)
  if a:opt =~? '[abgl]:'
    let scope = matchstr(a:opt,'^\w')
    let opt = s:sub(a:opt,'^\w:','')
  else
    let scope = ''
    let opt = a:opt
  endif
  let opt = s:sub(opt,'\<\%(rake\|rake_task\|rake_target\)$','task')
  let defscope = matchstr(s:opts(),'\n\zs\w\ze:'.opt,'\n')
  if defscope == ''
    let defscope = 'a'
  endif
  if scope == ''
    let scope = defscope
  endif
  if &filetype == 'ruby' && (scope == 'B' || scope == 'l')
    let scope = 'b'
  endif
  if opt =~ '\W'
    return s:error("Invalid option ".a:opt)
  elseif scope =~? 'a'
    let s:_{s:rv()}_{s:environment()}_{opt} = a:val
  elseif scope == 'B' && defscope == 'l'
    let b:_{s:sname()}_{s:escvar('')}_{opt} = a:val
  elseif scope =~? 'b'
    let b:{s:sname()}_{opt} = a:val
  elseif scope =~? 'g'
    let g:{s:sname()}_{opt} = a:val
  elseif scope =~? 'l'
    let b:_{s:sname()}_{s:escvar(s:lastmethod())}_{opt} = a:val
  else
    return s:error("Invalid scope for ".a:opt)
  endif
endfunction

function! s:opts()
  return "\nb:alternate\nb:controller\na:gnu_screen\nb:model\nl:preview\nb:task\nl:related\na:root_url\n"
endfunction

function! s:SetComplete(A,L,P)
  if a:A =~ '='
    let opt = matchstr(a:A,'[^=]*')
    return opt."=".s:getopt(opt)
  else
    let extra = matchstr(a:A,'^[abgl]:')
    let opts = s:gsub(s:sub(s:gsub(s:opts(),'\n\w:','\n'.extra),'^\n',''),'\n','=\n')
    return opts
  endif
  return ""
endfunction

function! s:BufModelines()
  if !g:rails_modelines
    return
  endif
  let lines = getline("$")."\n".getline(line("$")-1)."\n".getline(1)."\n".getline(2)."\n".getline(3)."\n"
  let pat = '\s\+\zs.\{-\}\ze\%(\n\|\s\s\|#{\@!\|%>\|-->\|$\)'
  let cnt = 1
  let mat    = matchstr(lines,'\C\<Rset'.pat)
  let matend = matchend(lines,'\C\<Rset'.pat)
  while mat != "" && cnt < 10
    let mat = s:sub(mat,'\s\+$','')
    let mat = s:gsub(mat,'|','\\|')
    if mat != ''
      silent! exe "Rset <B> ".mat
    endif
    let mat    = matchstr(lines,'\C\<Rset'.pat,matend)
    let matend = matchend(lines,'\C\<Rset'.pat,matend)
    let cnt = cnt + 1
  endwhile
endfunction

function! s:LocalModelines()
  if !g:rails_modelines
    return
  endif
  let lbeg = s:lastmethodline()
  let lend = s:endof(lbeg)
  if lbeg == 0 || lend == 0
    return
  endif
  let lines = "\n"
  let lnum = lbeg
  while lnum < lend && lnum < lbeg + 5
    let lines = lines . getline(lnum) . "\n"
    let lnum = lnum + 1
  endwhile
  let pat = '\s\+\zs.\{-\}\ze\%(\n\|\s\s\|#{\@!\|%>\|-->\|$\)'
  let cnt = 1
  let mat    = matchstr(lines,'\C\<rset'.pat)
  let matend = matchend(lines,'\C\<rset'.pat)
  while mat != "" && cnt < 10
    let mat = s:sub(mat,'\s\+$','')
    let mat = s:gsub(mat,'|','\\|')
    if mat != ''
      silent! exe "Rset <l> ".mat
    endif
    let mat    = matchstr(lines,'\C\<rset'.pat,matend)
    let matend = matchend(lines,'\C\<rset'.pat,matend)
    let cnt = cnt + 1
  endwhile
endfunction

" }}}1
" Initialization {{{1

function! s:InitPlugin()
  call s:InitConfig()
  if g:rails_statusline
    call s:InitStatusline()
  endif
  if has("autocmd") && g:rails_level >= 0
    augroup railsPluginDetect
      autocmd!
      autocmd BufNewFile,BufRead * call s:Detect(expand("<afile>:p"))
      autocmd BufEnter * call s:BufEnter()
      autocmd BufLeave * call s:BufLeave()
      autocmd VimEnter * if expand("<amatch>") == "" && !exists("b:rails_root") | call s:Detect(getcwd()) | call s:BufEnter() | endif
      autocmd BufWritePost */config/database.yml let s:dbext_last_root = "*" " Force reload
      autocmd BufWritePost,BufReadPost * call s:breaktabs()
      autocmd BufWritePre              * call s:fixtabs()
      autocmd FileType railslog call s:RailslogSyntax()
      autocmd FileType * if exists("b:rails_root") | call s:BufSettings() | endif
      autocmd FileType netrw call s:Detect(expand("<afile>:p"))
      autocmd Syntax ruby,eruby,yaml,railslog if exists("b:rails_root") | call s:BufSyntax() | endif
      silent! autocmd QuickFixCmdPre  make* call s:QuickFixCmdPre()
      silent! autocmd QuickFixCmdPost make* call s:QuickFixCmdPost()
    augroup END
  endif
  let s:efm=''
        \.'%D(in\ %f),'
        \.'%A\ %\\+%\\d%\\+)\ Failure:,'
        \.'%C%.%#\ [%f:%l]:,'
        \.'%A\ %\\+%\\d%\\+)\ Error:,'
        \.'%CActionView::TemplateError:\ compile\ error,'
        \.'%C%.%#/lib/gems/%\\d.%\\d/gems/%.%#,'
        \.'%C%.%#/vendor/rails/%.%#,'
        \.'%C%.%#(eval)%.%#,'
        \.'%Z%f:%l:\ syntax\ error\\,\ %m,'
        \.'%Z%f:%l:\ %m,'
        \.'%Z\ %#,'
        \.'%Z%p^,'
        \.'%C\ %\\+On\ line\ #%l\ of\ %f,'
        \.'%C\ \ \ \ %f:%l:%.%#,'
        \.'%Ctest_%.%#:,'
        \.'%CActionView::TemplateError:\ %f:%l:in\ `%.%#'."'".':\ %m,'
        \.'%CActionView::TemplateError:\ You\ have\ a\ %m!,'
        \.'%CNoMethodError:\ You\ have\ a\ %m!,'
        \.'%CActionView::TemplateError:\ %m,'
        \.'%CThe\ error\ occured\ while\ %m,'
        \.'%C%m,'
        \.'ActionView::TemplateError\ (%m)\ on\ line\ #%l\ of\ %f:,'
        \.'%AActionView::TemplateError\ (compile\ error,'
        \.'%.%#/rake_test_loader.rb:%\\d%\\+:in\ `load'."'".':\ %f:%l:\ %m,'
        \.'%-G%.%#/lib/gems/%\\d.%\\d/gems/%.%#,'
        \.'%-G%.%#/vendor/rails/%.%#,'
        \.'%f:%l:\ %m,'
        \.'%-G%.%#'
  command! -bar -bang -nargs=* -complete=dir Rails :call s:NewApp(<bang>0,<f-args>)
  call s:CreateMenus()
endfunction

function! s:Detect(filename)
  let fn = fnamemodify(a:filename,":p")
  if fn =~ '[\/]config[\/]environment\.rb$'
    return s:BufInit(strpart(fn,0,strlen(fn)-22))
  endif
  if isdirectory(fn)
    let fn = fnamemodify(fn,":s?[\/]$??")
  else
    let fn = fnamemodify(fn,':s?\(.*\)[\/][^\/]*$?\1?')
  endif
  let ofn = ""
  let nfn = fn
  while nfn != ofn
    if exists("s:_".s:escvar(nfn))
      return s:BufInit(nfn)
    endif
    let ofn = nfn
    let nfn = fnamemodify(nfn,':h')
  endwhile
  let ofn = ""
  while fn != ofn
    if filereadable(fn . "/config/environment.rb")
      return s:BufInit(fn)
    endif
    let ofn = fn
    let fn = fnamemodify(ofn,':s?\(.*\)[\/]\(app\|components\|config\|db\|doc\|lib\|log\|public\|script\|test\|tmp\|vendor\)\($\|[\/].*$\)?\1?')
  endwhile
  return 0
endfunction

function! s:BufInit(path)
  let cpo_save = &cpo
  set cpo&vim
  let firsttime = !(exists("b:rails_root") && b:rails_root == a:path)
  let b:rails_root = a:path
  let s:_{s:rv()} = 1
  if g:rails_level > 0
    if &ft == "mason"
      setlocal filetype=eruby
    elseif &ft =~ '^\%(conf\)\=$' && expand("%:e") =~ '^\%(rjs\|rxml\|rake\|mab\)$'
      setlocal filetype=ruby
    elseif &ft == "" && expand("%:e") == "liquid"
      setlocal filetype=liquid
    elseif &ft == "" && expand("%:e") == 'rhtml'
      setlocal filetype=eruby
    elseif &ft == "" && expand("%:e") == 'yml'
      setlocal filetype=yaml
    elseif firsttime
      " Activate custom syntax
      let &syntax = &syntax
    endif
    if expand("%:e") == "log"
      setlocal modifiable filetype=railslog
      silent! %s/\%(\e\[[0-9;]*m\|\r$\)//g
      "silent! exe "%s/\r$//"
      setlocal readonly nomodifiable noswapfile autoread foldmethod=syntax
      nnoremap <buffer> <silent> R :checktime<CR>
      nnoremap <buffer> <silent> G :checktime<Bar>$<CR>
      nnoremap <buffer> <silent> q :bwipe<CR>
      $
    endif
  endif
  call s:BufSettings()
  call s:BufCommands()
  call s:BufAbbreviations()
  call s:BufDatabase()
  let t = RailsFileType()
  "if t != ""
    let t = "-".t
  "endif
  let f = '/'.RailsFilePath()
  if f =~ '[ !#$%\,]'
    let f = ''
  endif
  silent doautocmd User Rails
  if t != '-'
    exe "silent doautocmd User Rails".s:gsub(t,'-','.')
  endif
  if f != ''
    exe "silent doautocmd User Rails".f
  endif
  if filereadable(b:rails_root."/config/rails.vim")
    if exists(":sandbox")
      sandbox exe "source ".s:ra()."/config/rails.vim"
    elseif g:rails_modelines
      exe "source ".s:ra()."/config/rails.vim"
    endif
  endif
  call s:BufModelines()
  call s:BufMappings()
  let &cpo = cpo_save
  return b:rails_root
endfunction

function! s:SetBasePath()
  let rp = s:rp()
  let t = RailsFileType()
  let oldpath = s:sub(&l:path,'^\.,','')
  if stridx(oldpath,rp) == 2
    let oldpath = ''
  endif
  let &l:path = '.,'.rp.",".rp."/app/controllers,".rp."/app,".rp."/app/models,".rp."/app/helpers,".rp."/components,".rp."/config,".rp."/lib,".rp."/vendor,".rp."/vendor/plugins/*/lib,".rp."/test/unit,".rp."/test/functional,".rp."/test/integration,".rp."/app/apis,".rp."/app/services,".rp."/test,"."/vendor/plugins/*/test,".rp."/vendor/rails/*/lib,".rp."/vendor/rails/*/test,"
  if s:controller() != ''
    if RailsFilePath() =~ '\<components/'
      let &l:path = &l:path . rp . '/components/' . s:controller() . ','
    else
      let &l:path = &l:path . rp . '/app/views/' . s:controller() . ',' . rp . '/app/views,' . rp . '/public,'
    endif
  endif
  if t =~ '^log\>'
    let &l:path = &l:path . rp . '/app/views,'
  endif
  if &l:path =~ '://'
    let &l:path = ".,"
  endif
  let &l:path = &l:path . oldpath
endfunction

function! s:BufSettings()
  if !exists('b:rails_root')
    return ''
  endif
  call s:SetBasePath()
  "silent compiler rubyunit
  let rp = s:rp()
  let &errorformat=s:efm
  setlocal makeprg=rake
  if stridx(&tags,rp) == -1
    let &l:tags = &tags . "," . rp ."/tags"
  endif
  if has("balloon_eval") && exists("+balloonexpr") && executable('ri')
    setlocal balloonexpr=RailsBalloonexpr()
  endif
  " There is no rjs/rxml filetype now, but in the future, who knows...
  if &ft == "ruby" || &ft == "eruby" || &ft == "rjs" || &ft == "rxml" || &ft == "yaml"
    setlocal sw=2 sts=2 et
    "set include=\\<\\zsAct\\f*::Base\\ze\\>\\\|^\\s*\\(require\\\|load\\)\\s\\+['\"]\\zs\\f\\+\\ze
    setlocal includeexpr=RailsIncludeexpr()
    if exists('+completefunc')
      if &completefunc == ''
        set completefunc=syntaxcomplete#Complete
      endif
    endif
  else
    " Does this cause problems in any filetypes?
    setlocal includeexpr=RailsIncludeexpr()
    setlocal suffixesadd=.rb,.rhtml,.rxml,.rjs,.mab,.liquid,.css,.js,.yml,.csv,.rake,.sql,.html
  endif
  if &filetype == "ruby" || &ft == "rjs" || &ft == "rxml"
    setlocal suffixesadd=.rb,.rhtml,.rxml,.rjs,.mab,.liquid,.yml,.csv,.rake,s.rb
    if expand('%:e') == 'rake'
      setlocal define=^\\s*def\\s\\+\\(self\\.\\)\\=\\\|^\\s*\\%(task\\\|file\\)\\s\\+[:'\"]
    else
      setlocal define=^\\s*def\\s\\+\\(self\\.\\)\\=
    endif
  elseif &filetype == "eruby"
    "set include=\\<\\zsAct\\f*::Base\\ze\\>\\\|^\\s*\\(require\\\|load\\)\\s\\+['\"]\\zs\\f\\+\\ze\\\|\\zs<%=\\ze
    setlocal suffixesadd=.rhtml,.rxml,.rjs,.mab,.liquid,.rb,.css,.js,.html,.yml,.csv
  elseif &filetype == "yaml"
    setlocal suffixesadd=.yml,.csv,.rb,.rhtml,.rxml,.rjs,.mab,.liquid,.rake,s.rb
  endif
endfunction

" }}}1

let s:file = expand('<sfile>:p')
let s:revision = ' $Rev: 128 $ '
let s:revision = s:sub(s:sub(s:revision,'^ [$]Rev:\=\s*',''),'\s*\$ $','')
call s:InitPlugin()

let &cpo = s:cpo_save

" vim:set sw=2 sts=2:
doc/rails.txt
892
*rails.txt*	Plugin for working with Ruby on Rails applications

Author: Tim Pope <vimNOSPAM@tpope.info>		|rails-plugin-author|

|rails-introduction|		Introduction and Feature Summary
|rails-installation|		Installation and Usage
|rails-commands|		General Commands
|rails-navigation|		Navigation
|rails-gf|			    File Under Cursor - gf
|rails-alternate-related|	    Alternate and Related Files
|rails-model-navigation|	    Model Navigation Commands
|rails-controller-navigation|	    Controller Navigation Commands
|rails-scripts|			Script Wrappers
|rails-partials|		Partial Extraction
|rails-integration|		Plugin Integration
|rails-abbreviations|		Abbreviations
|rails-options|			Managed Vim Options
|rails-configuration|		Configuration
|rails-global-settings| 	Global Settings
|rails-about|			About rails.vim
|rails-todo|			To Do

This plugin is only available if 'compatible' is not set.

{Vi does not have any of this}

==============================================================================
INTRODUCTION					*rails-introduction* *rails*

TextMate may be the latest craze for developing Ruby on Rails applications,
but Vim is forever.  This plugin offers the following features for Ruby on
Rails application development.

1. Automatically detects buffers containing files from Rails applications,
   and applies settings to those buffers (and only those buffers).  You can
   use an autocommand to apply your own custom settings as well.
   |rails-configuration|

2. Unintrusive.  Only files in a Rails application should be affected; regular
   Ruby scripts are left untouched.  Even when enabled, the plugin should keep
   out of your way if you're not using its features.  (If you find a situation
   where this is not a case, contact the |rails-plugin-author|.)

3. Provides reasonable settings for working with Rails applications.  Rake is
   the 'makeprg' (and it always knows where your Rakefile is), 'shiftwidth'
   is 2, and 'path' includes an appropriate collection of directories from
   your application. |rails-options|

4. Easy navigation of the Rails directory structure.  |gf| considers context
   and knows about partials, fixtures, and much more.  There are two commands,
   :A (alternate) and :R (related) for easy jumping between files, including
   favorites like model to migration, template to helper, and controller to
   functional test.  For more advanced usage, :Rmodel, :Rview, :Rcontroller,
   and several other commands are provided.  |rails-navigation|

5. Enhanced syntax highlighting.  From has_and_belongs_to_many to
   distance_of_time_in_words, it's here.  For Vim 7 users, 'completefunc' is
   set to enable syntax based completion on |i_CTRL-X_CTRL-U|, making it easy
   to complete such long method names.

6. Interface to script/*.  Generally, use ":Rscript about" to call
   "script/about".  Many commands have wrappers with additional features:
   ":Rgenerate controller Blog" generates a blog controller and edits
   app/controllers/blog_controller.rb.  |rails-scripts|

7. Partial extraction and migration inversion.  |:Rextract| {file} replaces
   the desired range (ideally selected in visual line mode) with "render
   :partial => '{file}'", which is automatically created with your content.
   The @{file} instance variable is replaced with the {file} local variable.
   |rails-partials| |:Rinvert| takes a self.up migration and writes a
   self.down.

8. Integration with other plugins.  |:Rproject| creates a new project.vim
   project.  |:Rdbext| loads database settings from database.yml for dbext.vim
   (and this happens by default under most situations).  Cream users get some
   additional mappings, and all GUI users get a menu.

==============================================================================
INSTALLATION AND USAGE				*rails-installation*

If you have the zip file, extract it to vimfiles (Windows) or ~/.vim
(everything else).  You should have the following files: >
	plugin/rails.vim
	doc/rails.txt
See |add-local-help| for instructions on enabling the documentation.  In a
nutshell: >
	:helptags ~/.vim/doc

Whenever you edit a file in a Rails application, this plugin will be
automatically activated.  This sets various options and defines a few
buffer-specific commands.

If you are in a hurry to get started, with a minimal amount of reading, you
are encouraged to at least skim through the headings and command names in this
file, to get a better idea of what is offered.  If you only read one thing,
make sure it is the navigation section: |rails-navigation|.

==============================================================================
GENERAL COMMANDS				*rails-commands*

All commands are buffer local, unless otherwise stated.  This means you must
actually edit a file from a Rails application.

						*rails-:Rails*
:Rails {directory}	The only global command.  Creates a new Rails
			application in {directory}, and loads the README.

						*rails-:Rake*
:Rake {targets}		Like calling |:make| {targets} (with 'makeprg' being
			rake).  However, in some contexts, if {targets} are
			omitted, :Rake defaults to something sensible (like
			db:migrate in a migration, or your current test).

						*rails-:Rcd*
:Rcd [{directory}]	|:cd| to /path/to/railsapp/{directory}.

						*rails-:Rlcd*
:Rlcd [{directory}]	|:lcd| to /path/to/railsapp/{directory}.

						*rails-:Rdoc*
:Rdoc			Browse to the Rails API, either in doc/api in the
			current Rails application, gem_server if it is
			running, or http://api.rubyonrails.org/ .  Requires
			:OpenURL to be defined (see |rails-:OpenURL|).

						*rails-:Rdoc!*
:Rdoc!			Make the appropriate |:helptags| call and invoke
			|:help| rails.

						*rails-:Redit*
:Redit {file}		Edit {file}, relative to the application root.

						*rails-:Rlog*
:Rlog [{logfile}]	Split window and open {logfile} ($RAILS_ENV or
			development by default).  The control characters used
			for highlighting are removed.  If you have a :Tail
			command (provided by |tailminusf|.vim), that is used;
			otherwise, the file does NOT reload upon change.
			Use |:checktime| to tell Vim to check for changes.
			|G| has been mapped to do just that prior to jumping
			to the end of the file, and q is mapped to close the
			window.  If the delay in loading is too long, you
			might like :Rake log:clear.

						*rails-:Rinvert*
:Rinvert		Experimental command available only in migrations.
			Rewrite the self.up method into a self.down method.
			If self.up is empty, the process is reversed.  The
			chokes on more complicated instructions, but works
			reasonably well for simple calls to create_table,
			add_column, and the like.

						*rails-:Rpreview*
:Rpreview [{path}]	Creates a URL from http://localhost:3000/ and the
			{path} given.  If {path} is omitted, a sensible
			default is used (considers the current
			controller/template, but does not take routing into
			account).  The not too useful default is to then edit
			this URL using Vim itself, allowing |netrw| to
			download it.  More useful is to define a :OpenURL
			command, which will be used instead (see
			|rails-:OpenURL|).
			
						*rails-:Rpreview!*
:Rpreview! [{path}]	As with :Rpreview, except :OpenURL is never used.

						*rails-:Rtags*
:Rtags			Calls ctags -R on the current application root.
			Exuberant ctags must be installed.

						*rails-:OpenURL*
:OpenURL {url}		This is not a command provided by the plugin, but
			rather provided by user and utilized by other plugin
			features.  This command should be defined to open the
			provided {url} in a web browser.  An example command
			on a Mac might be: >
		:command -bar -nargs=1 OpenURL :!open <args>
<			The following appears to work on Windows: >
		:command -bar -nargs=1 OpenURL :!start cmd /cstart /b <args>
<			On Debian compatible distributions, the following is
			the preferred method: >
		:command -bar -nargs=1 OpenURL :!sensible-browser <args>
<			If has("mac_gui"), has("win32_gui"), or
			executable("sensible-browser") is true, the
			corresponding command above will be automatically
			defined.  Otherwise, you must provide your own (which
			is recommended, regardless).

==============================================================================
NAVIGATION					*rails-navigation*

Navigation is where the real power of this plugin lies.  Efficient use of the
following features will greatly ease navigating the Rails file structure.

The 'path' has been modified to include all the best places to be.
>
	:find blog_controller
	:find book_test
<
						*rails-:Rfind*
:Rfind [{file}]		Find {file}.  Very similar to :find, but things like
			BlogController are properly handled, and if
			genutils.vim is installed, tab complete works.  The
			default filename is taken from under the cursor in a
			manner quite similar to gf, described below.

File Under Cursor - gf ~
						*rails-gf*
The |gf| command, which normally edits the current file under the cursor, has
been remapped to take context into account. |CTRL-W_f|(open in new window) and
|CTRL-W_gf| (open in new tab) are also remapped.

Example uses of |gf|, and where they might lead.
(* indicates cursor position)
>
	Pos*t.find(:first)
<	app/models/post.rb ~
>
	has_many :c*omments
<	app/models/comment.rb ~
>
	link_to "Home", :controller => :bl*og
<	app/controllers/blog_controller.rb ~
>
	<%= render :partial => 'sh*ared/sidebar' %>
<	app/views/shared/_sidebar.rhtml ~
>
	<%= stylesheet_link_tag :scaf*fold %>
<	public/stylesheets/scaffold.css ~
>
	class BlogController < Applica*tionController
<	app/controllers/application.rb ~
>
	class ApplicationController < ActionCont*roller::Base
<	.../action_controller/base.rb ~
>
	fixtures :pos*ts
<	test/fixtures/posts.yml ~
>
	layout :pri*nt
<	app/views/layouts/print.rhtml ~
>
	(In the Blog controller)
	def li*st
<	app/views/blog/list.rhtml ~

Alternate and Related Files ~
						*rails-alternate-related*
Two commands, :A and :R, are used quickly jump to an "alternate" and a
"related" file, defined below.

		*rails-:A* *rails-:AE* *rails-:AS* *rails-:AV* *:rails-:AT*
:A			These commands were picked to mimic Michael Sharpe's
:AE			a.vim.  Briefly, they edit the "alternate" file, in
:AS			either the same window (:A and :AE), a new split
:AV			window (:AS), a new vertically split window (:AV), or
:AT			a new tab (:AT).  An experimental mapping for :A is
			[f .

		*rails-:R* *rails-:RE* *rails-:RS* *rails-:RV* *:rails-:RT*
:R			These are similar |rails-:A| and friends above, only
:RE			they jump to the "related" file rather than the
:RS			"alternate."  An experimental mapping for :R is ]f .
:RV			
:RT

					*rails-alternate* *rails-related*
The alternate file is most frequently the test file, though there are
exceptions.  The related file varies, and is sometimes dependent on current
current location in the file.  For example, when editing a controller, the
related file is template for the method currently being edited.

The easiest way to learn these commands is to experiment.  A few examples of
alternate and related files follow:

Current file		Alternate file		Related file ~
model			unit test		related migration
controller (in method)	functional test		template (view)
template (view)		helper			controller (jump to method)
migration		previous migration	next migration
config/routes.rb	config/database.yml	config/environment.rb

Suggestions for further contexts to consider for the alternate file, related
file, and file under the cursor are welcome.  They are subtly tweaked from
release to release.

For the more uncommon cases, a more deliberate set of commands are provided.
Each of the following takes an optional argument (with tab completion) but
defaults to a reasonable guess that follows Rails conventions.  For example,
when editing app/models/employee.rb, :Rcontroller will default to
app/controllers/employees_controller.rb.  The controller and model options,
ideally set from  |rails-modelines|,  can override the mapping from model
related files to controller related files (Rset controller=hiring) and vice
versa (Rset model=employee).  See |rails-:Rset|.

Each of the following commands has variants for splitting, vertical splitting
and opening in a new tab.  For :Rmodel, those variants would be :RSmodel,
:RVmodel, and :RTmodel.  There is also :REmodel which is a synonym for :Rmodel
(future versions might allow customization of the behavior of :Rmodel).


Model Navigation Commands ~
						*rails-model-navigation*
The default for model navigation commands is the current model, if it can be
determined.  For example, test/unit/post_test.rb would have a current model
of post.  Otherwise, if a controller name can be determined, said controller
name will be singularized and used.  To override this, use a command or
modeline like: >
	Rset model=comment

:Rmodel						|rails-:Rmodel|
:Rmigration					|rails-:Rmigration|
:Robserver					|rails-:Robserver|
:Rfixtures					|rails-:Rfixtures|
:Runittest					|rails-:Runittest|

						*rails-:Rmodel*
:Rmodel [{name}]	Edit the specified model.

						*rails-:Rmigration*
:Rmigration [{pattern}]	If {pattern} is a number, find the migration for that
			particular set of digits, zero-padding if necessary.
			Otherwise, find the newest migration containing the
			given pattern.  The pattern defaults to the current
			model name, pluralized.  So when editing the Post
			model, :Rmigration with no arguments might find
			create_posts.rb, or add_date_to_posts.rb.

						*rails-:Robserver*
:Robserver [{name}]	Find the observer with a name like
			{model}_observer.rb.  When in an observer, most
			commands (like :Rmodel) will seek based on the
			observed model ({model}) and not the actual observer
			({model}_observer).  However, for the command
			:Runittest, a file of the form
			{model}_observer_test.rb will be found.

:Rfixtures [{name}]	Edit the fixtures for the given model.  If an argument
			is given, it must be pluralized, like the final
			filename (this may change in the future).  If omitted,
			the current model is pluralized automatically.  An
			optional extension can be given, to distinguish
			between YAML and CSV fixtures.

						*rails-:Runittest*
:Runittest [{name}]	Edit the unit test for the specified model.

Controller Navigation Commands  ~
						*rails-controller-navigation*
The default for model navigation commands is the current controller, if it can
be determined.  For example, test/functional/blog_test.rb would have a current
controller of blog.  Otherwise, if a model name can be determined, said model
name will be pluralized and used.  To override this, use a command or modeline
like: >
	Rset controller=blog

:Rcontroller					|rails-:Rcontroller|
:Rhelper					|rails-:Rhelper|
:Rview						|rails-:Rview|
:Rlayout					|rails-:Rlayout|
:Rapi						|rails-:Rapi|
:Rfunctionaltest				|rails-:Rfunctionaltest|
:Rintegrationtest				|rails-:Rintegrationtest|

						*rails-:Rcontroller*
:Rcontroller [{name}]	Edit the specified controller.

						*rails-:Rhelper*
:Rhelper [{name}]	Edit the helper for the specified controller.

						*rails-:Rview*
:Rview [[{controller}/]{view}]
			Edit the specified view.  The controller will default
			sensibly, and the view name can be omitted when
			editing a method of a controller.  If a view name is
			given with an extension, a new file will be created.
			This is a quick way to create a new view.

						*rails-:Rlayout*
:Rlayout [{name}]	Edit the specified layout.  Defaults to the layout for
			the current controller, or the application layout if
			that cannot be found.  A new layout will be created if
			an extension is given.

						*rails-:Rapi*
:Rapi [{name}]		Edit the API for the specified controller.

						*rails-:Rfunctionaltest*
:Rfunctionaltest [{name}]
			Edit the functional test for the specified controller.

						*rails-:Rintegrationtest*
:Rintegrationtest [{name}]
			Edit the integration test specified.  The default
			is based on the current controller or model, with no
			singularization or pluralization done.

Finally, one Vim feature that proves helpful in conjunction with all of the
above is |CTRL-^|.  This keystroke edits the previous file, and is helpful to
back out of any of the above commands.

==============================================================================
SCRIPT WRAPPERS					*rails-scripts*

The following commands are wrappers around the scripts in the script directory
of the Rails application.  Most have extra features beyond calling the script.
A limited amount of completion with <Tab> is supported.

						*rails-:Rscript*
:Rscript {script} {options}
			Call ruby script/{script} {options}.

				*rails-:Rbreakpointer* *rails-:Rconsole*
:Rbreakpointer {options}
:Rconsole {options}	Start the appropriate script.  On Windows these are
			launched in the background with |!start|.  In the
			terminal version GNU Screen is used if it is running
			and |g:rails_gnu_screen| is set.

						*rails-:Rrunner*
:Rrunner {code}		Executes {code} with script/runner.  Differs from
			:Rscript runner {code} in that the code is passed as
			one argument. Also, |system()| is used instead of
			|:!|.  This is to help eliminate annoying "Press
			ENTER" prompts.

						*rails-:Rp*
:Rp {code}		Like :Rrunner, but call the Ruby p method on the
			result. Literally "begin p {code} end".

						*rails-:Rgenerate*
:Rgenerate {options}	Calls script/generate {options}, and then edits the
			first file generated.  Respects |g:rails_subversion|.

						*rails-:Rdestroy*
:Rdestroy {options}	Calls script/destroy {options}.  Respects
			|g:rails_subversion|.

						*rails-:Rplugin*
:Rplugin {options}	Calls script/plugin {options}.  Respects
			|g:rails_subversion|.

						*rails-:Rserver*
:Rserver {options}	Launches script/server {options} in the background.
			On win32, this means |!start|.  On other systems, this
			uses the --daemon option.

						*rails-:Rserver!*
:Rserver! {options}	Same as |:Rserver|, only first attempts to kill any
			other server using the same port.  On non-Windows
			systems, lsof must be installed for this to work.

==============================================================================
PARTIAL EXTRACTION				*rails-partials*

The :Rextract command can be used to extract a partial to a new file.

						*rails-:Rextract*
:[range]Rextract [{controller}/]{name}	
			Create a {name} partial from [range] lines (default:
			current line).

						*rails-:Rpartial*
:[range]Rpartial [{controller}/]{name}	
			Deprecated alias for :Rextract.

If this is your file, in app/views/blog/show.rhtml: >

  1	<div>
  2	  <h2><%= @post.title %></h2>
  3	  <p><%= @post.body %></p>
  4	</div>

And you issue this command: >

	:2,3Rextract post

Your file will change to this: >

  1	<div>
  2	  <%= render :partial => 'post' %>
  3	</div>

And app/views/blog/_post.rhtml will now contain: >

  1	<h2><%= post.title %></h2>
  2	<p><%= post.body %></p>

As a special case, if the file had looked like this: >

  1     <% for object in @posts -%>
  2	  <h2><%= object.title %></h2>
  3	  <p><%= object.body %></p>
  4	<% end -%>
<
The end result would have been this: >

  1     <%= render :partial => 'post', :collection => @posts %>
<
The easiest way to choose what to extract is to use |linewise-visual| mode.
Then, a simple >
	:'<,'>Rextract blog/post
will suffice. (Note the use of a controller name in this example.)

==============================================================================
PLUGIN INTEGRATION				*rails-integration*

					*rails-:Rproject* *rails-project*
:Rproject [{file}]	This command is only provided when the |project|
			plugin is installed.  Invoke :Project (typically
			without an argument), and search for the root of the
			current Rails application.  If it is not found, create
			a new project, with appropriate directories (app,
			etc., but not vendor).

						*rails-:Rproject!*
:Rproject! [{file}]	Same as :Rproject, only delete existing project if it
			exists and recreate it.  The logic to delete the old
			project is convoluted and possibly erroneous; report
			any problems to the |rails-plugin-author|.  A handy
			mapping might look something like: >
		autocmd User Rails map <buffer> <F6> :Rproject!|silent w<CR>
<			As a bonus, this command organizes views into separate
			directories for easier navigation.  The downside of
			this is that you will have to regenerate your project
			each time you add another view directory (which is why
			this command recreates your project each time!).

						*rails-:Rdbext* *rails-dbext*
:Rdbext [{environment}] This command is only provided when the |dbext| plugin
			is installed.  Loads the {environment} configuration
			(defaults to $RAILS_ENV or development) from
			config/database.yml and uses it to configure dbext.
			The configuration is cached until a different Rails
			application is edited.  This command is called for you
			automatically when |g:rails_dbext| is set (default on
			non-Windows systems).

						*rails-:Rdbext!*
:Rdbext! [{environment}]
			Load the database configuration as above, and then
			attempt a CREATE DATABASE for it.  This is primarily
			useful for demonstrations.

						*rails-cream*
This plugin provides a few additional key bindings if it is running under
Cream, the user friendly editor which uses Vim as a back-end.  Ctrl+Enter
finds the file under the cursor (as in |rails-gf|), and Alt+[ and Alt+] find
the alternate (|rails-alternate|) and related (|rails-related|) files.  There
is also a GUI menu, which is available in both Cream and GVim.

==============================================================================
ABBREVIATIONS				*rails-abbreviations* *rails-snippets*

Abbreviations are still experimental.  They may later be extracted into a
separate plugin, or removed entirely.

						*rails-:Rabbrev*
:Rabbrev		List all Rails abbreviations.

:Rabbrev {abbr} {expn} [{extra}]
			Define a new Rails abbreviation. {extra} is permitted
			if and only if {expn} ends with "(".

						*rails-:Rabbrev!*
:Rabbrev! {abbr}	Remove an abbreviation.

Rails abbreviations differ from regular abbreviations in that they only expand
after a <C-]> (see |i_CTRL-]|) or a <Tab> (if <Tab> does not work, it is
likely mapped by another plugin).  If the abbreviation ends in certain
punctuation marks, additional expansions are possible.  A few examples will
hopefully clear this up (all of the following are enabled by default in
appropriate file types).

Command				Sequence typed		Resulting text ~
Rabbrev rp( render :partial\ =>	rp(			render(:partial =>
Rabbrev rp( render :partial\ =>	rp<Tab>			render :partial =>
Rabbrev vs( validates_size_of	vs(			validates_size_of(
Rabbrev pa[ params		pa[:id]			params[:id]
Rabbrev pa[ params		pa<C-]>			params
Rabbrev pa[ params		pa.inspect		params.inspect
Rabbrev AR:: ActionRecord	AR::Base		ActiveRecord::Base
Rabbrev :a :action\ =>\		render :a<Tab>		render :action => 

In short, :: expands on :, ( expands on (, and [ expands on both . and [.
These trailing punctuation marks are NOT part of the final abbreviation, and
you cannot have two mappings that differ only by punctuation.

You must escape spaces in your expansion, either as "\ " or as "<Space>".  For
an abbreviation ending with "(", you may define where to insert the
parenthesis by splitting the expansion into two parts (divided by an unescaped
space).

Many abbreviations abbreviations are provided by default: use :Rabbrev to list
them.  They vary depending on the type of file (models have different
abbreviations than controllers).  There is one "smart" abbreviation, :c, which
expands to ":controller => ", ":collection => ", or ":conditions => "
depending on context.

==============================================================================
CONFIGURATION					*rails-configuration*

Very little configuration is actually required; this plugin automatically
detects your Rails application and adjusts Vim sensibly.

					*rails-:autocmd* *rails-autocommands*
If you would like to set your own custom Vim settings whenever a Rails file is
loaded, you can use an autocommand like the following in your vimrc: >
	autocmd User Rails		silent! Rlcd
	autocmd User Rails		map <buffer> <F9> :Rake<CR>
You can also have autocommands that only apply to certain types of files.
These are based off the information shown in the 'statusline' (see
|rails-'statusline'|), with hyphens changed to periods. A few examples: >
	autocmd User Rails.controller*	iabbr <buffer> wsn wsdl_service_name
	autocmd User Rails.model.arb*	iabbr <buffer> vfo validates_format_of
	autocmd User Rails.view.rhtml*  imap  <buffer> <C-Z> <%=  %><C-O>3h
End all such Rails autocommands with asterisks, even if you have an exact
specification.  There is also a filename matching syntax: >
	autocmd User Rails/db/schema.rb  Rset task=db:schema:dump
	autocmd User Rails/**/foo_bar.rb Rabbrev FB:: FooBar
Use the filetype based syntax whenever possible, reserving the filename based
syntax for more advanced cases.

						*config/rails.vim*
If you have settings particular to a specific project, they can be put in a
config/rails.vim file in the root directory of the application.  The file is
sourced in the |sandbox| for security reasons.  This only works in Vim 7 or
newer.

						*rails-:Rset*
:Rset {option}[={value}]
			Query or set a local option.  This command may be
			called directly, from an autocommand, or from
			config/rails.vim.

Options may be set set in one of four scopes, which my be indicated by an
optional prefix.  These scopes determine how broadly an option will apply.
Generally, the default scope is sufficient

Scope	Description ~
a:	All files in one Rails application
b:	Buffer (file) specific
g:	Global to all applications
l:	Local to method (same as b: in non-Ruby files)

Options are shown below with their default scope, which should be omitted.
While you may override the scope with a prefix, this is rarely necessary and
oftentimes useless.  (For example, setting g:task is useless because the
default rake task will apply before considering this option.)

Option		Meaning ~
b:alternate	Custom alternate file for :A, relative to the Rails root
b:controller	Default controller for certain commands (e.g., :Rhelper)
b:model		Default model for certain commands (e.g., :Rfixtures)
l:preview	URL stub for :Rpreview (e.g., blog/show/1)
b:task		Default task used with :Rake
l:related	Custom related file for :R, relative to the Rails root
a:root_url	Root URL for commands like :Rpreview

Examples: >
	:Rset root_url=http://localhost:12345
	:Rset related=app/views/blog/edit.rhtml preview=blog/edit/1
	:Rset alternate=app/models/
	:Rset l:task=preview        " Special pseudo-task for :Rake

Note the use of a scope prefix in the last example.

						*rails-modelines*
If |g:rails_modelines| is enabled, these options can also be set from
modelines near the beginning or end of the file.  These modelines will always
set buffer-local options; scope should never be specified.  Examples: >
	# Rset task=db:schema:load
	<%# Rset alternate=app/views/layouts/application.rhtml %>
Modelines can also be local to a method.  Example: >
	def test_comment
	  # rset alternate=app/models/comment.rb
These two forms differ only in case.

==============================================================================
MANAGED VIM OPTIONS			*rails-options*

The following options are set local to buffers where the plugin is active.

					*rails-'shiftwidth'*	*rails-'sw'*
					*rails-'softtabstop'*	*rails-'sts'*
					*rails-'expandtab'*	*rails-'et'*
A value of 2 is used for 'shiftwidth' (and 'softtabstop'), and 'expandtab' is
enabled.  This is a strong convention in Rails, so the conventional wisdom
that this is a user preference has been ignored.

					*rails-'path'*		*rails-'pa'*
All the relevant directories from your application are added to your 'path'.
This makes it easy to access a buried file: >
	:find blog_controller.rb
<
					*rails-'suffixesadd'*	*rails-'sua'*
This is filetype dependent, but typically includes .rb, .rhtml, and several
others.  This allows shortening the above example: >
	:find blog_controller
<
					*rails-'includeexpr'*	*rails-'inex'*
The 'includeexpr' option is set to enable the magic described in |rails-gf|.

					*rails-'statusline'*	*rails-'stl'*
Useful information is added to the 'statusline', when |g:rails_statusline| is
enabled.  This option is set globally because it appears to have no side
effects.

					*rails-'makeprg'*	*rails-'mp'*
					*rails-'errorformat'*	*rails-'efm'*
Rake is used as the 'makeprg', so |:make| will work as expected.  Also, 
'errorformat' is set appropriately to handle your tests.

					*rails-'filetype'*	*rails-'ft'*
The 'filetype' is sometimes adjusted for Rails files.  Most notably, *.rxml
and *.rjs are treated as Ruby files, and files that have been falsely
identified as Mason sources are changed back to ERuby files (but only when
they are part of a Rails application).

					*rails-'completefunc'*	*rails-'cfu'*
A 'completefunc' is provided (if not already set).  It is pretty simple, as it
uses syntax highlighting to make its guess.  See |i_CTRL-X_CTRL-U|.

					*rails-'balloonexpr'*  *rails-'bexpr'*
If ri is installed, 'balloonexpr' is set up to call it.  In order to use it,
'ballooneval' must be set.  See |balloon-eval| for details.

==============================================================================
GLOBAL SETTINGS					*rails-global-settings*

A few global variables control the behavior of this plugin.  In general, they
can be enabled by setting them to 1 in your vimrc, and disabled by setting
them to 0. >
	let g:rails_some_option=1
	let g:rails_some_option=0
Most of these should never need to be used.  The few that might be interesting
are |g:rails_expensive|, |g:rails_subversion|, and |g:rails_default_database|.

						*g:rails_level*  >
	let g:rails_level=3
This is a general control of the level of features loaded.  Behavior can be
subsequently refined with other settings.  This option is a candidate for
removal; contact the |rails-plugin-author| if you still make use of it.

value	meaning ~

-1	Completely disabled.
0	User level autocommands only.
1	Minimal features; mainly option management.
2	Default, minus a few niceties like mappings and the statusline.
3	Default.  Includes all but a few possibly disruptive features.
4	Enables all normal features.  Recommended.
5+	Experimental features.

						*g:loaded_rails*  >
	let g:loaded_rails=1
Do not load the plugin. For emergency use only.

						*g:rails_abbreviations*
Enable Rails abbreviations.  See |rails-abbreviations|.  Enabled when
|g:rails_level| >= 3.

						*g:rails_dbext*  >
	let g:rails_dbext=1
Enable integration with the dbext plugin, if it is installed.  Defaults to the
value of |g:rails_expensive|.  When this option is set, dbext settings are
automagically extracted from config/database.yml.  Then, you can use features
like table name completion and commands like >
	:Create database brablog_development
	:Select * from posts where title like '%Denmark%'
Note that dbext is a complicated plugin, and may require additional
configuration.  See |dbext| (if installed) and |sql-completion-dynamic| (in
Vim 7).

						*g:rails_default_file*  >
	let g:rails_default_file='config/database.yml'
File to load when a new Rails application is created.  Defaults to the README.

						*g:rails_default_database*  >
	let g:rails_default_database='sqlite3'
Database to use for new applications.  Defaults to letting Rails decide.
 
					*rails-slow* *g:rails_expensive*  >
	let g:rails_expensive=1
Enables or disables expensive (slow) features (typically involving calls to
the Ruby interpreter).  Recommended for moderately fast computers.  Enabled
when |g:rails_level| >= 3 (>= 4 on Windows, which runs external programs
decidedly slower).  Windows users are encouraged to turn this option on and
see if performance is still acceptable.

					*rails-screen* *g:rails_gnu_screen*  >
	let g:rails_gnu_screen=1
Use GNU Screen (if it is running) to launch |:Rbreakpointer|, |:Rconsole|, and
|:Rserver| in the background.  Enabled by default.

						*g:rails_mappings*  >
	let g:rails_mappings=1
Enables a few mappings (mostly for |rails-navigation|). Enabled when
|g:rails_level| >= 3.

						*g:rails_modelines*  >
	let g:rails_modelines=1
Enable modelines like the following: >
	# Rset task=db:schema:load
Modelines set buffer-local options using the :Rset command.
Also enables method specific modelines (note the case difference): >
	  def show
	    # rset preview=blog/show/1
Modelines are extremely useful but may cause security concerns when editing
projects from an untrusted source. Enabled when |g:rails_level| >= 3.

						*g:rails_menu*  >
	let g:rails_menu=1
When 2, a Rails menu is created.  When 1, this menu is a submenu under the
Plugin menu.  The default is 0, 1, or 2, depending on whether |g:rails_level|
is less than, equal to, or greater than 3.

						*g:rails_url*  >
	let g:rails_url='http://localhost:3000/'
Used for the |:Rpreview| command.  Default is as shown above.  Overridden by
b:rails_url.

						*g:rails_statusline*  >
	let g:rails_statusline=1
Give a clue in the statusline when this plugin is enabled.  Enabled when
|g:rails_level| >= 3.

						*g:rails_subversion*  >
	let g:rails_subversion=1
Automatically add/remove files to the subversion repository for commands like
|:Rgenerate| and |:Rdestroy| (but not |:Rscript|).  Ignored when the
application is not part of a subversion repository.  Enabled with
|g:rails_level| >= 4.

						*g:rails_syntax*  >
	let g:rails_syntax=1
When enabled, this tweaks the syntax highlighting to be more Rails friendly.
Enabled when |g:rails_level| >= 2.

When g:rails_syntax is enabled, you may find your Ruby files to be a bit heavy
on the cyan (or however your Identifiers are highlighted).  You may want to
enable g:ruby_no_identifiers, as explained in |ft-ruby-syntax|.

					*rails-tabs* *g:rails_tabstop*  >
	let g:rails_tabstop=4
This option is for people who dislike the default 'shiftwidth' of 2.  When
non-zero, all files will have a |:retab|! done with 'tabstop' set to 2 on
load, to convert the initial indent from spaces to tabs.  Then, 'tabstop' and
'shiftwidth' will be set to the option's value.  The process is reversed on
write.  Thus, one can use a custom indent when editing files, yet conform to
Rails conventions when saving them.  There is also a local buffer version
of this option, to allow for things like: >
	autocmd User Rails if &ft == 'ruby' | let b:rails_tabstop = 4 | endif
This option defaults to 0, which is the recommended value.

If instead of all this magic, you would prefer to just override this plugin's
settings and use your own custom 'shiftwidth', adjust things manually in an
autocommand: >
	autocmd User Rails set sw=4 sts=4 noet
This is highly discouraged: don't fight Rails.

==============================================================================
ABOUT					*rails-about* *rails-plugin-author*

This plugin was written by Tim Pope.  Email him at <vimNOSPAM@tpope.info>.  He
can also be found on Freenode's IRC network, hanging out in #rubyonrails and
#vim as tpope.

The latest stable version can be found at
    http://www.vim.org/scripts/script.php?script_id=1567
In Vim 7.0, you can keep up to date with |GetLatestVimScripts|.

Development versions can be found at the following URLs:
    http://tpope.us/rails.vba
    http://tpope.us/rails.zip
    http://svn.tpope.net/rails/vim/railsvim
The first is a |vimball| for Vim 7.0.  The third is a subversion repository
and contains the very latest features and bugs.

Feedback is highly desired on this plugin.  Please send all comments,
complaints, and compliments to the author.

This plugin is distributable under the same terms as Vim itself.  See
|license|.  No warranties, expressed or implied.

==============================================================================
TODO						*rails-todo*

Create and maintain some sort of changelog.  (No seriously, I really plan to.)

==============================================================================
vim:tw=78:ts=8:ft=help:norl:
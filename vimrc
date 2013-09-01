" GENERAL SETTINGS                                                             {{{
" --------------------------------------------------------------------------------

set nocompatible                " Disable Vi compatibility

if filereadable($HOME."/.vim/bundle/pathogen/autoload/pathogen.vim")
  runtime bundle/pathogen/autoload/pathogen.vim
  call pathogen#infect()        " Manage 'runtimepath' with pathogen.vim
endif

if has("autocmd")
  filetype plugin indent on     " File-type detection, plug-ins, indent scripts
endif
if has("syntax") && !exists("g:syntax_on")
  syntax enable                 " Enable syntax highlighting
endif
if &t_Co >= 16
  silent! colorscheme noctu     " Set color scheme for 16-color+ terminals
endif

if &shell =~# "fish$"
  set shell=/bin/bash           " Ensure shell is POSIX compatible
endif

set encoding=utf-8              " Use UTF-8 as default file encoding
set spelllang=en_us             " Language and region to use for spellchecking
set shortmess+=I                " Suppress intro message when starting Vim
set laststatus=2                " Always show status line
set ruler                       " Show cursor position if status line not visible
set modeline modelines=5        " Look for modeline at beginning/end of file
set hidden                      " Allow buffers to become hidden
set autoread                    " Reload unchanged buffer when file changes
set history=500                 " Keep 500 lines of history
set scrolloff=2                 " Keep lines above/below cursor visible
set sidescrolloff=5             " Keep columns left/right of cursor visible
set display+=lastline           " Show as much as possible of wrapped last line
set foldnestmax=3               " Limit depth of nested syntax/indent folds
set foldopen-=block             " Do not open folds on '(', '{', etc.
set helpheight=1000             " Maximize help window vertically
set lazyredraw                  " Do not redraw screen during macro execution
set fillchars=vert:\ ,diff:\    " Use space for vertical split, diff fill char
if has("linebreak")             " Wrap lines at word boundaries
  set linebreak
  set showbreak=...
endif
set nowrap                      " Do not wrap long lines by default
set listchars=tab:>\ ,eol:$,extends:>,precedes:<,nbsp:+
if &termencoding ==# "utf-8" || &encoding ==# "utf-8"
  let &fillchars = "vert:\u2502,diff: "
  let &listchars = "tab:\u25b8 ,eol:\u00ac,extends:\u276f,precedes:\u276e,nbsp:\u2334"
  if has("linebreak")
    let &showbreak = "\u21aa"
  endif
  highlight VertSplit ctermbg=NONE guibg=NONE
endif

if has("unnamedplus")
  set clipboard=unnamedplus
else
  set clipboard=unnamed
endif

"" Command line and completion
set wildmenu                    " Command line completion
set cmdheight=2                 " Reserve two lines for command area
set completeopt+=longest        " Only insert longest common string
set pumheight=8                 " Limit height of popup menu

"" Whitespace
set autoindent
set backspace=indent,eol,start  " Allow backspacing over everything in insert mode
set tabstop=4                   " Width of displayed tabs--the rest is taken care of by sleuth.vim
set shiftround                  " Round indent to multiple of 'shiftwidth'

"" Swaps and backups
if !strlen($SUDO_USER) && has("unix")
  " Don't store swaps in . -- store in ~/.vim/tmp/%path%to%orig.swp
  set directory=~/.vim/tmp//,.,/var/tmp
  " Don't store backups in . -- store in ~/.vim/tmp/%path%to%orig~
  set backupdir=~/.vim/tmp//,.,/var/tmp
  " Create tmp/ dir if it doesn't exist
  if !isdirectory($HOME."/.vim/tmp") && exists("*mkdir")
    call mkdir($HOME."/.vim/tmp", "p", 0700)
  endif
else
  set nobackup
  set nowritebackup
  set noswapfile
endif

"" Searching
set hlsearch                    " Highlight search matches
set incsearch                   " Do incremental searching
set smartcase                   " Case-sensitivity triggered by capital letter if 'ignorecase' set

let g:statusline_separator_left = " \u27e9 "
let g:statusline_separator_right = " \u27e8 "

let &statusline = ""
let &statusline .= " %{fnamemodify(getcwd(), ':~')}"
let &statusline .= g:statusline_separator_left
let &statusline .= "%f%m"
let &statusline .= "%{StatuslineGit()}"
let &statusline .= "%="
let &statusline .= "%{strlen(&fenc)?&enc:&fenc}"
let &statusline .= g:statusline_separator_right
let &statusline .= '%{strlen(&ft)?&ft:"n/a"}'
let &statusline .= g:statusline_separator_right
let &statusline .= '%1*%{exists("*SyntasticStatuslineFlag")?SyntasticStatuslineFlag():""}%*'
let &statusline .= "%3.l:%-3.c "

" In many terminal emulators the mouse works just fine, thus enable it.
if has("mouse")
  set mouse=a
endif

" Load matchit.vim, if a newer version isn't already installed
if !exists("g:loaded_matchit") && findfile("plugin/matchit.vim", &rtp) ==# ""
  runtime! macros/matchit.vim
endif

" }}}
" FUNCTIONS & COMMANDS                                                         {{{
" --------------------------------------------------------------------------------

" Git branch/commit in status line
function! StatuslineGit()
  if !exists('*fugitive#head')
    return ''
  endif
  let l:out = fugitive#head(8)
  if l:out !=# ''
    let l:out = g:statusline_separator_left . l:out
  endif
  return l:out
endfunction

" Show highlight group of character under cursor
function! <SID>SynStack()
  if !exists("*synstack")
    return
  endif
  echo map(synstack(line("."), col(".")), "synIDattr(v:val, 'name')")
endfunction

" Follow symlink to actual file
function! <SID>FollowSymlink()
  " Get path of actual file
  let fname = resolve(expand("%:p"))
  " Rename buffer with new path
  execute "file " . fname
  " Read file again to trigger any plug-ins that are context-sensitive
  edit
endfunction

if !exists(":FollowSymlink")
  command FollowSymlink call <SID>FollowSymlink()
endif

" Execute commands without moving cursor, changing search pattern
function! <SID>Preserve(...)
  let l:saved_search = @/
  let l:saved_view = winsaveview()
  for l:command in a:000
    execute l:command
  endfor
  call winrestview(l:saved_view)
  let @/ = l:saved_search
endfunction

function! <SID>NormalizeWhitespace()
  " 1. Strip trailing whitespace
  " 2. Merge consecutive blank lines
  " 3. Strip empty line from end of file
  call <SID>Preserve(
    \ '%substitute/\s\+$//e',
    \ '%substitute/\n\{3,}/\r\r/e',
    \ '%substitute/\n\+\%$//e'
    \ )
endfunction

function! <SID>NormalModeDigraph(char2)
  let l:char1 = matchstr(getline('.'), '.', byteidx(getline('.'), col('.') - 1))
  echo 'digraph: ' . l:char1 . a:char2
  return "r\<C-k>" . l:char1 . a:char2
endfunction

function! <SID>Bdelete(bang) abort
  let l:current_buffer = bufnr("%")
  let l:alternate_buffer = bufnr("#")

  if buflisted(l:alternate_buffer)
    execute "buffer" . a:bang . " #"
  else
    execute "bnext" . a:bang
  endif

  if bufnr("%") == l:current_buffer
    new
  endif

  if buflisted(l:current_buffer)
    execute "bdelete" . a:bang . " " . l:current_buffer
  endif
endfunction

if !exists(":Bdelete")
  command -bang -bar Bdelete call <SID>Bdelete(<q-bang>)
endif

if exists("$NOTES")
  command! -bang Today execute "edit<bang> $NOTES/" . strftime("%Y-%m-%d") . ".md<Bar>lcd %:p:h"
endif

" Toggle light/dark background
command! -nargs=0 -bar BackgroundInvert let &background = ( &background == "dark" ? "light" : "dark" )

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
if !exists(":DiffOrig")
  command DiffOrig vertical new | set buftype=nofile | read # | 0delete_
    \ | diffthis | wincmd p | diffthis
endif

" }}}
" AUTOCOMMANDS                                                                 {{{
" --------------------------------------------------------------------------------

if has("autocmd")
  augroup FileTypeOptions
    autocmd!

    " For all text files set 'textwidth' to 78 characters.
    autocmd FileType text,markdown setlocal textwidth=78 wrap
    autocmd FileType markdown silent! compiler pandoc

    " Always use spelling for particular file types
    autocmd FileType gitcommit setlocal spell

    " Append semicolon or comma to end of line in insert mode
    autocmd FileType c,cpp,css,javascript,php inoremap <buffer> ;; <Esc>A;
    autocmd FileType c,cpp,css,javascript,php inoremap <buffer> ,, <Esc>A,
    autocmd FileType php,ruby inoremap <buffer> >> <Space>=><Space>

    " Automatically complete closing tags
    autocmd FileType html,liquid,markdown,php,xml inoremap <buffer> </ </<C-x><C-o>
    autocmd FileType html,liquid,xml setlocal textwidth=120

    " CSS-like languages
    autocmd FileType css,less setlocal foldmethod=marker
    autocmd FileType css,less setlocal foldmarker={,}

    " csv.vim
    autocmd FileType csv map <buffer> ( H
    autocmd FileType csv map <buffer> ) L

    " Keep separate spell file for Vim scripting
    autocmd FileType vim,help setlocal
      \ spellfile=~/.vim/spell/en.utf-8.add,~/.vim/spell/vim.utf-8.add
    autocmd FileType vim setlocal keywordprg=:help

    " Do not wrap lines in the QuickFix window
    autocmd FileType qf setlocal nowrap

    " Set format options for Apache config files
    autocmd FileType apache setlocal comments=:# commentstring=#\ %s
      \ formatoptions-=t formatoptions+=croql

    " Set options for fish scripts
    autocmd FileType fish silent! compiler fish
    autocmd FileType fish setlocal textwidth=78 foldmethod=expr

    " Set the file type for common Ruby files not ending in .rb
    autocmd BufRead,BufNewFile {Rakefile,Guardfile} set filetype=ruby
  augroup END

  set cursorline
  augroup CursorLine
    autocmd!

    " Only highlight cursor line in active buffer window
    autocmd WinLeave * set nocursorline
    autocmd WinEnter * set cursorline
  augroup END

  highlight! link TrailingWhitespace Error
  augroup TrailingWhiteSpace
    autocmd!
    autocmd BufWinEnter * if &modifiable | match TrailingWhitespace /\s\+$/ | endif
    autocmd InsertEnter * if &modifiable | match TrailingWhitespace /\s\+\%#\@<!$/ | endif
    autocmd InsertLeave * if &modifiable | match TrailingWhitespace /\s\+$/ | endif
    autocmd BufWinLeave * if &modifiable | call clearmatches() | endif
  augroup END
endif

" }}}
" MAPPINGS                                                                     {{{
" --------------------------------------------------------------------------------

" Make Y consistent with C and D
nnoremap Y y$

" Linewise movement should work on screen lines
noremap k gk
noremap j gj
noremap gk k
noremap gj j

noremap <Down> <C-w>+
noremap <Up> <C-w>-
noremap <Left> <C-w><
noremap <Right> <C-w>>

" Turn off highlighting and clear any message already displayed
nnoremap <silent> <C-l> :nohlsearch<CR><C-l>

" Expand %% to directory of current file in command-line mode
cnoremap %% <C-r>=fnameescape(expand("%:h"))."/"<CR>

" Convenient ways to open files relative to current buffer
map <Leader>ew :edit %%
map <Leader>es :split %%
map <Leader>ev :vsplit %%
map <Leader>et :tabedit %%

" Use character under cursor as first character in digraph and replace it
" Ex.:
"   Pressing <Leader>k- on the 'e' in
"     habere
"   Makes
"     habēre
nnoremap <expr> <Leader>k <SID>NormalModeDigraph(nr2char(getchar()))

" :help dispatch-commands
nnoremap <F2> :Make<CR>
nnoremap <F3> :Dispatch<CR>

" Write buffer and source current file
nnoremap <silent> <Leader>w :write<CR>:source %<CR>

" Write a one-off timestamped version of the current buffer
nnoremap <Leader>T :write %:p:r_<C-r>=strftime('%Y%m%d-%H%M%S')<CR>.%:e<CR>

" Source selection or current line
xnoremap <Leader>S y:execute @@<CR>:echomsg "Sourced selection"<CR>
nnoremap <Leader>S ^vg_y:execute @@<CR>:echomsg "Sourced current line"<CR>

" Remove trailing whitespace, merge consecutive empty lines
nnoremap <silent> <Leader>W :call <SID>NormalizeWhitespace()<CR>

" Re-indent entire buffer
nnoremap <silent> <Leader>= :call <SID>Preserve("normal! gg=G")<CR>

" sleuth.vim likes to change 'shiftwidth' to 8
nnoremap <Leader>4 :setlocal tabstop=4 softtabstop=4 shiftwidth=4<CR>

" Show highlighting groups for current word
nnoremap <silent> <Leader>p :call <SID>SynStack()<CR>

" Shortcuts for Fugitive plug-in
nnoremap <Leader>gg :Git<Space>
nnoremap <Leader>gw :Gwrite<CR>
nnoremap <Leader>gr :Gread<CR>
nnoremap <Leader>gs :Gstatus<CR>
nnoremap <Leader>gc :Gcommit<CR>
nnoremap <Leader>gd :Gdiff<CR>
nnoremap <Leader>gl :Glog<CR>
nnoremap <Leader>gb :Gblame<CR>
xnoremap <Leader>gb :Gblame<CR>
nnoremap <Leader>gm :Gmove<Space>
nnoremap <Leader>g/ :Ggrep<Space>

" Git Gutter plug-in complements Fugitive
nnoremap <Leader>gu :GitGutterToggle<CR>
nnoremap <Leader>gh :GitGutterLineHighlightsToggle<CR>

" Shortcuts for delimitMate
nnoremap <Leader>dd :DelimitMateSwitch<CR>
nnoremap <Leader>dr :DelimitMateReload<CR>

" Traversing folds
nnoremap <C-k> zMzkzv[zzt
nnoremap <C-j> zMzjzvzt

" Switch to alternate window or buffer
nnoremap <silent> <Leader><Leader> :if winnr("$") > 1<Bar>wincmd p<Bar>else<Bar>buffer #<Bar>endif<CR>

nnoremap <Leader><CR> *<C-o>
map <BS> %

" Unimpaired.vim-like toggles
nnoremap [oo :set colorcolumn=+1<CR>
nnoremap ]oo :set colorcolumn=0<CR>
nnoremap coo :let &colorcolumn = ( &colorcolumn == "+1" ? "0" : "+1" )<CR>

" <Space> mappings for finding files
nnoremap <Space><Space> :CtrlP<CR>
nnoremap <Space>. :CtrlP .<CR>
nnoremap <Space>; :CtrlPBuffer<CR>
nnoremap <Space>~ :CtrlP $HOME<CR>
nnoremap <Space>, :CtrlPTag<CR>
nnoremap <Space>? :CtrlPMRU<CR>
nnoremap <Space>/ :vimgrep // **/*.<C-r>=expand("%:e")<CR>
  \ <Home><Right><Right><Right><Right><Right><Right><Right><Right><Right>
nnoremap <Space>D :edit README.md<CR>
nnoremap <Space>E :edit Gemfile<CR>
nnoremap <Space>G :edit $HOME/.dots/vim/gvimrc<CR>
nnoremap <Space>H :edit .htaccess<CR>
nnoremap <Space>L :edit $HOME/.vimrc.local<CR>
nnoremap <Space>M :edit Makefile<CR>
nnoremap <Space>N :edit $DOCS/vim.md<CR>
nnoremap <Space>R :edit Rakefile<CR>
nnoremap <Space>U :edit Guardfile<CR>
nnoremap <Space>V :edit $HOME/.dots/vim/vimrc<CR>
nnoremap <Space>c :CtrlP $HOME/.dots<CR>
nnoremap <Space>d :CtrlP $DOCS<CR>
nnoremap <Space>ka :CtrlP application<CR>
nnoremap <Space>kc :CtrlP application/classes/Controller<CR>
nnoremap <Space>ke :CtrlP application/messages<CR>
nnoremap <Space>kl :CtrlP application/logs<CR>
nnoremap <Space>km :CtrlP application/classes/Model<CR>
nnoremap <Space>ko :CtrlP application/config<CR>
nnoremap <Space>kt :CtrlP application/templates<CR>
nnoremap <Space>kv :CtrlP application/classes/View<CR>
nnoremap <Space>n :CtrlP $NOTES<CR>
nnoremap <Space>p :CtrlP $PROJECTS<CR>
nnoremap <Space>v :CtrlP $HOME/.vim<CR>

" }}}
" PLUG-INS                                                                     {{{
" --------------------------------------------------------------------------------

" :help ruby.vim
let g:ruby_fold = 1
let g:ruby_no_comment_fold = 1

" :help netrw-browser-options
let g:netrw_banner = 0

" :help menu.vim
let g:did_install_default_menus = 1
let g:did_install_syntax_menu = 1

" :help GitGutterCustomisation
if &termencoding ==# "utf-8" || &encoding ==# "utf-8"
  let g:gitgutter_sign_modified_removed = "\u2243"
endif

" :help syntastic-global-options
if &termencoding ==# "utf-8" || &encoding ==# "utf-8"
  let g:syntastic_error_symbol = "\u24a0 "
  let g:syntastic_warning_symbol = "\u24b2 "
  let g:syntastic_style_error_symbol = "\u00a7"
  let g:syntastic_style_warning_symbol = "\u00a7"
endif
let g:syntastic_enable_highlighting = 0
let g:syntastic_stl_format = ' %E{%e' . g:syntastic_error_symbol
let g:syntastic_stl_format .= ' (line %fe)}'
let g:syntastic_stl_format .= '%B{ }'
let g:syntastic_stl_format .= '%W{%w' . g:syntastic_warning_symbol
let g:syntastic_stl_format .= ' (line %fw)} '

" :help syntastic-config-makeprg
" Don't complain about indentation with tabs, set encoding
let g:syntastic_php_phpcs_post_args = "--tab-width=4 --encoding=utf-8"
" Use PSR2 standard instead of default PEAR
" http://www.php-fig.org/psr/2/
let g:syntastic_php_phpcs_post_args .= " --standard=PSR2"

" xptemplate key
let g:xptemplate_key = "<Tab>"

" UltiSnips settings
let g:UltiSnipsExpandTrigger = "<Tab>"
let g:UltiSnipsJumpForwardTrigger = "<Tab>"
let g:UltiSnipsJumpBackwardTrigger = "<S-Tab>"
let g:UltiSnipsSnippetDir = "~/.vim/snippets"
let g:UltiSnipsSnippetDirectories = ["snippets"]

" Reverse Command-T match list so best result appears at bottom
let g:CommandTMatchWindowReverse = 1
let g:CommandTMaxHeight = 12

" :help ctrlp-options
let g:ctrlp_extensions = ["tag"]
let g:ctrlp_user_command = [".git", "cd %s && git ls-files . -co --exclude-standard"]

" delimitMate settings
let g:delimitMate_expand_cr = 1
let g:delimitMate_expand_space = 1
let g:delimitMate_balance_matchpairs = 1

" :help supertab-options
let g:SuperTabDefaultCompletionType = "context"
let g:SuperTabLongestEnhanced = 1
let g:SuperTabLongestHighlight = 1

" :help supertab-completionchaining
if has("autocmd")
  augroup SuperTabRC
    autocmd!
    autocmd FileType *
      \ if exists("*SuperTabChain") && &omnifunc != "" |
      \   call SuperTabChain(&omnifunc, "<C-p>") |
      \   call SuperTabSetDefaultCompletionType("<C-x><C-u>") |
      \ endif
  augroup END
endif

" }}}
" LOCAL VIMRC                                                                  {{{
" --------------------------------------------------------------------------------

" Local
if filereadable(glob("~/.vimrc.local"))
  source ~/.vimrc.local
endif

" }}}
" vim: fdm=marker:sw=2:sts=2:et

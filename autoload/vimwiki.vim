" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

"
" Init functions
"
function! vimwiki#init() " {{{1
  let g:vimwiki = {}
  let g:vimwiki.root = g:vimwiki_path
  let g:vimwiki.diary = g:vimwiki_path . 'journal/'

  "
  " Define mappings
  "
  nnoremap <silent> <leader>ww         :call vimwiki#goto_index()<cr>
  nnoremap <silent> <leader>wx         :call vimwiki#reload()<cr>
  nnoremap <silent> <leader>w<leader>w :call vimwiki#diary#make_note()<cr>
endfunction

" }}}1
function! vimwiki#init_buffer() " {{{1
  setlocal nolisp
  setlocal nomodeline
  setlocal nowrap
  setlocal foldmethod=expr
  setlocal foldexpr=vimwiki#fold#level(v:lnum)
  setlocal foldtext=vimwiki#fold#text()
  setlocal omnifunc=vimwiki#complete#omnicomplete
  setlocal suffixesadd=.wiki
  setlocal isfname-=[,]
  setlocal autoindent
  setlocal nosmartindent
  setlocal nocindent
  setlocal comments =:*\ TODO:,b:*\ [\ ],b:*\ [X],b:*
  setlocal comments+=:-\ TODO:,b:-\ [\ ],b:-\ [X],b:-
  setlocal formatoptions-=o
  setlocal formatoptions+=n
  let &l:formatlistpat = '\v^\s*%(\d|\l|i+)\.\s'

  let b:vimwiki = {
        \ 'in_diary' : stridx(
        \   resolve(expand('%:p')),
        \   resolve(g:vimwiki.diary)) == 0
        \ }

  call vimwiki#define_regexes()

  "
  " Autocommands
  "
  augroup vimwiki
    autocmd!
    autocmd BufWinEnter *.wiki setlocal conceallevel=2
  augroup END

  "
  " Keybindings
  "
  nnoremap <silent><buffer> <leader>wt :call vimwiki#page#create_toc()<cr>
  nnoremap <silent><buffer> <leader>wb :call vimwiki#get_backlinks()<cr>
  nnoremap <silent><buffer> <leader>wd :call vimwiki#page#delete()<cr>
  nnoremap <silent><buffer> <leader>wr :call vimwiki#page#rename()<cr>
  nnoremap <silent><buffer> <tab>      :call vimwiki#nav#next_link()<cr>
  nnoremap <silent><buffer> <s-tab>    :call vimwiki#nav#prev_link()<cr>
  nnoremap <silent><buffer> <bs>       :call vimwiki#nav#return()<cr>
  nnoremap <silent><buffer> <cr>       :call vimwiki#link#follow()<cr>
  nnoremap <silent><buffer> <leader>wf :call vimwiki#link#toggle()<cr>
  nnoremap <silent><buffer> <c-cr>     :call vimwiki#link#follow('vsplit')<cr>
  vnoremap <silent><buffer> <cr>       :<c-u>call vimwiki#link#toggle_visual()<cr>
  if b:vimwiki.in_diary
    nnoremap <silent><buffer> <c-j> :<c-u>call vimwiki#diary#go(-v:count1)<cr>
    nnoremap <silent><buffer> <c-k> :<c-u>call vimwiki#diary#go(v:count1)<cr>
    nnoremap <silent><buffer> <leader>wk :call vimwiki#diary#copy_note()<cr>
  else
    nnoremap <silent><buffer> <c-j>      :call vimwiki#diary#make_note()<cr>
    nnoremap <silent><buffer> <c-k>      :call vimwiki#diary#make_note()<cr>
  endif
endfunction

" }}}1

"
" Miscellaneous
"
function! vimwiki#define_regexes() " {{{
  "
  " Define link matchers
  "
  let l:rx_url = '\<\l\+:\%(//\)\?[^ \t()\[\]]\+'
  let g:vimwiki.link_matcher = {}
  let g:vimwiki.link_matcher.url = {
        \ 'template' : '__Url__',
        \ 'rx_full' : l:rx_url,
        \ 'rx_url' : l:rx_url,
        \ 'rx_text' : '',
        \ 'syntax' : 'VimwikiLinkUrl',
        \}
  let g:vimwiki.link_matcher.wiki = {
        \ 'template' : [
        \   '[[__Url__]]',
        \   '[[__Url__|__Text__]]',
        \ ],
        \ 'rx_full' : '\[\[\/\?[^\\\]]\{-}\%(|[^\\\]]\{-}\)\?\]\]',
        \ 'rx_url' : '\[\[\zs\/\?[^\\\]]\{-}\ze\%(|[^\\\]]\{-}\)\?\]\]',
        \ 'rx_text' : '\[\[\/\?[^\\\]]\{-}|\zs[^\\\]]\{-}\ze\]\]',
        \ 'syntax' : 'VimwikiLinkWiki',
        \}
  let g:vimwiki.link_matcher.md = {
        \ 'template' : '[__Text__](__Url__)',
        \ 'rx_full' : '\[[^\\]\{-}\]([^\\]\{-})',
        \ 'rx_url' : '\[[^\\]\{-}\](\zs[^\\]\{-}\ze)',
        \ 'rx_text' : '\[\zs[^\\]\{-}\ze\]([^\\]\{-})',
        \ 'syntax' : 'VimwikiLinkMd',
        \}
  let g:vimwiki.link_matcher.ref = {
        \ 'template' : [
        \   '[__Url__]',
        \   '[__Text__][__Url__]',
        \ ],
        \ 'rx_full' : '[\]\[]\@<!\['
        \   . '[^\\\[\]]\{-}\]\[\%([^\\\[\]]\{-}\)\?'
        \   . '\][\]\[]\@!',
        \ 'rx_url' : '[\]\[]\@<!\['
        \   . '\%(\zs[^\\\[\]]\{-}\ze\]\[\|[^\\\[\]]\{-}\]\[\zs[^\\\[\]]\{-1,}\ze\)'
        \   . '\][\]\[]\@!',
        \ 'rx_text' : '[\]\[]\@<!\['
        \   . '\zs[^\\\[\]]\{-}\ze\]\[[^\\\[\]]\{-1,}'
        \   . '\][\]\[]\@!',
        \ 'syntax' : 'VimwikiLinkRef',
        \}
  let g:vimwiki.link_matcher.ref_target = {
        \ 'template' : '[__Text__]: __Url__',
        \ 'rx_full' : '\[[^\\\]]\{-}\]:\s\+' . l:rx_url,
        \ 'rx_url' : '\[[^\\\]]\{-}\]:\s\+\zs' . l:rx_url . '\ze',
        \ 'rx_text' : '\[\zs[^\\\]]\{-}\ze\]:\s\+' . l:rx_url,
        \ 'syntax' : 'VimwikiLinkRefTarget',
        \}

  "
  " Define regexes
  "
  let g:vimwiki.rx = {}

  let g:vimwiki.rx.link = join(map(
        \   values(g:vimwiki.link_matcher),
        \   'v:val.rx_full'),
        \ '\|')

  let g:vimwiki_bullet_types = { '-':0, '*':0, '+':0 }
  let g:vimwiki_number_types = ['1.']
  let g:vimwiki_list_markers = ['-', '*', '+', '1.']

  let g:vimwiki.rx.word = '[^[:blank:]!"$%&''()*+,:;<=>?\[\]\\^`{}]\+'

  let g:vimwiki.rx.preStart = '^\s*```'
  let g:vimwiki.rx.preEnd = '^\s*```\s*$'

  let g:vimwiki.rx.italic = vimwiki#rx#generate_bold_italic('_')
  let g:vimwiki.rx.bold = vimwiki#rx#generate_bold_italic('*')
  let g:vimwiki.rx.boldItalic = vimwiki#rx#generate_bold_italic('*_')
  let g:vimwiki.rx.italicBold = vimwiki#rx#generate_bold_italic('_*')

  let g:vimwiki.rx.superScript = '\^[^^`]\+\^'
  let g:vimwiki.rx.subScript = ',,[^,`]\+,,'
  let g:vimwiki.rx.listDefine = '::\%(\s\|$\)'
  let g:vimwiki.rx.comment = '^\s*%%.*$'
  let g:vimwiki.rx.todo = '\C\%(TODO\|DONE\|STARTED\|FIXME\|FIXED\):\?'
  let g:vimwiki.rx.header = '^#\{1,6}\s*[^#].*'
  let g:vimwiki.rx.header_items = '^\(#\{1,6}\)\s*\([^#].*\)\s*$'
endfunction

" }}}1
function! vimwiki#goto_index() " {{{1
  call vimwiki#url#parse('wiki:/index').open()
endfunction

" }}}1
" {{{1 function! vimwiki#reload()
let s:file = expand('<sfile>')
if !exists('s:reloading_script')
  function! vimwiki#reload()
    let s:reloading_script = 1

    " Reload autoload scripts
    for l:file in [s:file]
          \ + split(globpath(fnamemodify(s:file, ':r'), '*.vim'), '\n')
      execute 'source' l:file
    endfor

    " Reload plugin
    if exists('g:vimwiki_loaded')
      unlet g:vimwiki_loaded
      runtime plugin/vimwiki.vim
    endif

    " Reload ftplugin and syntax
    if &filetype == 'vimwiki'
      unlet b:did_ftplugin
      runtime ftplugin/vimwiki.vim

      if get(b:, 'current_syntax', '') ==# 'vimwiki'
        unlet b:current_syntax
        runtime syntax/vimwiki.vim
      endif
    endif

    unlet s:reloading_script
  endfunction
endif

" }}}1
function! vimwiki#get_backlinks() "{{{1
  let l:origin = expand("%:p")
  let l:locs = []

  for l:file in globpath(g:vimwiki.root, '**/*.wiki', 0, 1)
    if resolve(l:file) ==# resolve(l:origin) | break | endif

    for l:link in vimwiki#page#get_links(l:file)
      if resolve(l:link.filename) ==# resolve(l:origin)
        call add(l:locs, {
              \ 'filename' : l:file,
              \ 'text' : empty(l:link.anchor) ? '' : 'Anchor: ' . l:anchor,
              \ 'lnum' : l:link.lnum,
              \ 'col' : l:link.col
              \})
      endif
    endfor
  endfor

  if empty(l:locs)
    echomsg 'Vimwiki: No other file links to this file'
  else
    call setloclist(0, l:locs, 'r')
    lopen
  endif
endfunction

"}}}1

" vim: fdm=marker sw=2

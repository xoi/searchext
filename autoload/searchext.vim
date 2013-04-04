function s:CreateContext(method, flags)
  return {
	\ 'regexp': function('searchext#method#' . a:method . '#Regexp'),
	\ 'flags' : a:flags
	\ }
endfunction

function searchext#FindChar(method, ...)
  let flags = a:0 < 1 ? '' : a:1
  let context = s:CreateContext(a:method, flags)
  let char = nr2char(getchar())
  let regexp = context.regexp(char)
  if s:CountSearch('\%' . line('.') . 'l' . regexp, flags . 'W') == 0
    return "\<Plug>"	" bell in noremap
  endif
  return s:MoveToCurrentColumn()
endfunction

cmap <expr> <Plug>(searchext#trap) <SID>Trap()
cmap <expr> <Plug>(searchext#hook) <SID>Hook()
noremap <Plug>(searchext#hook) <Nop>
noremap <expr> <Plug>(searchext#redraw) <SID>Redraw()

hi default link searchextIncSearchAll Search

function searchext#IncSearch(prompt, method, ...)
  let flags = a:0 < 1 ? '' : a:1
  let s:context = s:CreateContext(a:method, flags)

  try
    let showmode = &showmode
    let &showmode = 0
    call feedkeys("\<Plug>(searchext#trap)")
    let pattern = input(a:prompt)
    if pattern != '' && !(s:key == "\<Esc>" && maparg('<Esc>', 'c') == '')
      let @/ = s:regexp
      return (flags =~# 'b' ? '?' : '/') . "\<CR>"
    endif
  catch
  finally
    let &showmode = showmode
    call s:Init()
    echo ''
    call feedkeys("\<Plug>(searchext#redraw)")
  endtry
  return ''
endfunction

function s:Redraw()
  " redraw cursor and command-line (not move)
  return s:MoveToCurrentColumn()
endfunction

let s:multi_key = ['<C-V>', '<C-Q>', '<C-K>', '<C-R>', '<C-\>']
let s:multi_key_string = map(s:multi_key, 'eval(''"\'' . v:val . ''"'')')

" determine if key is hookable by rule of thumb
function s:Hookable(key)
  let mapping = maparg(a:key, 'c', 0, 1)
  if mapping == {} && mapcheck(a:key, 'c') != ''
    return 0
  endif
  if mapping == {}
    return index(s:multi_key_string, a:key) == -1
  endif
  if !mapping.noremap || mapping.expr
    return 1
  endif
  for i in s:multi_key_string
    if mapping.rhs =~ i
      return 0
    endif
  endfor
  return 1
endfunction

function s:Trap()
  let char = getchar()
  if type(char) == type(0)
    let char = nr2char(char)
    let s:key = char
  else
    call feedkeys("\<C-K>" . char . "\<CR>", 'n')
    let s:key = input('')
  endif
  if s:Hookable(s:key)
    call feedkeys("\<Plug>(searchext#hook)")
  endif
  return char
endfunction

function s:Hook()
  let s:regexp = s:context.regexp(getcmdline())
  call s:Init()
  try
    call add(s:state, ['s:MatchDelete', matchadd('searchextIncSearchAll', s:regexp)])
    call add(s:state, ['s:MatchDelete', matchadd('IncSearch', '\%#\%(' . s:regexp . '\)')])
    call add(s:state, ['winrestview', winsaveview()])
    call s:CountSearch(s:regexp, s:context.flags)
  catch
  endtry
  redraw
  return "\<Plug>(searchext#trap)"
endfunction

let s:state = []

function s:Init()
  for i in s:state
    call function(i[0])(i[1])
  endfor
  let s:state = []
endfunction

function s:MatchDelete(id)
  if 0 < a:id
    call matchdelete(a:id)
  endif
endfunction

function s:CountSearch(pattern, flags)
  let i = 0
  while i < v:count1
    let line = search('\C\m' . a:pattern, a:flags)
    if line == 0
      break	" not found
    endif
    let i += 1
  endwhile
  return line
endfunction

function s:ClearCount()
  return v:count ? repeat("\<Del>", len(v:count)) : ''
endfunction

function s:MoveToCurrentColumn()
  return s:ClearCount() . (winsaveview().curswant + 1) . '|'
endfunction

" autoload/jdaddy.vim
" Author: Tim Pope <http://tpo.pe/>

if exists("g:autoloaded_jdaddy")
  finish
endif
let g:autoloaded_jdaddy = 1

if !exists('g:jdaddy#null')
  let g:jdaddy#null = ['null']
  let g:jdaddy#false = ['false']
  let g:jdaddy#true = ['true']
endif

function! s:sub(str,pat,rep) abort
  return substitute(a:str,'\v\C'.a:pat,a:rep,'')
endfunction

function! s:gsub(str,pat,rep) abort
  return substitute(a:str,'\v\C'.a:pat,a:rep,'g')
endfunction

" Text Objects {{{1

function! jdaddy#inner_pos(...) abort
  let cnt = a:0 ? a:1 : 1
  let line = getline('.')
  let char = line[col('.')-1]
  if char ==# '"' || len(s:gsub(s:gsub(line[0 : col('.')-1], '\\.', ''), '[^"]', '')) % 2
    let cnt -= 1
    if !cnt
      let quotes = []
      for pos in range(len(line))
        if exists('skip')
          unlet skip
        elseif line[pos] ==# '\'
          let skip = 1
        elseif line[pos] ==# '"'
          let quotes += [pos]
        endif
      endfor
      let before = filter(copy(quotes), 'v:val <= col(".")-1')
      let after  = filter(copy(quotes), 'v:val > col(".")-1')
      if before[-1] == col('.')-1 && len(before) % 2 == 0
        return [line('.'), before[-2]+1, line('.'), before[-1]+1]
      else
        return [line('.'), before[-1]+1, line('.'), after[0]+1]
      endif
    endif
  elseif char =~# '[[:alnum:]._+-]'
    let cnt -= 1
    if !cnt
      let [start, end] = [col('.')-1, col('.')-1]
      while line[start-1] =~# '[[:alnum:]._+-]'
        let start -= 1
      endwhile
      while line[end+1] =~# '[[:alnum:]._+-]'
        let end += 1
      endwhile
      return [line('.'), start+1, line('.'), end+1]
    endif
  endif
  if char =~# '[]})]'
    let cnt -= 1
    let [lclose, cclose] = [line('.'), col('.')]
  else
    let [lclose, cclose] = searchpairpos('[[{(]', '', '[]})]', 'W')
  endif
  let [lopen, copen] = searchpairpos('[[{(]', '', '[]})]', 'Wb')
  if !lopen || !lclose
    return [0, 0, 0, 0]
  endif
  return [lopen, copen, lclose, cclose]
endfunction

function! jdaddy#outer_pos(...) abort
  if getline('.')[col('.')-1] =~# '[]}]'
    let [lclose, cclose] = [line('.'), col('.')]
  else
    let [lclose, cclose] = searchpairpos('[[{]', '', '[]}]', 'r')
  endif
  let [lopen, copen] = searchpairpos('[[{]', '', '[]}]', 'rb')
  if lopen && lclose
    return [lopen, copen, lclose, cclose]
  endif
  return [0, 0, 0, 0]
endfunction

function! s:movement_string(line, col) abort
  return a:line . "G0" . (a:col > 1 ? (a:col - 1) . "l" : "")
endfunction

function! jdaddy#inner_movement(count) abort
  let [lopen, copen, lclose, cclose] = jdaddy#inner_pos(a:count)
  if !lopen
    return "\<Esc>"
  endif
  call setpos("'[", [0, lopen, copen, 0])
  call setpos("']", [0, lclose, cclose, 0])
  return "`[o`]"
endfunction

function! jdaddy#outer_movement(count) abort
  let [lopen, copen, lclose, cclose] = jdaddy#outer_pos(a:count)
  if !lopen
    return "\<Esc>"
  endif
  call setpos("'[", [0, lopen, copen, 0])
  call setpos("']", [0, lclose, cclose, 0])
  return s:movement_string(lopen, copen) . 'o' . s:movement_string(lclose, cclose)
endfunction

" }}}1

function! jdaddy#parse(string) abort
  let [null, false, true] = [g:jdaddy#null, g:jdaddy#false, g:jdaddy#true]
  let one_line = substitute(a:string, "[\r\n]\\s*", ' ', 'g')
  let quoted_keys = substitute(one_line,
        \ '\C"\(\\.\|[^"\\]\)*"\|\w\+\ze:\|[[:,]\s*\zs\h\w*\ze\s*[]},]',
        \ '\=submatch(0) =~# "^\\%(\"\\|true$\\|false$\\|null$\\)" ? submatch(0) : "\"\002" . submatch(0) . "\""',
        \ 'g')
  let stripped = substitute(quoted_keys,'\C"\(\\.\|[^"\\]\)*"','','g')
  if stripped !~# "[^,:{}\\[\\]0-9.\\-+Eaeflnr-u \n\r\t]"
    try
      return eval(quoted_keys)
    catch
    endtry
  endif
  throw "jdaddy: invalid JSON: ".one_line
endfunction

let s:escapes = {
      \ "\b": '\b',
      \ "\f": '\f',
      \ "\n": '\n',
      \ "\r": '\r',
      \ "\t": '\t',
      \ "\"": '\"',
      \ "\\": '\\'}

function! jdaddy#dump(object, ...) abort
  let opt = extend({'width': 0, 'level': 0, 'indent': 1, 'before': 0, 'seen': []}, a:0 ? copy(a:1) : {})
  let opt.seen = copy(opt.seen)
  let childopt = copy(opt)
  let childopt.before = 0
  let childopt.level += 1
  let indent = repeat(' ', opt.indent)
  for i in range(len(opt.seen))
    if a:object is opt.seen[i]
      return type(a:object) == type([]) ? '[...]' : '{...}'
    endif
  endfor
  if a:object is g:jdaddy#null
    return 'null'
  elseif a:object is g:jdaddy#false
    return 'false'
  elseif a:object is g:jdaddy#true
    return 'true'
  elseif type(a:object) ==# type('')
    if a:object =~# '^\%x02.'
      let dump = a:object[1:-1]
    else
      let dump = '"'.s:gsub(a:object, "[\001-\037\"\\\\]", '\=get(s:escapes, submatch(0), printf("\\u%04x", char2nr(submatch(0))))').'"'
    endif
  elseif type(a:object) ==# type([])
    let childopt.seen += [a:object]
    let dump = '['.join(map(copy(a:object), 'jdaddy#dump(v:val, {"seen": childopt.seen, "level": childopt.level})'), ', ').']'
    if opt.width && opt.before + opt.level * opt.indent + len(s:gsub(dump, '.', '.')) > opt.width
      let space = repeat(indent, opt.level)
      let dump = '[' . join(map(copy(a:object), '"\n".indent.space.jdaddy#dump(v:val, childopt)'), ",") . "\n" . space . ']'
    endif
  elseif type(a:object) ==# type({})
    let childopt.seen += [a:object]
    let keys = sort(keys(a:object))
    let dump = '{'.join(map(copy(keys), 'jdaddy#dump(v:val) . ": " . jdaddy#dump(a:object[v:val], {"seen": childopt.seen, "indent": childopt.indent, "level": childopt.level})'), ', ').'}'
    if opt.width && opt.before + opt.level * opt.indent + len(s:gsub(dump, '.', '.')) > opt.width
      let space = repeat(indent, opt.level)
      let lines = []
      let last = get(keys, -1, '')
      for k in keys
        let prefix = jdaddy#dump(k) . ':'
        let suffix = jdaddy#dump(a:object[k]) . ','
        if len(space . prefix . ' ' . suffix) >= opt.width - (k ==# last ? -1 : 0)
          call extend(lines, [prefix . ' ' . jdaddy#dump(a:object[k], extend(copy(childopt), {'before': len(prefix)+1})) . ','])
        else
          call extend(lines, [prefix . ' ' . suffix])
        endif
      endfor
      let dump = s:sub("{\n" . indent . space . join(lines, "\n" . indent . space), ',$', "\n" . space . '}')
    endif
  else
    let dump = string(a:object)
  endif
  return dump
endfunction

function! jdaddy#reformat(func, count, ...) abort
  let [lopen, copen, lclose, cclose] = call(a:func, [a:count])
  if !lopen
    return ''
  endif
  if lopen == lclose
    let body = getline(lopen)[copen-1 : cclose-1]
  else
    let body = getline(lopen)[copen-1 : -1] . join(getline(lopen+1, lclose-1), "\n") . getline(lclose)[0 : cclose-1]
  endif
  try
    if a:0
      let json = jdaddy#combine(jdaddy#parse(body), jdaddy#parse(getreg(a:1)))
    else
      let json = jdaddy#parse(body)
    endif
  catch /^jdaddy:/
    return 'echoerr '.string(v:exception)
  endtry
  let level = indent(lopen)/&sw
  let dump =
        \ (copen == 1 ? '' : getline(lopen)[0 : copen-2]) .
        \ jdaddy#dump(json, {'width': (&tw ? &tw : 79), 'indent': &sw, 'level': level, 'before': copen-1-level}) .
        \ getline(lclose)[cclose : -1]
  call append(lclose, split(dump, "\n"))
  silent exe lopen.','.lclose.'delete _'
  call setpos('.', [0, lopen, copen, 0])
  silent! call repeat#set(":call jdaddy#reformat(".string(a:func).",".string(a:count).(a:0 ? ",".string(a:1) : "").")\<CR>")
  return ''
endfunction

function! jdaddy#combine(one, two) abort
  if a:one is g:jdaddy#null || a:one is g:jdaddy#false
    return a:two
  elseif a:two is g:jdaddy#null || a:two is g:jdaddy#false
    return a:one
  elseif a:one is g:jdaddy#true
    return a:one
  elseif type(a:one) != type(a:two)
    throw "jdaddy: Can't combine disparate types"
  elseif type(a:one) == type({})
    return extend(copy(a:one), a:two)
  elseif type(a:one) == type('')
    return a:one . a:two
  else
    return a:one + a:two
  endif
endfunction

" vim:set et sw=2:

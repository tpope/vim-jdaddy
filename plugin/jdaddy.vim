" plugin/jdaddy.vim
" Author: Tim Pope <http://tpo.pe/>

if exists("g:loaded_jdaddy") || v:version < 700 || &cp
  finish
endif
let g:loaded_jdaddy = 1

xnoremap <expr>   ij jdaddy#inner_movement(v:count1)
onoremap <silent> ij :normal vij<CR>
xnoremap <expr>   aj jdaddy#outer_movement(v:count1)
onoremap <silent> aj :normal vaj<CR>

nnoremap <silent> gqij :exe jdaddy#reformat('jdaddy#inner_pos', v:count1)<CR>
nnoremap <silent> gqaj :exe jdaddy#reformat('jdaddy#outer_pos', v:count1)<CR>
nnoremap <silent> gwij :exe jdaddy#reformat('jdaddy#inner_pos', v:count1, v:register)<CR>
nnoremap <silent> gwaj :exe jdaddy#reformat('jdaddy#outer_pos', v:count1, v:register)<CR>

" vim:set et sw=2:

if exists('g:loaded_textobj_chunk')
    finish
endif

let s:save_cpo = &cpo
set cpo&vim

call textobj#user#plugin('chunk', {
    \ '-' : {
    \      'select-a' : 'ac', '*select-a-function*' : 'textobj#chunk#select_a',
    \      'select-i' : 'ic', '*select-i-function*' : 'textobj#chunk#select_i',
    \   },
    \ })

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_textobj_chunk = 1

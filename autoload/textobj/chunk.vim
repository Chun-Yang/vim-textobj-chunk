let s:save_cpo = &cpo
set cpo&vim

let g:textobj#chunk#blocks = get(g:, 'textobj#chunk#blocks',
            \ [ '(', '{', '[', '<' ])
let g:textobj#chunk#min_block_size = get(g:, 'textobj#chunk#min_block_size', 2)

function! textobj#chunk#select_i()
    return s:select('a')
endfunction

function! textobj#chunk#select_a()
    return s:select('a')
endfunction

function! s:select(chunk)
    let save_screen_begin = line('w0')
    let current_pos = getpos('.')
    let final_region = [current_pos, current_pos]

    " search end of line first
    let region_from_end = s:search_end(a:chunk)
    call s:restore_screen_pos(save_screen_begin)

    if len(region_from_end) == 2
        let final_region = region_from_end
    else
        " search around
        let region_from_around = s:search_around(a:chunk)
        call s:restore_screen_pos(save_screen_begin)
        if len(region_from_around) == 2
            let final_region = region_from_around
        endif
    endif

    if final_region[0] == final_region[1]
      return 0
    endif

    " beginning of the line
    let start_pos    = final_region[0]
    let start_pos[2] = 1
    " end of the line, +1 is used to delete the line break at the end
    let end_pos      = final_region[1]
    let end_pos[2]   = strlen(getline(end_pos[1])) + 1
    return ['v', start_pos, end_pos]
endfunction

" check the end of the current line, see if it is one of the brackets
function! s:search_end(chunk)
    let current_line      = getline(line('.'))
    let last_char_of_line = matchstr(current_line, "\[{}()[\\]<>\]$")
    if len(last_char_of_line) == 0
        return 0
    else
        let origin_pos = getpos('.')
        execute 'silent!' 'normal!'  '$v'.a:chunk.last_char_of_line
        execute 'silent!' 'normal!' "\<Esc>"
        call setpos('.', origin_pos)
        return [getpos("'<"), getpos("'>")]
    endif
endfunction

" check around the current cursor
function! s:search_around(chunk)
    for block in get(b:, 'textobj_chunk_local_blocks', []) + g:textobj#chunk#blocks
        let r = s:get_region(a:chunk.block)
        if s:is_empty_region(r) || s:cursor_is_out_of_region(r)
            continue
        endif

        let e = s:region_extent(r)
        if e < g:textobj#chunk#min_block_size
            continue
        endif

        if !exists('l:min_region_extent') || min_region_extent > e
            let min_region_extent = e
            let min_region = r
        endif
    endfor

    return exists('l:min_region') ? min_region : 0
endfunction

function! s:restore_screen_pos(before_screen_begin)
    let line_diff = line('w0') - a:before_screen_begin
    if line_diff > 0
        execute 'normal!' line_diff."\<C-y>"
    elseif line_diff < 0
        execute 'normal!' (-line_diff)."\<C-e>"
    endif
endfunction

function! s:region_extent(region)
    let extent = 0

    for line in range(a:region[0][1], a:region[1][1])
        let line_width = strlen(getline(line))
        let width = line_width

        if line == a:region[0][1]
            let width -= a:region[0][2] - 1
        endif

        if line == a:region[1][1]
            let width -= line_width - a:region[1][2]
        endif

        let extent += width
    endfor

    return extent
endfunction

function! s:get_region(textobj)
    let pos = getpos('.')
    normal! v
    execute 'silent!' 'normal'  a:textobj
    execute 'silent!' 'normal!' "\<Esc>"
    call setpos('.', pos)
    return [getpos("'<"), getpos("'>")]
endfunction

function! s:is_empty_region(region)
    return a:region[1][1] < a:region[0][1] || (a:region[0][1] == a:region[1][1] && a:region[1][2] <= a:region[0][2])
endfunction


function! s:cursor_is_out_of_region(region)
    let [_, line, col, _] = getpos('.')

    if line < a:region[0][1] || (line == a:region[0][1] && col < a:region[0][2])
        return 1
    endif

    if line > a:region[1][1] || (line == a:region[1][1] && col > a:region[1][2])
        return 1
    endif

    return 0
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" FILE:     plugin/dupe.vim
" AUTHOR:   Nico Raffo <nicoraffo@gmail.com>
" MODIFIED: __MODIFIED__
" VERSION:  __VERSION__, for Vim 7.0
" LICENSE: {{{
" Conque - pty interaction in Vim
" Copyright (C) 2009 Nico Raffo 
"
" MIT License
" 
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
" 
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
" 
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
" THE SOFTWARE.
" }}}

" TODO ------------------------------------------------
"  
"  * Rewrite color handling
"  * Look for better methods for mapping all keys
"  * find "good" solution to meta keys (possibly Config option to send <Esc>)
"  * Escapes: full K/J, \eE, \eH, CSIg
"  * Look for performance shortcuts
"  * Figure out how to run background checks without leaving insert mode
"

if exists('g:Loaded_ConqueExperimental') || v:version < 700
  finish
endif

setlocal encoding=utf-8

" Mappable characters
let s:chars_control      = 'abcdefghijklmnopqrstuwxyz?]\'
let s:chars_meta         = 'abcdefghijklmnopqrstuvwxyz'

" add locale-specific chars here
let s:chars_extra        = ''

" Escape sequences {{{
let s:escape_sequences = { 
\ 'm':'font',
\ 'J':'clear_screen',
\ 'K':'clear_line',
\ '@':'add_spaces',
\ 'A':'cursor_up',
\ 'B':'cursor_down',
\ 'C':'cursor_right',
\ 'D':'cursor_left',
\ 'G':'cursor_to_column',
\ 'H':'cursor',
\ 'L':'insert_lines',
\ 'M':'delete_lines',
\ 'P':'delete_chars',
\ 'd':'cusor_vpos',
\ 'f':'cursor',
\ 'g':'tab_clear',
\ 'r':'set_coords'
\ } 
" }}}

" Alternate escape sequences, no [ {{{
let s:escape_sequences_plain = {
\ 'D':'scroll_up',
\ 'E':'next_line',
\ 'H':'set_tab',
\ 'M':'scroll_down',
\ 'N':'single_shift_2',
\ 'O':'single_shift_3',
\ '=':'alternate_keypad',
\ '>':'numeric_keypad',
\ '7':'save_cursor',
\ '8':'restore_cursor'
\ }
" }}}

" Font codes {{{
let s:font_codes = {
\ '0': {'description':'Normal (default)', 'attributes': {'cterm':'NONE','ctermfg':'NONE','ctermbg':'NONE','gui':'NONE','guifg':'NONE','guibg':'NONE'}, 'normal':1},
\ '00': {'description':'Normal (default) alternate', 'attributes': {'cterm':'NONE','ctermfg':'NONE','ctermbg':'NONE','gui':'NONE','guifg':'NONE','guibg':'NONE'}, 'normal':1},
\ '1': {'description':'Bold', 'attributes': {'cterm':'BOLD','gui':'BOLD'}, 'normal':0},
\ '01': {'description':'Bold', 'attributes': {'cterm':'BOLD','gui':'BOLD'}, 'normal':0},
\ '4': {'description':'Underlined', 'attributes': {'cterm':'UNDERLINE','gui':'UNDERLINE'}, 'normal':0},
\ '04': {'description':'Underlined', 'attributes': {'cterm':'UNDERLINE','gui':'UNDERLINE'}, 'normal':0},
\ '5': {'description':'Blink (appears as Bold)', 'attributes': {'cterm':'BOLD','gui':'BOLD'}, 'normal':0},
\ '05': {'description':'Blink (appears as Bold)', 'attributes': {'cterm':'BOLD','gui':'BOLD'}, 'normal':0},
\ '7': {'description':'Inverse', 'attributes': {'cterm':'REVERSE','gui':'REVERSE'}, 'normal':0},
\ '07': {'description':'Inverse', 'attributes': {'cterm':'REVERSE','gui':'REVERSE'}, 'normal':0},
\ '8': {'description':'Invisible (hidden)', 'attributes': {'ctermfg':'0','ctermbg':'0','guifg':'#000000','guibg':'#000000'}, 'normal':0},
\ '08': {'description':'Invisible (hidden)', 'attributes': {'ctermfg':'0','ctermbg':'0','guifg':'#000000','guibg':'#000000'}, 'normal':0},
\ '22': {'description':'Normal (neither bold nor faint)', 'attributes': {'cterm':'NONE','gui':'NONE'}, 'normal':1},
\ '24': {'description':'Not underlined', 'attributes': {'cterm':'NONE','gui':'NONE'}, 'normal':1},
\ '25': {'description':'Steady (not blinking)', 'attributes': {'cterm':'NONE','gui':'NONE'}, 'normal':1},
\ '27': {'description':'Positive (not inverse)', 'attributes': {'cterm':'NONE','gui':'NONE'}, 'normal':1},
\ '28': {'description':'Visible (not hidden)', 'attributes': {'ctermfg':'NONE','ctermbg':'NONE','guifg':'NONE','guibg':'NONE'}, 'normal':1},
\ '30': {'description':'Set foreground color to Black', 'attributes': {'ctermfg':'16','guifg':'#000000'}, 'normal':0},
\ '31': {'description':'Set foreground color to Red', 'attributes': {'ctermfg':'1','guifg':'#ff0000'}, 'normal':0},
\ '32': {'description':'Set foreground color to Green', 'attributes': {'ctermfg':'2','guifg':'#00ff00'}, 'normal':0},
\ '33': {'description':'Set foreground color to Yellow', 'attributes': {'ctermfg':'3','guifg':'#ffff00'}, 'normal':0},
\ '34': {'description':'Set foreground color to Blue', 'attributes': {'ctermfg':'4','guifg':'#0000ff'}, 'normal':0},
\ '35': {'description':'Set foreground color to Magenta', 'attributes': {'ctermfg':'5','guifg':'#990099'}, 'normal':0},
\ '36': {'description':'Set foreground color to Cyan', 'attributes': {'ctermfg':'6','guifg':'#009999'}, 'normal':0},
\ '37': {'description':'Set foreground color to White', 'attributes': {'ctermfg':'7','guifg':'#ffffff'}, 'normal':0},
\ '39': {'description':'Set foreground color to default (original)', 'attributes': {'ctermfg':'NONE','guifg':'NONE'}, 'normal':1},
\ '40': {'description':'Set background color to Black', 'attributes': {'ctermbg':'16','guibg':'#000000'}, 'normal':0},
\ '41': {'description':'Set background color to Red', 'attributes': {'ctermbg':'1','guibg':'#ff0000'}, 'normal':0},
\ '42': {'description':'Set background color to Green', 'attributes': {'ctermbg':'2','guibg':'#00ff00'}, 'normal':0},
\ '43': {'description':'Set background color to Yellow', 'attributes': {'ctermbg':'3','guibg':'#ffff00'}, 'normal':0},
\ '44': {'description':'Set background color to Blue', 'attributes': {'ctermbg':'4','guibg':'#0000ff'}, 'normal':0},
\ '45': {'description':'Set background color to Magenta', 'attributes': {'ctermbg':'5','guibg':'#990099'}, 'normal':0},
\ '46': {'description':'Set background color to Cyan', 'attributes': {'ctermbg':'6','guibg':'#009999'}, 'normal':0},
\ '47': {'description':'Set background color to White', 'attributes': {'ctermbg':'7','guibg':'#ffffff'}, 'normal':0},
\ '49': {'description':'Set background color to default (original).', 'attributes': {'ctermbg':'NONE','guibg':'NONE'}, 'normal':1},
\ '90': {'description':'Set foreground color to Black', 'attributes': {'ctermfg':'16','guifg':'#000000'}, 'normal':0},
\ '91': {'description':'Set foreground color to Red', 'attributes': {'ctermfg':'1','guifg':'#ff0000'}, 'normal':0},
\ '92': {'description':'Set foreground color to Green', 'attributes': {'ctermfg':'2','guifg':'#00ff00'}, 'normal':0},
\ '93': {'description':'Set foreground color to Yellow', 'attributes': {'ctermfg':'3','guifg':'#ffff00'}, 'normal':0},
\ '94': {'description':'Set foreground color to Blue', 'attributes': {'ctermfg':'4','guifg':'#0000ff'}, 'normal':0},
\ '95': {'description':'Set foreground color to Magenta', 'attributes': {'ctermfg':'5','guifg':'#990099'}, 'normal':0},
\ '96': {'description':'Set foreground color to Cyan', 'attributes': {'ctermfg':'6','guifg':'#009999'}, 'normal':0},
\ '97': {'description':'Set foreground color to White', 'attributes': {'ctermfg':'7','guifg':'#ffffff'}, 'normal':0},
\ '100': {'description':'Set background color to Black', 'attributes': {'ctermbg':'16','guibg':'#000000'}, 'normal':0},
\ '101': {'description':'Set background color to Red', 'attributes': {'ctermbg':'1','guibg':'#ff0000'}, 'normal':0},
\ '102': {'description':'Set background color to Green', 'attributes': {'ctermbg':'2','guibg':'#00ff00'}, 'normal':0},
\ '103': {'description':'Set background color to Yellow', 'attributes': {'ctermbg':'3','guibg':'#ffff00'}, 'normal':0},
\ '104': {'description':'Set background color to Blue', 'attributes': {'ctermbg':'4','guibg':'#0000ff'}, 'normal':0},
\ '105': {'description':'Set background color to Magenta', 'attributes': {'ctermbg':'5','guibg':'#990099'}, 'normal':0},
\ '106': {'description':'Set background color to Cyan', 'attributes': {'ctermbg':'6','guibg':'#009999'}, 'normal':0},
\ '107': {'description':'Set background color to White', 'attributes': {'ctermbg':'7','guibg':'#ffffff'}, 'normal':0}
\ } 
" }}}

" nr2char() is oddly more reliable than \r etc
let s:action_match = '\(\e[\??\?\(\d\+;\)*\d*\(\w\|@\)\|'.nr2char(10).'\|'.nr2char(13).'\|'.nr2char(8).'\|'.nr2char(7).'\)'

" Open a command in Conque.
" This is the root function that is called from Vim to start up Conque.
function! conque_experimental#open(...) "{{{
    let command = get(a:000, 0, '')
    let hooks   = get(a:000, 1, [])

    call s:log.debug('<open command>')
    call s:log.debug('command: ' . command)

    " bare minimum validation
    if empty(command)
        echohl WarningMsg | echomsg "No command found" | echohl None
        call s:log.warn('command not found: ' . command)
        return 0
    else
        let l:cargs = split(command, '\s')
        if !executable(l:cargs[0])
            echohl WarningMsg | echomsg "Not an executable" | echohl None
            call s:log.warn('command not found: ' . l:cargs[0])
            return 0
        endif
    endif

    " configure shell buffer display and key mappings
    call conque_experimental#set_buffer_settings(command, hooks)

    " set global environment variables
    let $COLUMNS = winwidth(0)
    let $LINES = winheight(0)
    let b:COLUMNS = $COLUMNS
    let b:LINES = $LINES
    " the CSI r escape can change the effective working rectangle of screen output
    let b:WORKING_COLUMNS = $COLUMNS
    let b:WORKING_LINES = $LINES

    " cursor position
    let b:_l = 1
    let b:_c = 0

    " top of the screen
    let b:_top = 1

    " color highlights
    let b:_hi = {}

    " used for timer
    let b:K_IGNORE = "\x80\xFD\x35"

    " open command
    try
        let b:subprocess = subprocess#new()
        call b:subprocess.open(command, {'TERM': 'vt100', 'CONQUE': 1, 'EDITOR': 'unsupported'})
        call s:log.info('opening command: ' . command . ' with ptyopen')
    catch 
        echohl WarningMsg | echomsg "Unable to open command: " . command | echohl None
        return 0
    endtry

    " save this buffer info
    let g:Conque_BufNr = bufnr("%")
    let g:Conque_BufName = bufname("%")
    let g:Conque_Idx += 1

    " read welcome message from command, give it a full second to start up
    call conque_experimental#read(500)

    call s:log.debug('</open command>')

    startinsert!
    return 1
endfunction "}}}

" buffer settings, layout, key mappings, and auto commands
function! conque_experimental#set_buffer_settings(command, pre_hooks) "{{{
    " optional hooks to execute, e.g. 'split'
    for h in a:pre_hooks
        silent execute h
    endfor

    " buffer settings {{{
    silent execute "edit " . substitute(a:command, ' ', '\\ ', 'g') . "\\ -\\ " . g:Conque_Idx
    setlocal buftype=nofile  " this buffer is not a file, you can't save it
    setlocal nonumber        " hide line numbers
    setlocal foldcolumn=0    " reasonable left margin
    setlocal nowrap          " default to no wrap (esp with MySQL)
    setlocal noswapfile      " don't bother creating a .swp file
    setlocal updatetime=25   " trigger cursorhold event after 1s
    set scrolloff=0          " don't use buffer lines. it makes the 'clear' command not work as expected
    setfiletype conque       " useful
    silent execute "setlocal syntax=".g:Conque_Syntax
    setlocal foldmethod=manual
    " }}}

    " map first 256 ASCII chars {{{
    for i in range(33, 255)
        call s:log.debug(nr2char(i))
        " <Bar>
        if i == 124
            continue
        endif
        silent execute 'inoremap <silent> <buffer> ' . nr2char(i) . ' <Esc>:call conque_experimental#press_key(nr2char(' . i . '))<CR>a'
    endfor
    " }}}

    " Special cases
    inoremap <silent> <buffer> <BS> <Esc>:call conque_experimental#press_key(nr2char(8))<CR>a
    inoremap <silent> <buffer> <Tab> <Esc>:call conque_experimental#press_key(nr2char(9))<CR>a
    inoremap <silent> <buffer> <LF> <Esc>:call conque_experimental#press_key(nr2char(10))<CR>a
    inoremap <silent> <buffer> <CR> <Esc>:call conque_experimental#press_key(nr2char(13))<CR>a
    inoremap <silent> <buffer> <Space> <Esc>:call conque_experimental#press_key(nr2char(32))<CR>a
    inoremap <silent> <buffer> <Bar> <Esc>:call conque_experimental#press_key(nr2char(124))<CR>a
    inoremap <silent> <buffer> <Up> <Esc>:call conque_experimental#press_key("<C-v><Esc>[A")<CR>a
    inoremap <silent> <buffer> <Down> <Esc>:call conque_experimental#press_key("<C-v><Esc>[B")<CR>a
    inoremap <silent> <buffer> <Right> <Esc>:call conque_experimental#press_key("<C-v><Esc>[C")<CR>a
    inoremap <silent> <buffer> <Left> <Esc>:call conque_experimental#press_key("<C-v><Esc>[D")<CR>a

    " Control / Meta chars {{{
    for c in split(s:chars_control, '\zs')
        silent execute 'inoremap <silent> <buffer> <C-' . c . '> <Esc>:call conque_experimental#press_key("<C-v><C-' . c . '>")<CR>a'
    endfor

    " meta characters 
    for c in split(s:chars_meta, '\zs')
        silent execute 'inoremap <silent> <buffer> <M-' . c . '> <Esc>:call conque_experimental#press_key("<C-v><Esc>' . c . '")<CR>a'
    endfor
    " }}}

    " other weird stuff {{{

    " use F8 key to get more input
    inoremap <silent> <buffer> <F8> <Esc>:call conque_experimental#read(1)<CR>a

    " used for auto read
    inoremap <silent> <buffer> <expr> <F7> " \<BS>"

    " remap paste keys
    nnoremap <silent> <buffer> p :call conque_experimental#paste()<CR>
    nnoremap <silent> <buffer> P :call conque_experimental#paste()<CR>

    " send selected text into conque
	  vnoremap <silent> <F9> :<C-u>call conque_experimental#send_selected(visualmode())<CR>

    " send escape
    inoremap <silent> <buffer> <Esc><Esc> <Esc>:call conque_experimental#press_key("<C-v><Esc>")<CR>a
    nnoremap <silent> <buffer> <Esc> :<C-u>call conque_experimental#message('To send an <E'.'sc> to the terminal, press <E'.'sc><E'.'sc> quickly in insert mode. Some programs, such as Vim, will also accept <Ctrl-c> as a substitute for <E'.'sc>', 1)<CR>
    nnoremap <silent> <buffer> <C-c> :call conque_experimental#press_key("<C-v><C-c>")<CR>a

    " }}}

    " handle unexpected closing of shell
    " passes HUP to main and all child processes
    autocmd BufUnload <buffer> call conque_experimental#hang_up()
    autocmd CursorHoldI <buffer> call conque_experimental#auto_read()
    autocmd BufEnter <buffer> call conque_experimental#update_window_size()
endfunction "}}}

" controller to execute current line
function! conque_experimental#press_key(char) "{{{
    call s:log.debug('<keyboard triggered run>')
    call s:log.debug('pressed key ' . a:char)

    call s:log.profile_start('run')

    " check if subprocess still exists
    if !exists('b:subprocess')
        return
    endif

    call b:subprocess.write(a:char)

    call conque_experimental#read(1)

    call s:log.profile_end('run')
    call s:log.debug('</keyboard triggered run>')
endfunction "}}}

" read from pty and write to buffer
function! conque_experimental#read(timeout) "{{{
    call s:log.debug('<read>')
    call s:log.profile_start('read')
    call s:log.profile_start('subread')

    try
        let l:output = b:subprocess.read(a:timeout)
    catch
        call s:log.warn('read exception')
        echohl WarningMsg | echomsg 'no process' | echohl None
        call conque_experimental#exit()
        return
    endtry

    call s:log.profile_end('subread')
    call s:log.profile_start('printread')

    call s:log.debug('raw output: ' . string(l:output))

    " short circuit no output
    if len(l:output) == 1 && l:output[0] == ''
        return
    endif

    " process each line individually
    for i in range(len(l:output))
        if i == len(l:output) - 1
            let l:line = l:output[i]
        else
            let l:line = l:output[i] . "\n"
        endif
        call conque_experimental#process_input(l:line)
        if i > 1 && i % 100 == 0
            call s:log.profile_start('partial redraw')
            redraw
            call s:log.profile_end('partial redraw')
        endif
    endfor

    " redraw screen
    call s:log.profile_start('finalredraw')
    redraw
    call s:log.profile_end('finalredraw')

    call s:log.profile_end('printread')
    call s:log.profile_end('read')
    call s:log.debug('</read>')
endfunction "}}}

function! conque_experimental#auto_read() " {{{
    "call s:log.profile_start('autoread')

    call conque_experimental#read(1)
    call cursor(b:_l, b:_c + 1)
    call feedkeys("\<F7>", "t")

    "call s:log.profile_end('autoread')
endfunction " }}}

function! conque_experimental#message(msg, warn) " {{{
    if g:Conque_Help_Messages == 0
        return
    endif

    if a:warn == 1
        echohl WarningMsg | echomsg a:msg | echohl None
    else
        echo a:msg
    endif
endfunction " }}}

" kill process pid with SIGHUP
" this gets called if the buffer is unloaded before the program has been exited
" it should pass the signall to all children before killing the parent process
function! conque_experimental#hang_up() "{{{
    call s:log.debug('<hang up>')

    if !exists('b:subprocess')
        return
    endif

    if b:subprocess.get_status() == 1
        " Kill processes.
        try
            " 1 == HUP
            call b:subprocess.hang_up()
            call append(line('$'), '*Killed*')
        catch /No such process/
        endtry
    endif

    call s:log.debug('</hang up>')
    "call conque_experimental#on_exit()
endfunction "}}}

function! conque_experimental#process_input(input) " {{{
    call s:log.profile_start('process_input')

    " attempt a short circuit
    if a:input =~ '^[a-zA-Z0-9_. ''"-]\+$'
        call s:log.debug('SHORT')
        let l:working = getline(b:_l)
        if b:_c == 0
            let l:working = a:input . l:working[ b:_c + strlen(a:input) : ]
        else
            let l:working = l:working[ : b:_c - 1 ] . a:input . l:working[ b:_c + strlen(a:input) : ]
        endif
        let b:_c += strlen(a:input)
        call setline(b:_l, l:working)
        call cursor(b:_l, b:_c)
        return
    endif

    " prefill whitespace {{{
    if b:_l > line('$')
        for l:i in range(line('$') + 1, b:_l)
            call setline(l:i, '')
        endfor
    endif

    " XXX - check b:_c len
    if b:_l > 0 && strlen(getline(b:_l)) < b:_c
        call s:log.debug('line ' . b:_l . ' is not ' . b:_c . ' chars')
        call s:log.debug('max line is ' . line('$'))
        call s:log.debug('current is ' . getline(b:_l))
        call setline(b:_l, getline(b:_l) . printf("%" . (b:_c - strlen(getline(b:_l))) . "s", ' '))
    endif
    " }}}

    " init vars
    let l:line_pos = b:_c
    let l:input = a:input
    let l:output = getline(b:_l)
    let l:color_changes = []

    call s:log.debug('starting process line at line ' . b:_l . ' and col ' . b:_c . ' add newline ? ')

    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " REMOVE REDUNDANT/IGNORED ESCAPE SEQUENCES. {{{
    " This often removes the requirement to parse the line char by char, which is a huge performance hit.

    if l:input =~ '\e' 
        call s:log.profile_start('regex madness')
        " remove trailing <CR>s. conque assumes cursor will be at col 0 for new lines
        "let l:input = substitute(l:input, '\r\+$', '', '')
        " remove shift in
        let l:input = substitute(l:input, nr2char(15), '', 'g')
        " remove character set escapes. they would be ignored
        let l:input = substitute(l:input, '\e(.', '', 'g')
        let l:input = substitute(l:input, '\e).', '', 'g')
        " remove keypad mode commands. they would be ignored
        let l:input = substitute(l:input, '\e>', '', 'g')
        let l:input = substitute(l:input, '\e=', '', 'g')
        " remove initial color escape if it is setting color to normal. conque always starts lines in normal syntax
        let l:input = substitute(l:input, '^\(\e[0\?m\)*', '', '')
        " remove title changes
        let l:input = substitute(l:input, '\e]\d;.\{-\}'.nr2char(7), '', 'g')
        " remove trailing color escapes. syntax changes are limited to one line
        let l:input = substitute(l:input, '\(\e[\(\d*;\)*\d*m\)*$', '', '')
        " remove all normal color escapes leading up to the first non-normal color escape
        while l:input =~ '^[^\e]\+\e[\(39;49\|0\)\?m'
            call s:log.debug('found initial normal')
            let l:input = substitute(l:input, '\e[\(39;49\|0\)\?m', '', '')
        endwhile
        call s:log.profile_end('regex madness')
    endif " }}}

    call s:log.debug('PROCESSING LINE ' . l:input)
    call s:log.debug('AT COL ' . l:line_pos)

    call s:log.profile_start('big_wrap')
    " ****************************************************************************************** "
    " Loop over action matches {{{
    let l:match_num = match(l:input, s:action_match)
    call s:log.debug('FIRST MATCH ' . l:match_num)
    while l:match_num != -1
        " pack characters up to the match onto output
        if l:match_num > 0 && l:line_pos == 0
            let l:output =                                  l:input[ 0 : l:match_num - 1 ] . l:output[ l:line_pos + l:match_num : ]
        elseif l:match_num > 0
            let l:output = l:output[ 0 : l:line_pos - 1 ] . l:input[ 0 : l:match_num - 1 ] . l:output[ l:line_pos + l:match_num : ]
        endif

        call s:log.profile_start('wrapping_1')
        " handle line wrapping {{{
        call s:log.debug('testing string ' . l:input[ b:WORKING_COLUMNS : ])
        if l:line_pos + l:match_num > b:WORKING_COLUMNS && (l:input =~ '\e' || l:input =~ nr2char(13) . '.*\w')
            call s:log.debug('wrapping needed ' . l:output . ' len ' . len(l:output) . ' is greater than ' . b:WORKING_COLUMNS)
            let b:auto_wrapped = 1

            " break output at screen width
            "let l:input = nr2char(13) . l:output[ b:WORKING_COLUMNS : ] . l:input[ l:match_num : ]
            let l:input = l:input[ b:WORKING_COLUMNS : ]
            let l:output = l:output[ : b:WORKING_COLUMNS - 1 ]
            
            call s:log.debug('new input: ' . l:input)
            call s:log.debug('new output: ' . l:output)

            " finish off this line
            call setline(b:_l, l:output)
            call conque_experimental#process_colors(l:color_changes)
            call cursor(b:_l, b:_c)
            call winline()

            " initialize cursor in the correct position
            let b:_l += 1
            let b:_c = 0
            "call setline(b:_l, '')

            " ship off the rest of input to next line
            call s:log.profile_end('process_input')
            call conque_experimental#process_input(l:input)
            return
        endif " }}}
        call s:log.profile_end('wrapping_1')

        call s:log.debug('PREADDING OUTPUT resulting in ' . l:output)

        let l:match_str = matchstr(l:input, s:action_match, l:match_num)

        call s:log.debug('MATCH STR ' . l:match_str)
        let l:input = l:input[l:match_num + len(l:match_str) :]
        call s:log.debug('NEW INPUT LINE ' . l:input)
        let l:line_pos += l:match_num
        call s:log.debug('line pos now ' . l:line_pos)

        if l:match_str == nr2char(8) " backspace {{{
            call s:log.debug('backspace')
            let l:line_pos = l:line_pos - 1
            " }}}

        elseif l:match_str == nr2char(10) " new line {{{
            call s:log.debug('<NL>')
            let l:local_scroll = 0

            " if screen size has been adjusted, scroll partial screen region
            call s:log.debug('checking working work overflow at line ' . b:_l . ' with working lines ' . b:WORKING_LINES . ' and lines ' . b:LINES . ' and top ' . b:_top)
            if b:WORKING_LINES < b:LINES && b:_l + 1 > b:_top + b:WORKING_LINES - 1
                call s:log.debug('work overflow at line ' . b:_l . ' with working lines ' . b:WORKING_LINES)
                if b:_top > line('.') - winline() + 1
                    let l:local_scroll = 1
                    silent execute b:_top . "," . b:_top . "d"
                endif
                call append(b:_l - 1, '')
            endif

            " finish off this line
            call setline(b:_l, l:output)
            call conque_experimental#process_colors(l:color_changes)
            "call cursor(b:_l, b:_c)
            "call winline()

            " initialize cursor in the correct position
            let b:_c = 0
            if l:local_scroll == 0
                let b:_l += 1
            endif
            if b:_l > b:_top + b:WORKING_LINES - 1
                let b:_top += 1
            endif

            call cursor(b:_l, b:_c)
            call winline()

            call s:log.debug('set line to ' . b:_l . ' col to ' . b:_c)

            " ship off the rest of input to next line
            call s:log.profile_end('process_input')
            call conque_experimental#process_input(l:input)
            return
            " }}}

        elseif l:match_str == nr2char(13) " CR {{{
            call s:log.debug('<CR>')
            let l:line_pos = 0
            let b:_c = 0
            " }}}

        elseif l:match_str == nr2char(7) " Bell {{{
            call s:log.debug('bell')
            echohl WarningMsg | echomsg "BELL!" | echohl None
            " }}}

        else
            call s:log.profile_start('escape')
            " last character
            let l:key = l:match_str[-1 : -1]

            call s:log.debug('match key ' . l:key)

            if l:match_str =~ '^\e[' && exists('s:escape_sequences[l:key]')

                call s:log.debug('escape type ' . l:key)
                " action tied to this last character
                let l:action = s:escape_sequences[l:key]
                " numeric modifiers
                let l:vals = split(l:match_str[2 : -2], ';')
                let l:delta = len(l:vals) > 0 ? l:vals[0] : 1
                call s:log.debug('escape type ' . l:action . ' with nums ' . string(l:vals))

                " ********************************************************************************** "
                " Escape actions 
                if l:action == 'font' " {{{
                    if len(l:color_changes) > 0
                        let l:color_changes[len(l:color_changes) - 1].end = l:line_pos
                    endif
                    call add(l:color_changes, {'col': l:line_pos, 'end' : -1 , 'codes': l:vals})
                    " }}}

                elseif l:action == 'clear_line' " {{{
                    if l:line_pos == 0
                        let l:output = ''
                    else
                        let l:output = l:output[ : l:line_pos - 1]
                    endif
                    if len(l:color_changes) > 0
                        for l:i in range(len(l:color_changes))
                            if l:color_changes[l:i].col >= l:line_pos
                                let l:color_changes[l:i].codes = []
                            endif
                        endfor
                    endif
                    call conque_experimental#clear_colors(b:_l, l:line_pos)
                    " }}}

                elseif l:action == 'cursor_right' " {{{
                    let l:line_pos = l:line_pos + l:delta
                    " }}}

                elseif l:action == 'cursor_left' " {{{
                    let l:line_pos = l:line_pos - l:delta
                    " }}}

                elseif l:action == 'cursor_to_column' " {{{
                    let l:line_pos = l:delta - 1
                    while len(l:output) <= l:line_pos
                        let l:output = l:output . ' '
                    endwhile
                    " }}}

                elseif l:action == 'cursor_up' " {{{
                    " finish off this line
                    call setline(b:_l, l:output)
                    call conque_experimental#process_colors(l:color_changes)
                    call cursor(b:_l, b:_c)
                    call winline()

                    " initialize cursor in the correct position
                    let b:_l = b:_l - l:delta
                    let b:_c = l:line_pos

                    call s:log.debug('set line to ' . b:_l . ' col to ' . b:_c)

                    " ship off the rest of input to next line
                    call s:log.profile_end('process_input')
                    call conque_experimental#process_input(l:input)
                    return
                    " }}}

                elseif l:action == 'cursor_down' " {{{
                    " finish off this line
                    call setline(b:_l, l:output)
                    call conque_experimental#process_colors(l:color_changes)
                    call cursor(b:_l, b:_c)
                    call winline()

                    " initialize cursor in the correct position
                    let b:_l = b:_l + l:delta
                    let b:_c = l:line_pos

                    call s:log.debug('set line to ' . b:_l . ' col to ' . b:_c)

                    " ship off the rest of input to next line
                    call s:log.profile_end('process_input')
                    call conque_experimental#process_input(l:input)
                    return
                    " }}}

                elseif l:action == 'clear_screen' " {{{
                    " do not default to 1
                    let l:delta = len(l:vals) > 0 ? l:vals[0] : ''

                    " 2 == clear entire screen
                    if l:delta == 2
                        call setline(b:_l, l:output)
                        call conque_experimental#process_colors(l:color_changes)

                        let b:_c = 0
                        let b:_l = line('$') + 1
                        call setline(b:_l, '')
                        let b:_top = b:_l
                        normal Gzt

                        for i in range(b:_top + 1, b:_top + b:WORKING_LINES - 1)
                            call setline(i, '')
                        endfor

                        call s:log.debug('clearing screen, new top is ' . b:_top)

                        call s:log.profile_end('process_input')
                        call conque_experimental#process_input(l:input)
                        return

                    " ''|0 == clear down
                    elseif l:delta == '' || l:delta == 0
                        if b:_l < line('$')
                            silent execute (b:_l + 1) . "," . line('$') . "d"
                        endif

                        for i in range(b:_l + 1, b:_top + b:WORKING_LINES - 1)
                            call setline(i, '')
                        endfor
  
                        if line_pos == 0
                            let l:output = ''
                        else
                            let l:output = l:output[ : l:line_pos - 1]
                        endif

                    " 1 == clear up
                    elseif l:delta == ''
                        normal Gzt

                    endif
                    " }}}

                elseif l:action == 'delete_chars' " {{{
                    if l:line_pos == 0
                        let l:output =                               l:output[l:line_pos + l:delta : ]
                    else
                        let l:output = l:output[ : l:line_pos - 1] . l:output[l:line_pos + l:delta : ]
                    endif
                    " }}}

                elseif l:action == 'add_spaces' " {{{

                    call s:log.debug('adding ' . l:delta . ' spaces')
                    let l:spaces = []
                    for sp in range(l:delta)
                        call add(l:spaces, ' ')
                    endfor
                    call s:log.debug('spaces: ' . string(l:spaces))

                    if l:line_pos == 0
                        let l:output =                               join(l:spaces, '') . l:output[l:line_pos : ]
                    else
                        let l:output = l:output[ : l:line_pos - 1] . join(l:spaces, '') . l:output[l:line_pos : ]
                    endif
                    " }}}

                elseif l:action == 'cursor' " {{{
                    let l:new_line = len(l:vals) > 0 ? l:vals[0] : 1
                    let l:new_col = len(l:vals) > 1 ? l:vals[1] : 1

                    call setline(b:_l, l:output)
                    call conque_experimental#process_colors(l:color_changes)

                    let l:top = line('.') - winline() + 1

                    let b:_l = l:top + l:new_line - 1
                    let b:_c = l:new_col - 1

                    call s:log.debug('moving cursor to  line ' . b:_l . ' column ' . b:_c)

                    call s:log.profile_end('process_input')
                    call conque_experimental#process_input(l:input)
                    return
                    " }}}

                elseif l:action == 'set_coords' " {{{
                    call s:log.debug('really old top ' . b:_top)

                    let l:top = line('.') - winline() + 1

                    let l:new_start = l:vals[0]
                    let l:new_end = l:vals[1]

                    call s:log.debug('old top ' . b:_top)

                    let b:_top = l:top + l:new_start - 1

                    call s:log.debug('new top ' . b:_top)

                    if l:top + l:new_end  > line('$')
                        call s:log.debug('creating lines')
                        for l:ln in range(line('$') + 1, l:top + l:new_end - 1)
                            call setline(l:ln, '')
                        endfor
                    endif

                    let b:WORKING_LINES = l:new_end - l:new_start + 1
                    " }}}

                endif

            elseif l:match_str =~ '^\e' && exists('s:escape_sequences_plain[l:key]')
                let l:action = s:escape_sequences_plain[l:key]

                call s:log.debug('plain key match ' . l:action)

                if l:action == 'scroll_up' " {{{
                    call s:log.debug('scrolling up')

                    "if line('$') > b:WORKING_LINES && line('$') - b:WORKING_LINES + 1 > b:_top
                    "    let b:_top = line('$') - b:WORKING_LINES + 1
                    "endif
                    
                    let b:_top += 1
                    " }}}

                elseif l:action == 'scroll_down' " {{{
                    call s:log.debug('scrolling down')

                    "if line('$') > b:WORKING_LINES && line('$') - b:WORKING_LINES + 1 > b:_top
                    "    let b:_top = line('$') - b:WORKING_LINES + 1
                    "endif

                    " XXX - this escape kills highlighting, no way around it
                   
                    call s:log.debug('old top is ' . b:_top) 
                    "let b:_top += -1
                    "let b:_l += -1

                    " overscroll
                    "if b:_l < 1
                    "    call s:log.debug('overscroll ') 
                    "    let b:_top += 1
                    "    let b:_l += 1
                    "    call append(0, '')
                    "endif

                    " clear new line
                    call append(b:_top - 1, '')
                    let l:output = ''
                    "call cursor(b:_top, b:_c)
                    "call winline()

                    " remove old line
                    silent execute (b:_top + b:WORKING_LINES) . ',' . (b:_top + b:WORKING_LINES) . 'd'
                    " }}}

                endif
            endif

            call s:log.profile_end('escape')

        endif

        let l:match_num = match(l:input, s:action_match)
        call s:log.debug('NEXT MATCH NUM ' . l:match_num)
    endwhile
    " }}}
    call s:log.profile_end('big_wrap')

    " pack on remaining input
    if l:line_pos > 0
        let l:output = l:output[ 0 : l:line_pos - 1 ] . l:input . l:output[ l:line_pos + len(l:input) : ]
    else
        let l:output =                                  l:input . l:output[ l:line_pos + len(l:input) : ]
    endif
    call s:log.debug('FINAL OUTPUT ' . l:output)

    call s:log.profile_start('wrapping_2')
    " handle line wrapping {{{
    if len(l:output) > b:WORKING_COLUMNS && (l:input =~ '\e' || l:input =~ nr2char(13) . '.*\w')
        call s:log.debug('II wrapping needed ' . l:output . ' len ' . len(l:output) . ' is greater than ' . b:WORKING_COLUMNS)
        let b:auto_wrapped = 1

        " break output at screen width
        let l:input = l:output[ b:WORKING_COLUMNS : ]
        let l:output = l:output[ : b:WORKING_COLUMNS - 1 ]
        
        call s:log.debug('new input: ' . l:input)
        call s:log.debug('new output: ' . l:output)

        " finish off this line
        call setline(b:_l, l:output)
        call conque_experimental#process_colors(l:color_changes)
        call cursor(b:_l, b:_c)
        call winline()

        " initialize cursor in the correct position
        let b:_l += 1
        let b:_c = 0

        " ship off the rest of input to next line
        call s:log.profile_end('process_input')
        call conque_experimental#process_input(l:input)
        return
    endif
    " }}}
    call s:log.profile_end('wrapping_2')

    " strip trailing spaces
    call s:log.debug('line pos ' . l:line_pos)

    let l:line_pos += len(l:input)
    let b:_c = l:line_pos

    " set line
    call setline(b:_l, l:output)

    " prefill whitespace {{{
    while strlen(getline(b:_l)) < b:_c
        call s:log.debug('line ' . b:_l . ' is not ' . b:_c . ' chars')
        call s:log.debug('max line is ' . line('$'))
        call s:log.debug('current is ' . getline(b:_l))
        call setline(b:_l, getline(b:_l) . ' ')
    endwhile
    " }}}

    " color it
    call conque_experimental#process_colors(l:color_changes)

    " reposition cursor
    call cursor(b:_l, b:_c)
    call s:log.profile_end('process_input')
endfunction " }}}

function! conque_experimental#clear_colors(line, col) " {{{
    call s:log.debug('clearing colors at line ' . a:line . ' col ' . a:col)
    " strip previous color changes
    if exists('b:_hi[' . a:line . ']')
        for l:hi_col in keys(b:_hi[a:line])
            if l:hi_col >= a:col - 1
                for l:hi_name in b:_hi[a:line][l:hi_col]
                    call s:log.debug('clearing ' . l:hi_name)
                    silent execute "highlight clear " . l:hi_name
                endfor
            endif
        endfor
    endif
endfunction " }}}

function! conque_experimental#process_colors(color_changes) " {{{
    call s:log.profile_start('process_colors')
    if len(a:color_changes) == 0
        call s:log.profile_end('process_colors')
        return
    endif

    "call conque_experimental#clear_colors(b:_l, b:_c)

    " color it
    let l:hi_ct = 1
    let l:last_col = len(substitute(getline(b:_l), '\s\+$', '', ''))
    for cc in a:color_changes
        if cc.col > l:last_col + 2
            continue
        endif

        let l:highlight = ''
        for color_number in cc.codes
            if exists('s:font_codes['.color_number.']')
                for attr in keys(s:font_codes[color_number].attributes)
                    let l:highlight = l:highlight . ' ' . attr . '=' . s:font_codes[color_number].attributes[attr]
                endfor
            endif
        endfor

        " fix last color seq
        if cc.end == -1
            let cc.end = l:last_col
        endif

        let syntax_name = ' EscapeSequenceAt_' . bufnr('%') . '_' . b:_l . '_' . cc.col . '_' . l:hi_ct
        let syntax_region = 'syntax match ' . syntax_name . ' /\%' . b:_l . 'l\%>' . cc.col . 'c.*\%<' . (cc.end + 2) . 'c/ contains=ALL oneline'
        "let syntax_link = 'highlight link ' . syntax_name . ' Normal'
        let syntax_highlight = 'highlight ' . syntax_name . l:highlight

        silent execute syntax_region
        "execute syntax_link
        silent execute syntax_highlight

        "call s:log.debug(syntax_name)
        call s:log.debug(syntax_region)
        "call s:log.debug(syntax_link)
        call s:log.debug(syntax_highlight)

        " add highlight to history
        if !exists('b:_hi[' . b:_l . ']')
            let b:_hi[b:_l] = {}
        endif
        if !exists('b:_hi[' . b:_l . '][' . cc.col . ']')
            let b:_hi[b:_l][cc.col] = []
        endif
        call add(b:_hi[b:_l][cc.col], syntax_name)

        let l:hi_ct += 1
    endfor
    call s:log.profile_end('process_colors')
endfunction " }}}

" send @@ buffer contents to terminal
function! conque_experimental#paste() " {{{
    call conque_experimental#press_key(@@)
endfunction " }}}

" send selected text from another buffer
function! conque_experimental#send_selected(type) "{{{
    let reg_save = @@

    " yank current selection
    silent execute "normal! `<" . a:type . "`>y"

    let @@ = substitute(@@, '^[\r\n]*', '', '')
    let @@ = substitute(@@, '[\r\n]*$', '', '')

    silent execute ":sb " . g:Conque_BufName

    call conque_experimental#press_key(@@)

    let @@ = reg_save
endfunction "}}}

" check if the buffer has been resized, and update pty with new size if so
function! conque_experimental#update_window_size() " {{{
    if b:COLUMNS == winwidth(0) && b:LINES == winheight(0)
        return
    endif

    " update kernel and subprocess
    let b:COLUMNS = winwidth(0)
    let b:LINES = winheight(0)
    let b:WORKING_COLUMNS = b:COLUMNS
    let b:WORKING_LINES = b:LINES
    call b:subprocess.update_window_size(b:LINES, b:COLUMNS)

    " update screen
    call conque_experimental#read(200)
    normal G
    call cursor(b:_l, b:_c)
endfunction " }}}

" Logging {{{
if exists('g:Conque_Logging') && g:Conque_Logging == 1
    let s:log = log#getLogger(expand('<sfile>:t'))
    let s:profiles = {}
    function! s:log.profile_start(name)
        let s:profiles[a:name] = reltime()
    endfunction
    function! s:log.profile_end(name)
        let time = reltimestr(reltime(s:profiles[a:name]))
        call s:log.debug('PROFILE "' . a:name . '": ' . time)
    endfunction
else
    let s:log = {}
    function! s:log.debug(msg)
    endfunction
    function! s:log.info(msg)
    endfunction
    function! s:log.warn(msg)
    endfunction
    function! s:log.error(msg)
    endfunction
    function! s:log.fatal(msg)
    endfunction
    function! s:log.profile_start(name)
    endfunction
    function! s:log.profile_end(name)
    endfunction
endif
" }}}

" Configuration globals {{{
""""""""""""""""""""""""""""""""""""""""""
" Default read timeout for running a command, in seconds.
" Decreasing this value will make Conque seem more responsive, but you will get more '...' read timeouts
if !exists('g:Conque_Read_Timeout')
    let g:Conque_Read_Timeout = 1
endif
" Show help messages
if !exists('g:Conque_Help_Messages')
    let g:Conque_Help_Messages = 1
endif
" Syntax for your buffer
if !exists('g:Conque_Syntax')
    let g:Conque_Syntax = 'conque'
endif
" TERM environment setting
if !exists('g:Conque_TERM')
    let g:Conque_TERM =  'vt100'
endif
""""""""""""""""""""""""""""""""""""""""""
" }}}

command! -nargs=+ -complete=shellcmd ConqueExperimental call conque_experimental#open(<q-args>)

let g:Loaded_ConqueExperimental = 1
let g:Conque_Idx = 1

" vim: foldmethod=marker

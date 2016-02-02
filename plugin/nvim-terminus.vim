" not all buffers have names to use bufnr
" {bufnr, job_id}
let g:terminus_terms = {}  " TODO make script local
let g:terminus_max_command_length = 10000
let g:terminus_prompt = '>'

" Start a job and add id to list
function! s:start_terminal(...)
  if a:0 > 0
    let l:cmd = a:1
  else
    let l:cmd = &shell
  endif

  enew
  let job_id = termopen(l:cmd)
  let g:terminus_terms[bufnr('%')] = l:job_id

  execute 'autocmd BufDelete <buffer>
        \ call remove(g:terminus_terms, ' . bufnr('%') . ')
        \ | autocmd! BufDelete <buffer>'
  
endfunction

" open a new scratch buffer
function! s:open_scratch_buffer(bufnr, command)
  " open new empty buffer
  new

  " make buffer a scratch buffer
  setlocal buftype=nofile
  setlocal bufhidden=unload
  setlocal noswapfile

  " send command back to terminal when we leave this buffer. Note that we
  " can't use arguments in autocmd as they won't exist when autocmd is run so
  " we must use execute to resolve those arguments beforehand
  execute 'autocmd BufLeave <buffer> 
        \ call jobsend(' . g:terminus_terms[a:bufnr] . ', join(getline(1, ''$''), "\n")) 
        \ | autocmd! BufLeave <buffer>'

  call s:put_command(a:command)

endfunction

" clear the command line of the given bufnr
function! s:clear_commandline(bufnr)
  let i = 0
  while i < g:terminus_max_command_length
    " use backspace to clear the commandline rather than 
    " send 10 backspace's at once to reduce lag
    call jobsend(g:terminus_terms[a:bufnr], '')
    let i += 10
  endwhile
endfunction

" extract the command that follows the given promt from the current buffer
function! s:extract_command(prompt)
  " starting at the last line search backwards through the file for a line containing the prompt
  let l:line_number = line('$')
  while l:line_number > 0
    " if a user has not entered a command then there will not be a space after the last prompt
    let l:space_or_eol = '\( \|$\)'
    if match(getline(l:line_number), a:prompt . l:space_or_eol) !=# -1
      " combine all the lines from the line containing the prompt to the last line into a single string
      let l:commandline = join(getline(l:line_number, '$'), "\n")      
      return s:format_command(s:strip_prompt(l:commandline, a:prompt))
    endif
    let l:line_number = l:line_number - 1
  endwhile

  " if we reach this point then the prompt was not found
  echoerr "Could not find prompt '" . l:prompt . "' in buffer"
endfunction

" strip the given prompt from the commandline, leaving only the command
function! s:strip_prompt(commandline, prompt)
  let l:prompt_idx = stridx(a:commandline, a:prompt) + len(a:prompt) + 1
  return strpart(a:commandline, l:prompt_idx)
endfunction

" remove extra whitespace and newlines caused by our method of extracting text
" from the terminal buffer
function! s:format_command(command)
  " remove all whitespace following a newline
  let l:command = substitute(a:command, '\(\n\)\s*', '\n', "g")
  " remove newlines that do not come after a backslash
  let l:command = substitute(l:command, '\([^\\]\)\n*', '\1', "g")
  return l:command
endfunction

" put the given command into the current buffer
function! s:put_command(command)
  put =a:command
  " remove the (empty) first line
  0,1delete
endfunction

" edit the current command on the commandline of a terminal 
function! s:edit_command()
  let term_buf_nr = bufnr('%')
  let command = s:extract_command(g:terminus_prompt)
  call s:clear_commandline(l:term_buf_nr)
  call s:open_scratch_buffer(l:term_buf_nr, l:command)
endfunction

" Mappings
tnoremap <silent> <Plug>TerminusEdit <c-\><c-n>:call <SID>edit_command()<cr>

tmap <c-x> <Plug>TerminusEdit

" Commands
command! -nargs=? TerminusOpen call s:start_terminal(<f-args>)


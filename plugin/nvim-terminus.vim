" TODO reasoning for using bufname vs bufnr
" {bufname, job_id}
let g:terminus_terms = {}

" Start a job and add id to list
function! s:start_terminal(cmd)
  enew
  let job_id = termopen(a:cmd)
  let g:terminus_terms[bufname('%')] = l:job_id
endfunction

" open a scratch buffer and return the bufname
function! s:open_scratch_buffer(term_buf_name)
  " open new empty buffer
  new

  " make buffer a scratch buffer
  setlocal buftype=nofile
  setlocal bufhidden=unload
  setlocal noswapfile

  " send command back to terminal when we leave this buffer. Note that we
  " can't use arguments in autocmd as they won't exist when autocmd is run so
  " we must use execute to resolve it
  execute 'autocmd BufLeave <buffer> 
        \ call jobsend(' . g:terminus_terms[a:term_buf_name] . ', join(getline(1, ''$''), "\n")) 
        \ | autocmd! BufLeave <buffer>'

endfunction

function! s:clear_terminal(bufname)
  call jobsend(g:terminus_terms[a:bufname], '')
endfunction

function! s:clear_commandline(bufname)
  let i = 0
  while i < 10
    " use backspace to clear the commandline rather than 
    call jobsend(g:terminus_terms[a:bufname], '')
    let i += 1
  endwhile
endfunction

function! s:populate_commandline(bufname, command)
  call jobsend(g:terminus_terms[a:bufname], a:command)
endfunction

function! s:extract_command(bufname, prompt)
  " starting at the last line search backwards through the file for a line containing the prompt
  let l:line_number = line('$')
  while l:line_number > 0
    " if a user has not entered a command then there will not be a space after the last prompt
    let l:space_or_eol = '\( \|$\)'
    if match(getline(l:line_number), a:prompt . l:space_or_eol) !=# -1
      " combine all the lines from the line containing the prompt to the last line into a single string
      let l:commandline = join(getline(l:line_number, '$'), "\n")      
      " save command to a script local variable
      return s:strip_prompt(l:commandline, a:prompt)
    endif
    let l:line_number = l:line_number - 1
  endwhile

  " if we reach this point then the prompt was not found
  echoerr "Could not find prompt '" . l:prompt . "' in buffer"
endfunction

function! s:strip_prompt(commandline, prompt)
  let l:prompt_idx = stridx(a:commandline, a:prompt) + len(a:prompt) + 1
  return strpart(a:commandline, l:prompt_idx)
endfunction

function! s:put_command(command)
  " TODO investigate using append()
  put! =a:command
  " TODO format command before putting it in the buffer?
  call s:format_command()
endfunction

function! s:format_command()
  " strip leading whitespace
  %left

  " a single line in terminal buffer that wraps is yanked as two lines
  " so we must join to recombine it. However we do not want to join lines
  " that end with a '\'.

  " replace backslash followed by newline with \$ so we can see where to add newlines after join
  silent! %substitute/\\$/\\\$
  %join!
  silent! %substitute/\\\$/\\\r/g
endfunction

function! s:edit_command()
  let term_buf_name = bufname('%')
  let command = s:extract_command(l:term_buf_name, '>')
  call s:clear_commandline(l:term_buf_name)
  call s:open_scratch_buffer(l:term_buf_name)
  call s:put_command(l:command)
endfunction

tnoremap <silent> <Plug>Terminus <c-\><c-n>:call <SID>edit_command()<cr>

tmap <c-x> <Plug>Terminus
nmap <c-t> :call <SID>start_terminal('/usr/local/bin/fish')<cr>

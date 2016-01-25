" {bufname, job_id}
let g:terminus_terms = {}

" Start a job and add id to list
function! s:start_terminal(cmd)
  enew
  let job_id = termopen(a:cmd)
  let g:terminus_terms[bufname('%')] = l:job_id
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

function! s:edit_command()
  let bufname = bufname('%')
  let command = s:extract_command(l:bufname, '>')
  call jobsend(g:terminus_terms[l:bufname], '')
  "s:clear_commandline(l:bufname)
endfunction

tnoremap <silent> <Plug>EditCommand <c-\><c-n>:call <SID>edit_command()<cr>

tmap <c-x> <Plug>EditCommand
nmap <c-t> :call <SID>start_terminal('/usr/local/bin/fish')<cr>

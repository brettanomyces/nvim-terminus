
if !exists('g:terminus_terms')
  let g:terminus_terms = {}
endif

let g:terminus_max_command_length = 10000

" if a user has not entered a command then there will not be a space after the last prompt
let s:space_or_eol = '\( \|$\|\n\)'
let s:terminus_default_prompt = '>'
let s:terminus_prompts = {
      \ 'bash' : '$',
      \ 'zsh' : '%',
      \ 'fish' : '>',
      \ 'lua' : '>',
      \ 'python' : '>>>'}

" start the prototype
let Terminus = {}

" instance methods, shared by all copies of the prototype
function! Terminus.ClearCommand()
  let i = 0
  while i < g:terminus_max_command_length
    " use backspace to clear the commandline rather than 
    " send 10 backspace's at once to reduce lag
    call jobsend(self.job_id, '')
    let i += 10
  endwhile
endfunction

function! Terminus.Edit()
  let l:command = self.GetCommand()
  call self.OpenScratch(l:command)
  call self.ClearCommand()
endfunction

function! Terminus.SetCommand(command)
  call jobsend(self.job_id, a:command)
endfunction

function! Terminus.Prompt()
  return get(s:terminus_prompts, self.interpreter, s:terminus_default_prompt)
endfunction

function! Terminus.GetCommand()
  let l:commandline = s:get_commandline(self.Prompt())
  return s:format_command(s:strip_prompt(l:commandline, self.Prompt()))
endfunction

function! Terminus.OpenScratch(command)
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
        \ call g:terminus_terms[' . self.bufnr . '].SetCommand(join(getline(1, ''$''), "\n"))
        \ | autocmd! BufLeave <buffer>'

  call s:put_command(a:command)

endfunction

function! Terminus.Erase()
  if has_key(g:terminus_terms, self.bufnr)
    call remove(g:terminus_terms, self.bufnr)
  endif
endfunction

function! s:handle_stdout(job_id, data, event)
  for key in keys(g:terminus_terms)
    if g:terminus_terms[key].job_id ==# a:job_id
      call g:terminus_terms[key].HandleStdout(a:data, a:event)
    endif
  endfor
endfunction

" WARNING: this is handled asynchronously! 
" Currently only extracts and stores the prompt
function! Terminus.HandleStdout(data, event)
  if bufnr('%') ==# self.bufnr
    if strlen(self.stdout_buf) > 1000
      let self.stdout_buf = ''
    endif
    let self.stdout_buf = self.stdout_buf . join(a:data, "\n")
    " get prompt string
    let prompt_string = matchstr(self.stdout_buf, '\e\]0;\zs.\{-}\ze')
    if !empty(l:prompt_string)
      " remove color control characters and escape string so it can be used as a filename
      let self.fname = fnameescape(self.job_id . ' ' . substitute(l:prompt_string, '\e\[[0-9;]\+[mK]', '', 'g'))

      " TODO won't always be the case!
      " let self.cmd split(l:prompt_string)[0]
      " let self.dir split(l:prompt_string)[1]

      call self.Rename()
      " TODO we may be throwing away a prompt if two appear in the same batch of a:data
      let self.stdout_buf = ''
    endif
  endif
endfunction

function! Terminus.Rename()
  execute 'file ' . self.fname
  redraw!
endfunction


" the constructor
function! Terminus.New(...)
  if a:0 > 0
    let l:cmd = a:1
  else
    let l:cmd = &shell
  endif

  let obj = copy(self)
  " open new empty buffer which the terminal will use
  enew
  let obj.stdout_buf = ''
  let obj.shell = l:cmd
  let obj.job_id = termopen(l:cmd, {'on_stdout':function('s:handle_stdout')})
  let obj.bufnr = bufnr('%')
  let obj.dir = ''
  let obj.fname = ''

  let g:terminus_terms[obj.bufnr] = obj

  execute 'autocmd BufDelete <buffer> 
        \ call g:terminus_terms[' . obj.bufnr . '].Erase() 
        \ | autocmd! BufDelete <buffer>'

  return obj
endfunction

function! s:get_commandline(prompt)
  let l:line_number = line('$')
  while l:line_number > 0 
    if match(getline(l:line_number), a:prompt . s:space_or_eol) !=# -1
      " combine all the lines from the line containing the prompt to the last line into a single string
      let l:commandline = join(getline(l:line_number, '$'), "\n")      
      return s:format_command(l:commandline)
    endif
    let l:line_number = l:line_number - 1
  endwhile
  return ''
endfunction

" strip the given prompt from the commandline, returning only the command
function! s:strip_prompt(commandline, prompt)
  let l:prompt_idx = match(a:commandline, a:prompt . s:space_or_eol . '\zs')
  return strpart(a:commandline, l:prompt_idx)
endfunction

function! s:strip_command(commandline, prompt)
  let l:prompt_idx = match(a:commandline, '\ze' . a:prompt . s:space_or_eol)
  return strpart(a:commandline, 0, l:prompt_idx)
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

" Mappings
tnoremap <silent> <Plug>TerminusEdit <c-\><c-n>:call g:terminus_terms[bufnr('%')].Edit()<cr>
tmap <c-x> <Plug>TerminusEdit

" Commands
command! -nargs=? TerminusOpen call Terminus.New(<f-args>)


if !exists('g:terminus_terminals')
  let g:terminus_terminals = {}
endif

if !exists('g:terminus_use_xterm_title')
  let g:terminus_use_xterm_title = 1
endif

if !exists('g:terminus_max_command_length')
  let g:terminus_max_command_length = 10000
endif

if !exists('g:terminus_default_prompt')
  let g:terminus_default_prompt = '>'
endif

" if a user has not entered a command then there will not be a space after the last prompt
let s:space_or_eol = '\( \|$\|\n\)'

" xterm title hack
" ESC =  = \033 = \e
" BEL =  = \007
let s:xterm_title_hack = ']0;\zs.\{-}\ze'

" [#D = Cursor Backward - Moves the cursor backward by # columns
" [m  = 
" (B  = mystery, possible cursor down
" [K  = erase to eol
" [1K = erase to start of line
" [2K = erase entire line
" >   = Numeric Keypad Mode
" ?#h = set mode? ?1h = Application Cursor Keys (DECCKM)
" ?#l = reset mode? ?1l = Normal Cursor Mode (DECCOM)
" =⏎  = seems to be before the actual prompt, Application Keypad Mode

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

function! Terminus.EditCommand()
  let l:command = self.GetCommand()
  call self.OpenScratch(l:command)
  call self.ClearCommand()
endfunction

function! Terminus.SetCommand(command)
  call jobsend(self.job_id, a:command)
endfunction

function! Terminus.GetPrompt()
  if !empty(self.prompt)
    return self.prompt
  else
    return get(g:, 'terminus_default_prompt', '>')
  endif
endfunction

" Set the prompt for the current 
function! Terminus.SetPrompt(...)
  if a:0 > 0
    " remove apostrophes and quotations
    let self.prompt = substitute(a:1, '[''\|"]', '', 'g')
  else
    let self.prompt = get(g:, 'terminus_default_prompt', '>')
  endif
endfunction

function! Terminus.GetCommand()
  let l:commandline = s:get_commandline(self.GetPrompt())
  return s:format_command(s:strip_prompt(l:commandline, self.GetPrompt()))
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
  execute 'autocmd BufUnload <buffer> 
        \ call g:terminus_terminals[' . self.bufnr . '].SetCommand(join(getline(1, ''$''), "\n"))
        \ | autocmd! BufUnload <buffer>'

  call s:put_command(a:command)

endfunction

function! Terminus.Erase()
  if has_key(g:terminus_terminals, self.bufnr)
    call remove(g:terminus_terminals, self.bufnr)
  endif
endfunction

if !exists("*TerminusHandleStdout")
  function! TerminusHandleStdout(job_id, data, event)
    for key in keys(g:terminus_terminals)
      if g:terminus_terminals[key].job_id ==# a:job_id
        call g:terminus_terminals[key].HandleStdout(a:data, a:event)
      endif
    endfor
  endfunction
endif

" WARNING: this is handled asynchronously! 
" Currently only extracts and stores the prompt
function! Terminus.HandleStdout(data, event)
  if get(g:, 'terminus_use_xterm_title', 0)
    if bufnr('%') ==# self.bufnr
      let self.stdout_buf = self.stdout_buf . join(a:data, '')
      " processing line by line prevents buffer getting too big
      let l:idx = match(self.stdout_buf, '[]')
      while l:idx !=# -1
        " include the  or  in the line
        let l:line = strpart(self.stdout_buf, 0, l:idx + 1)
        " trim buffer
        let self.stdout_buf = strpart(self.stdout_buf, l:idx + 1)
        if get(g:, 'terminus_enable_logging', 0)
          " format output to make it easier to read
          let l:output = s:strip_color_codes(l:line)
          let l:output = substitute(l:output, '(B', '', 'g')  " remove mystery control code
          let l:output = substitute(l:output, '\[[0-9;]\+D', '', 'g')
          let l:output = substitute(l:output, '', '^[', 'g')
          let l:output = substitute(l:output, '', '^M', 'g')
          let l:output = substitute(l:output, '', '^G', 'g')
          call writefile([l:output], '/tmp/terminus.log', 'a')
        endif
        let l:title = matchstr(l:line, s:xterm_title_hack)
        if !empty(l:title)
          let self.fname = fnameescape(self.bufnr . ' ' . l:title)
          call self.Rename()
        endif
        " there may be more than one line included in each event!
        let l:idx = match(self.stdout_buf, '[]')
      endwhile
    endif
  endif
endfunction

function! Terminus.Rename()
  execute 'silent! file ' . self.fname
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
  let obj.prompt = g:terminus_default_prompt
  let obj.stdout_buf = ''
  let obj.shell = l:cmd

  " open new empty buffer which the terminal will use
  enew
  let obj.job_id = termopen(l:cmd, {'on_stdout':function('TerminusHandleStdout')})
  startinsert

  let obj.bufnr = bufnr('%')
  let obj.fname = ''

  let g:terminus_terminals[obj.bufnr] = obj

  execute 'autocmd BufDelete <buffer> 
        \ call g:terminus_terminals[' . obj.bufnr . '].Erase() 
        \ | autocmd! BufDelete <buffer>'

  return obj
endfunction

function! s:strip_color_codes(input)
  return substitute(a:input, '\e\[[0-9;]*[mK]', '', "g")
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

function! s:current_terminal()
  return g:terminus_terminals[bufnr('%')]
endfunction

" Mappings
tnoremap <silent> <Plug>TerminusEditCommand <c-\><c-n>:call <SID>current_terminal().EditCommand()<cr>

if get(g:, 'terminus_default_mappings', 0)
  tmap <c-x> <Plug>TerminusEditCommand
endif

" Commands

" TerminusOpen should mirror the `:terminal`
command! -nargs=? TerminusOpen call Terminus.New(<f-args>)
command! -nargs=0 TerminusEditCommand call <SID>current_terminal().EditCommand()
command! -nargs=? TerminusSetPrompt call <SID>current_terminal().SetPrompt(<f-args>)

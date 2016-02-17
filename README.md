# nvim-terminus

Edit your current command in a scratch buffer. The command may come from any
shell running inside a [Neovim](https://github.com/neovim/neovim) terminal,
e.g.  bash/fish/lua/ruby/... 

This plugin provides the same functionality as
[nvim-editcommand](https://github.com/brettanomyces/nvim-editcommand) but uses
jobcontrol to communicate with the terminal rather than the dirty vimscipt hack
used by nvim-editcommand. The downside of this is that terminals must be
started using the TerminusOpen function/command provided by this plugin. The
upside is we now have access to the stdin/stdout of the terminal.

This plugin differs from [neoterm](https://github.com/kassio/neoterm) in that
nvim-terminus allows you to edit a command from a terminal, inside a text buffer, while
neoterm allows you to run a command from a text buffer inside a terminal.

## Features

### Edit command

While in `TERMINAL` mode `<c-e><c-x>` can be used to open the current command inside a scratch buffer. The contents of the scratch buffer are then sent back to the terminal (via stdin) once the scratch buffer is closed.

### Update terminal name

By parsing the stdout of the terminal we can keep track of the current prompt and update the name of the terminal buffer to match. This makes it easier to identify which terminal is which when viewing the buffer list (`:ls`).

## Installations

### [vim-plug](https://github/junegunn/vim-plug)

    call plug#begin('~/.nvim/plugged')
    Plug 'brettanomyces/nvim-terminus'
    ...
    call plug#end()

## Configuration

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

While in `TERMINAL` mode `<c-x>` can be used to open the current command inside a scratch buffer. The contents of the scratch buffer are then sent back to the terminal (via stdin) once the scratch buffer is closed.

### Use Xterm title

Use the xterm title as the terminal buffer name. This makes it much easier to differentiate between different terminal buffers. The title will depend on what your shell emits, fish shell will show the current command and directory.

`:ls` with Xterm titles enabled 

    :ls
      1   h- "1 fish  /tmp"                    line 45
      5  %a- "5 brettanomyces@brettanomyces: ~/Workspace"                    line 45
      12  h- "12 sl  /home/brettanomyces"                           line 45

`:ls` without Xterm titles enabled

    :ls
      3   h- "termp:/.//7596:/usr/local/bin/fish" line 45
      4  #h- "termp:/.//7627:/usr/local/bin/fish" line 45
      5  %a- "termp:/.//7686:/usr/local/bin/fish" line 45

If you are using [fish-shell](https://fishshell.com/) then you can control what is displayed in the title by defining `~/.config/fish/functions/fish_title.fish`

    function fish_title
      echo -n 'brett'
    end

To update the title for other shells see: [http://tldp.org/HOWTO/Xterm-Title-4.html](http://tldp.org/HOWTO/Xterm-Title-4.html)


## Installation

### [vim-plug](https://github/junegunn/vim-plug)

    call plug#begin('~/.nvim/plugged')
    Plug 'brettanomyces/nvim-terminus'
    ...
    call plug#end()

## Commands

Open a new terminal

    TerminusOpen

    TerminausOpen /bin/sh

Edit the current terminal command

    TerminusEditCommand

Set the terminal prompt

    TerminusSetPrompt >

## Configuration

Enable the default mappings

    g:terminus_default_mappings = 1
   
Set the default prompt 

    g:terminus_default_prompt = '>'

Enable xterm titles

    g:terminus_use_xterm_title = 1

## TODO

* Autodetect prompt - useful if a user enters a interpreter inside a shell running in a terminal buffer
* Extract command results - could be useful for something ???
* Intergration with neoterm

## Contributing

Please do. Issues/PR's/Ideas are all welcome!



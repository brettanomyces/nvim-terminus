# nvim-terminus

Edit your current command in a scratch buffer. The command may come from any
commandline interpreter running inside a
[Neovim](https://github.com/neovim/neovim) terminal, e.g.
bash/fish/lua/ruby/... 

This plugin provides the same functionality as
[nvim-editcommand](https://github.com/brettanomyces/nvim-editcommand) but uses
jobcontrol to communicate with the terminal rather than the dirty vimscipt hack
used by nvim-editcommand. The downside of this is that terminals must be
started using the TerminusOpen function/command provided by this plugin.

This plugin differs from [neoterm](https://github.com/kassio/neoterm) in that
nvim-terminus allows you to edit a command from a terminal, inside a text buffer, while
neoterm allows you to run a command from a text buffer inside a terminal.

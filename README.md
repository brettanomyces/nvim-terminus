# nvim-terminus

A plugin to allow one to easily move code between a 'normal' buffer and a
terminal buffer.

This plugin attempts to cover two use cases:

1. Edit your current terminal command inside a buffer (and copy it back).
2. Run some code from your current buffer inside a terminal. 

Terminals are shell interpreters running in a Neovim terminal buffer. E.g.
Bash, Fish, Zsh, Python, Ruby, etc. 

If you are only interested in usecase #2 then I suggest using
[kassio/neoterm](https://github.com/kassio/neoterm) which this plugin is
heavily inspired by.


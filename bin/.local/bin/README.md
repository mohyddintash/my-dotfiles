# Example for using the tmux-sessionizer
Note: You may need to install fzf if you haven't already (sudo apt install fzf, brew install fzf, etc.).

Use It

Now, from any terminal, you can just type:
Bash

```sh
tmux-sessionizer
```

An fzf menu will pop up. Start typing the name of any project, use the arrow keys to select, press Enter, and you'll be dropped directly into its tmux session.


assuming that stow command was run form dotfiles dir stow bin and thet ~/.local/bin is in the $PATH

# Example for your astro-mizar project, this is for bootsterapping one session for a project
# use tmux-sessionizer for fuzzyfinding a project, it uses tmux-project-bootstrapper and fzf and find under the hood.
tmux-project-bootsrapper ~/path/to/your/projects/astro-mizar

# Nvim Setup Information

This document provides a summary of the most important shortcuts and commands to help you master and navigate this nvim setup.

This setup is based on [LazyVim](https://www.lazyvim.org/).

## Leader Key

The leader key is a special key that is used to prefix many custom shortcuts. In this configuration, the leader key is `space`.

So, whenever you see `<leader>`, you should press the `space` bar.

## File Explorer (neo-tree)

This setup uses `neo-tree` as a file explorer.

-   `<leader>e`: Toggle the file explorer.
-   `o`: Open a file or folder.
-   `a`: Create a new file.
-   `d`: Delete a file or folder.
-   `r`: Rename a file or folder.
-   `c`: Copy a file or folder.
-   `x`: Cut a file or folder.
-   `p`: Paste a file or folder.
-   `q`: Close the file explorer.

## Basic Navigation

-   `<leader><leader>`: Search for files (Telescope).
-   `<leader>fb`: Search buffers.
--   `gd`: Go to definition.
-   `gr`: Go to references.
-   `gD`: Go to declaration.
-   `gy`: Go to type definition.

## Editing

-   `<leader>c`: Format code.
-   `gcc`: Toggle comments.
-   `<leader>co`: Organize imports (for TypeScript).
-   `<leader>cR`: Rename file (for TypeScript).

## Telescope

Telescope is a powerful fuzzy finder.

-   `<leader><leader>`: Find files.
-   `<leader>fg`: Find text in files (live grep).
-   `<leader>fb`: Find buffers.
-   `<leader>fh`: Find help tags.
-   `<leader>fo`: Find old files.
-   `<leader>fp`: Find plugin files.

## LSP (Language Server Protocol)

LSP provides features like go-to-definition, find-references, and diagnostics.

-   `K`: Show hover documentation.
-   `[d`: Go to the previous diagnostic.
-   `]d`: Go to the next diagnostic.
-   `<leader>ca`: Code actions.

## Git

-   `<leader>gg`: Open Lazygit.
-   `<leader>gb`: Git blame.
-   `<leader>gL`: Git log.

## LazyVim

-   `<leader>l`: Open the LazyVim dashboard.
-   `<leader>L`: Show the LazyVim changelog.
-   `<leader>x`: Open the trouble panel.

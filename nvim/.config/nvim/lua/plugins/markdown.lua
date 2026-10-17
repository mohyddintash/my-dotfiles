-- Tweaks on top of the LazyVim markdown extra (enabled in lazyvim.json).
return {
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          args = { "--config", vim.fn.stdpath("config") .. "/.markdownlint-cli2.yaml", "-" },
        },
      },
    },
  },
}

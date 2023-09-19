# cmp-bibtex

Bibtex completion source for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp). Currently supports `\addbibresource{}`, or manually specified file names.

Note, writing this was a quick one day job between classes, and as such many things may not work yet. Open an issue and I'll get around to sorting things out as quickly as I can.

## Setup

Install (e.g. with [lazy.nvim](https://github.com/folke/lazy.nvim)), and register `"bibtex"` as a completion source:

```lua
require("cmp").setup({
  sources = { name = "bibtex" }
})
```

## Configuration

Call `require("cmp-bibtex").setup(opts)`, where opts is a table, supporting the following options:

* `files`: A list of `.bib` files which will always be parsed for suggestions.
* `filetypes`: A list of filetypes for which the source will be loaded (default `{ "markdown", "tex" }`)

For example, to enable the source for Rmarkdown files:

```lua
require("cmp-bibtex").setup({
  filetypes = { "markdown", "rmd", "tex" }
})
```

Or, with [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "liamvdvyver/cmp-bibtex",
  opts = { filetypes = { "markdown", "rmd", "tex" } }
}
```

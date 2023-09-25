local util = require("cmp-bibtex.util")
local source = {}

-- Set defaults
source.opts = {
  files = {},
  filetypes = { "markdown", "tex" },
}

source.setup = function(opts)
  source.opts = vim.tbl_extend("force", source.opts, opts)
end

source.new = function()
  local self = setmetatable({}, { __index = source })
  return self
end

function source:is_available()
  for _, v in ipairs(source.opts.filetypes) do
    if vim.bo.filetype == v then
      return true
    end
  end
  return false
end

function source:get_debug_name()
  return 'bibtex'
end

-- TODO: Check context before "{"
function source:get_trigger_characters()
  return { "@", "{" }
end

function source:complete(params, callback)
  local context = params.context

  if not util.should_complete(context) then return end

  if source.cache then
    callback({
      items = source.cache,
      isIncomplete = true
    })
  end

  local parsed_entries = {}

  local files = util.clean_filenames(vim.tbl_flatten({ source.opts.files, util.get_bibresources(context) }))
  local file_keys = util.vals_to_keys(files)

  for file, _ in pairs(file_keys) do
    if not util.file_exists(file) then goto continue end

    io.input(file)
    local contents = io.read("*a")

    if contents then
      local entries = contents:gmatch("@%w*%s*%b{}")

      for entry in entries do
        local key             = entry:match("@%w*%s*{%c?%w*,?"):gsub("@%w*%s*{%c?", ""):gsub(",?", "")
        local author          = util.get_field(entry, "author")
        local year            = util.get_field(entry, "year")
        local title           = util.get_field(entry, "title")

        local completion_item = {
          label = key,
          documentation = {
            kind = "markdown",
            value = "# " .. title .. "\n\n" .. author .. " (" .. year .. ")"
          }
        }

        if key then table.insert(parsed_entries, completion_item) end
      end
    end
    ::continue::
  end

  callback({
    items = parsed_entries,
    isIncomplete = false
  })

  source.cache = parsed_entries
end

function source:resolve(completion_item, callback)
  callback(completion_item)
end

function source:execute(completion_item, callback)
  callback(completion_item)
end

return source

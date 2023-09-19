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

-- function source:get_keyword_pattern()
--   return '@'
-- end

-- TODO: Check context before "{"
function source:get_trigger_characters()
  return { "@", "{" }
end

function source.get_field(entry, field)
  return (string.match(entry, field .. "%s*=%s*%b{}") or "NA"):gsub(field .. "%s*=%s*", ""):gsub("[{}]", "")
end

function source.get_bibresources(context)
  local ret = {}
  if context.filetype == "tex" then
    local lines = vim.api.nvim_buf_get_lines(context.bufnr, 0, -1, false)

    for _, line in ipairs(lines) do
      -- TODO: Support multiple per line
      -- TODO: Support relative paths
      -- TODO: Support other methods of adding bib resources
      -- TODO: Exclude commented out lines
      local matches = line:gmatch("\\addbibresource%b{}")

      for match in matches do
        local bib_file = match:gsub("(\\addbibresource{)(.*)(}%s*)", "%2")
        table.insert(ret, bib_file)
      end
    end
  end
  return ret
end

function source.file_exists(file)
  local f = io.open(file, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

function source:complete(params, callback)
  local isIncomplete = false
  local context = params.context

  local parsed_entries = {}

  local files = vim.tbl_flatten({ source.opts.files, source.get_bibresources(context) })

  local file_keys = {}

  for _, v in ipairs(files) do
    file_keys[v] = true
  end

  for file, _ in pairs(file_keys) do
    if not source.file_exists(file) then goto continue end

    -- TODO: Expand ~/$HOME
    io.input(file)
    local contents = io.read("*a")

    if contents then
      local entries = contents:gmatch("@%w*%s*%b{}")

      for entry in entries do
        local key             = entry:match("@%w*%s*{%c?%w*,?"):gsub("@%w*%s*{%c?", ""):gsub(",?", "")
        local author          = source.get_field(entry, "author")
        local year            = source.get_field(entry, "year")
        local title           = source.get_field(entry, "title")

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
    isIncomplete = isIncomplete
  })
end

function source:resolve(completion_item, callback)
  callback(completion_item)
end

function source:execute(completion_item, callback)
  callback(completion_item)
end

return source

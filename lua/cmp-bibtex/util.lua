local M = {}

function M.get_field(entry, field)
  return (string.match(entry, field .. "%s*=%s*%b{}") or "NA"):gsub(field .. "%s*=%s*", ""):gsub("[{}]", "")
end

function M.get_bibresources(context)
  local ret = {}
  if context.filetype == "tex" then
    local lines = vim.api.nvim_buf_get_lines(context.bufnr, 0, -1, false)

    for _, line in ipairs(lines) do
      -- TODO: Support multiple per line
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

function M.file_exists(file)
  local f = io.open(file, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

function M.should_complete(context)
  local line = vim.api.nvim_buf_get_text(
    context.bufnr,
    context.cursor.row - 1, 0,
    context.cursor.row - 1, context.cursor.character,
    {}
  )[1]
  if string.match(line, "@$") or string.match(line, "\\cite%a?{$") then
    return true
  end
  return false
end

function M.clean_filenames(files)
  local ret = {}
  for _, v in ipairs(files) do
    local filename = vim.fn.expand(v)
    if not string.match(filename, "^/") then
      -- TODO: get actual filename from request context
      filename = vim.fn.expand("%:p:h") .. "/" .. filename
    end
    table.insert(ret, filename)
  end
  return ret
end

function M.vals_to_keys(list)
  local ret = {}
  for _, v in ipairs(list) do
    ret[v] = true
  end
  return ret
end

function M.flatten_once(tab)
  local ret = {}
  for _, vi in pairs(tab) do
    for _, vj in pairs(vi) do
      table.insert(ret, vj)
    end
  end
  return ret
end

function M.completion_items(file)
  local ret = {}

  io.input(file)
  local contents = io.read("*a")

  if contents then
    local entries = contents:gmatch("@%w*%s*%b{}")

    for entry in entries do
      local key             = entry:match("@%w*%s*{%c?%w*,?"):gsub("@%w*%s*{%c?", ""):gsub(",?", "")
      local author          = M.get_field(entry, "author")
      local year            = M.get_field(entry, "year")
      local title           = M.get_field(entry, "title")

      local completion_item = {
        label = key,
        documentation = {
          kind = "markdown",
          value = "# " .. title .. "\n\n" .. author .. " (" .. year .. ")"
        }
      }

      if key then table.insert(ret, completion_item) end
    end
  end

  return ret
end

return M

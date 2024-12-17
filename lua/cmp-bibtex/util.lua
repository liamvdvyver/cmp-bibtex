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
    context.cursor.row - 1,
    0,
    context.cursor.row - 1,
    context.cursor.character,
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
      local key = entry:match("@%w*%s*{%c?%w*,?"):gsub("@%w*%s*{%c?", ""):gsub(",?", "")
      local author = M.get_field(entry, "author")
      local year = M.get_field(entry, "year")
      local title = M.get_field(entry, "title")
      local journal = M.get_field(entry, "journaltitle") or M.get_field(entry, "journal")
      local volume = M.get_field(entry, "volume")
      local number = M.get_field(entry, "number")
      local pages = M.get_field(entry, "pages")
      local publisher = M.get_field(entry, "publisher")
      local entry_type = entry:match("@%w*"):sub(2):lower() -- Ex: article, book

      -- Format APA-stil preview
      local apa_preview = "**" .. (author or "Unknown Author") .. ".** "
      if year and year ~= "NA" then
        apa_preview = apa_preview .. "(" .. year .. "). "
      end
      if title and title ~= "NA" then
        apa_preview = apa_preview .. "*" .. title .. ".* "
      end

      if entry_type == "article" and journal and journal ~= "NA" then
        apa_preview = apa_preview .. journal
        if volume and volume ~= "NA" then
          apa_preview = apa_preview .. ", *" .. volume .. "*"
        end
        if number and number ~= "NA" then
          apa_preview = apa_preview .. "(" .. number .. ")"
        end
        if pages and pages ~= "NA" then
          apa_preview = apa_preview .. ", " .. pages
        end
        apa_preview = apa_preview .. "."
      elseif publisher and publisher ~= "NA" then
        apa_preview = apa_preview .. publisher .. "."
      end

      local completion_item = {
        label = key,
        documentation = {
          kind = "markdown",
          value = apa_preview,
        },
      }

      if key then
        table.insert(ret, completion_item)
      end
    end
  end

  return ret
end

return M

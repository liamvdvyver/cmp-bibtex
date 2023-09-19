M = {}

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

return M

local M = {}

-- Extract a specific field from a BibTeX entry
function M.get_field(entry, field)
  -- Match the field and preserve the content within the outermost braces
  local match = string.match(entry, field .. "%s*=%s*%b{}")
  if match then
    local content = match:match("{(.*)}") -- Extract inside the outermost {}
    return content or "NA"
  end
  return "NA"
end

-- Convert a list of values into a dictionary-like table with keys
function M.vals_to_keys(list)
  local ret = {}
  for _, v in ipairs(list) do
    ret[v] = true
  end
  return ret
end

-- Extract BibTeX resource files linked in a LaTeX file
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
        local bib_file = match:match("\\addbibresource{(.*)}")
        if bib_file then
          table.insert(ret, bib_file)
        end
      end
    end
  end
  return ret
end

-- Check if a file exists
function M.file_exists(file)
  local f = io.open(file, "r")
  if f then
    io.close(f)
    return true
  end
  return false
end

-- Decide whether to trigger BibTeX completion
function M.should_complete(context)
  local line = vim.api.nvim_buf_get_text(
    context.bufnr,
    context.cursor.row - 1,
    0,
    context.cursor.row - 1,
    context.cursor.character,
    {}
  )[1]
  return string.match(line, "@$") or string.match(line, "\\cite%a?{$") or false
end

-- Clean relative file paths for BibTeX files
function M.clean_filenames(files)
  local ret = {}
  for _, v in ipairs(files) do
    local filename = vim.fn.expand(v)
    if not string.match(filename, "^/") then
      filename = vim.fn.expand("%:p:h") .. "/" .. filename
    end
    table.insert(ret, filename)
  end
  return ret
end

-- Flatten a nested table one level deep
function M.flatten_once(tab)
  local ret = {}
  for _, vi in pairs(tab) do
    for _, vj in pairs(vi) do
      table.insert(ret, vj)
    end
  end
  return ret
end

-- Convert LaTeX-encoded text to UTF-8
local function latex_to_utf8(text)
  if not text then
    return ""
  end

  local replacements = {
    -- Skandinavian accents
    ['\\"a'] = "ä",
    ['\\"A'] = "Ä",
    ['\\"o'] = "ö",
    ['\\"O'] = "Ö",
    ["\\aa"] = "å",
    ["\\AA"] = "Å",

    -- German accents
    ['\\"u'] = "ü",
    ['\\"U'] = "Ü",
    ["\\ss"] = "ß",

    -- Hungarian and misc accents
    ["\\'a"] = "á",
    ["\\'A"] = "Á",
    ["\\'e"] = "é",
    ["\\'E"] = "É",
    ["\\'i"] = "í",
    ["\\'I"] = "Í",
    ["\\'o"] = "ó",
    ["\\'O"] = "Ó",
    ["\\'u"] = "ú",
    ["\\'U"] = "Ú",
    ['\\"u'] = "ű",
    ['\\"U'] = "Ű",

    -- French accents
    ["\\`a"] = "à",
    ["\\`A"] = "À",
    ["\\`e"] = "è",
    ["\\`E"] = "È",
    ["\\`u"] = "ù",
    ["\\`U"] = "Ù",
    ["\\^a"] = "â",
    ["\\^A"] = "Â",
    ["\\^e"] = "ê",
    ["\\^E"] = "Ê",
    ["\\^o"] = "ô",
    ["\\^O"] = "Ô",
    ["\\^u"] = "û",
    ["\\^U"] = "Û",

    -- Spanish and Portugese accents
    ["\\~n"] = "ñ",
    ["\\~N"] = "Ñ",
    ["\\~a"] = "ã",
    ["\\~A"] = "Ã",
    ["\\~o"] = "õ",
    ["\\~O"] = "Õ",

    -- General accents
    ["\\c{c}"] = "ç",
    ["\\c{C}"] = "Ç",

    -- Commands
    ["\\textsuperscript"] = "⁺",
    ["\\textsubscript"] = "₋",
  }

  for k, v in pairs(replacements) do
    text = text:gsub(k, v)
  end

  -- Handle dashes at the end to avoid interfering with other replacements
  text = text:gsub("%-%-%-", "—") -- Replace "---" with em-dash
  text = text:gsub("%-%-", "–") -- Replace "--" with en-dash

  -- Remove all curly braces
  text = text:gsub("[{}]", "")

  return text
end

-- Generate completion items from a BibTeX file
function M.completion_items(file)
  local ret = {}

  io.input(file)
  local contents = io.read("*a")

  if contents then
    -- Match individual BibTeX entries
    local entries = contents:gmatch("@%w*%s*%b{}")

    for entry in entries do
      -- Extract the key and type
      local key = entry:match("@%w*%s*{%s*(%w+),?")
      local entry_type = entry:match("@(%w+)") or "unknown"

      -- Extract other fields
      local author = latex_to_utf8(M.get_field(entry, "author"))
      local year = M.get_field(entry, "year")
      local title = latex_to_utf8(M.get_field(entry, "title"))
      local pages = latex_to_utf8(M.get_field(entry, "pages"))
      local journal = latex_to_utf8(M.get_field(entry, "journaltitle") or M.get_field(entry, "journal"))

      -- Format documentation in APA-like style with type
      local apa_preview = "**" .. (author or "Unknown Author") .. ".** "
      if year and year ~= "NA" then
        apa_preview = apa_preview .. "(" .. year .. "). "
      end
      if title and title ~= "NA" then
        apa_preview = apa_preview .. "*" .. title .. ".* "
      end
      if journal and journal ~= "NA" then
        apa_preview = apa_preview .. journal .. ". "
      end
      apa_preview = apa_preview .. "\n\n{" .. entry_type .. "}" -- Add type in braces

      -- Create the completion item
      if key then
        table.insert(ret, {
          label = key,
          documentation = { kind = "markdown", value = apa_preview },
        })
      end
    end
  end

  return ret
end

return M

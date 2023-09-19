local source = {}

source.new = function()
  local self = setmetatable({}, { __index = source })
  return self
end

function source:is_available()
  return true
end

function source:get_debug_name()
  return 'bibtex'
end

-- function source:get_keyword_pattern()
--   return '@'
-- end

function source:get_trigger_characters()
  return { "@", "{" }
end

source.files = { "/home/lvdv/Documents/zotero/bib.bib" }

function source.get_field(entry, field)
  return (string.match(entry, field .. "%s*=%s*%b{}") or "NA"):gsub(field .. "%s*=%s*", ""):gsub("[{}]", "")
end

function source:complete(_, callback)
  local isIncomplete = false

  local parsed_entries = {}

  for _, file in ipairs(source.files) do
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

require('cmp').register_source("bibtex", source.new())

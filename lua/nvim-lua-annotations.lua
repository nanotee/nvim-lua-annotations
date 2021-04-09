local vim_globals = [[
--- The vim global namespace. See `:help lua-vim`
_G.vim = {}

--- The API namescape. See `:help api-global`
_G.vim.api = {}

--- Global vim options. See `:help lua-vim-options`
_G.vim.o = {}

--- Window-local vim options. See `:help lua-vim-options`
_G.vim.wo = {}

--- Buffer-local vim options. See `:help lua-vim-options`
_G.vim.bo = {}

]]

local api_types_map = {
    Object = 'any',
    Integer = 'integer',
    Float = 'number',
    Boolean = 'boolean',
    String = 'string',
    Dictionary = 'table<string,any>',
    Array = 'any[]',
    ['ArrayOf(Integer)'] = 'integer[]',
    ['ArrayOf(Integer, 2)'] = 'integer[]',
    ['ArrayOf(String)'] = 'string[]',
    ['ArrayOf(Dictionary)'] = 'table<string,any>[]',
    LuaRef = 'function',
    Buffer = 'integer',
    Window = 'integer',
    Tabpage = 'integer',
    ['ArrayOf(Buffer)'] = 'integer[]',
    ['ArrayOf(Window)'] = 'integer[]',
    ['ArrayOf(Tabpage)'] = 'integer[]',
}

local function format_params(params)
    if #params == 0 then return end

    local formatted_params = {}

    for _, param in ipairs(params) do
        local ptype, pname = unpack(param)
        if pname == 'end' then pname = 'end_' end
        table.insert(formatted_params, ('--- @param %s %s'):format(pname, api_types_map[ptype]))
    end

    return table.concat(formatted_params, '\n')
end

local function format_return_type(return_type)
    if return_type ~= 'void' then
        return ('--- @return %s'):format(api_types_map[return_type])
    end
end

local function format_signature(func_name, params)
    params = vim.tbl_map(
        function(param)
            if param[2] == 'end' then param[2] = 'end_' end
            return param[2]
        end,
        params)

    return ('function vim.api.%s(%s) end'):format(func_name, table.concat(params, ', '))
end

local function generate_api_annotations()
    local annotations = {}

    for _, func in ipairs(vim.fn.api_info().functions) do
        if not func.deprecated_since then
            local params = format_params(func.parameters)
            local return_type = format_return_type(func.return_type)
            local signature = format_signature(func.name, func.parameters)
            local annotation = vim.tbl_filter(function(item) return item ~= nil end, {params, return_type, signature})
            table.insert(annotations, table.concat(annotation, '\n'))
        end
    end

    return table.concat(annotations, '\n\n')
end

local option_scopes_map = {
    global = 'o',
    win = 'wo',
    buf = 'bo',
}

local function format_type(type)
    return ('--- @type %s'):format(type)
end

local function format_variable_name(scope, name)
    return ('vim.%s.%s = nil'):format(scope, name)
end

local function make_option_annotation(type, scope, name)
    local option_type = format_type(type)
    local option_name = format_variable_name(option_scopes_map[scope], name)
    local annotation = {option_type, option_name}
    return table.concat(annotation, '\n')
end

local function generate_nvim_options_annotations()
    local annotations = {}

    for _, option in pairs(vim.api.nvim_get_all_options_info()) do
        if option.name ~= '' then
            local annotation = {}
            table.insert(annotation, make_option_annotation(option.type, option.scope, option.name))
            if option.global_local then
                table.insert(annotation, make_option_annotation(option.type, 'global', option.name))
            end
            table.insert(annotations, table.concat(annotation, '\n'))
        end
    end

    return table.concat(annotations, '\n\n')
end

local function write_to_file(path)
    vim.validate {
        path = {path, 'string'},
    }
    if vim.fn.filereadable(path) == 1 then
        local answer = vim.fn.input(('File "%s" exists. Overwrite? y/n: '):format(path))
        if not answer:match('^[yY][eE]?[sS]?$') then return end
    end
    local api_annotations = generate_api_annotations()
    local nvim_options_annotations = generate_nvim_options_annotations()
    local file, open_err = io.open(path, 'w+')
    assert(not open_err, open_err)
    local _, write_err file:write(
        vim_globals,
        api_annotations,
        '\n\n',
        nvim_options_annotations
        )
    if write_err then
        file:close()
        error(write_err)
    end
    file:close()
end

return {
    write_to_file = write_to_file
}

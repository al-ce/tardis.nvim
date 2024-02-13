local M = {}

---@class TardisKeyHints
---@field session TardisSession
---@field keymap TardisKeymap
---@field win integer
---@field buf integer
M.KeyHints = {}

---@param session TardisSession
function M.KeyHints:new(session)
    local keyhints = {}
    self.__index = self
    self.session = session
    self.keymap = self:get_keymap()
    return setmetatable(keyhints, self)
end

function M.KeyHints:get_keymap()
    return self.session.parent.config.keymap
end

---@param width integer
---@param height integer
function M.KeyHints:create_window(width, height)
    local cur_win = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(self.session.origin_win)
    local win = vim.api.nvim_open_win(0, true, {
        relative = 'win',
        width = width,
        height = height,
        row = (vim.api.nvim_win_get_height(self.session.origin_win) - height) / 2,
        col = vim.api.nvim_win_get_width(self.session.origin_win) - width - 3,
        style = 'minimal',
        border = 'single',
        title = { { 'TARDIS Keymap', 'Keyword' } },
        title_pos = 'center',
    })
    vim.api.nvim_set_current_win(cur_win)
    return win
end

---@param keymap_display string[]
---@param hint_name_width integer
function M.KeyHints:create_buffer(keymap_display, hint_name_width)
    self.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, keymap_display)
    vim.api.nvim_win_set_buf(self.win, self.buf)
    vim.api.nvim_set_option_value('modifiable', false, { buf = self.buf })

    for linenum = 1, #keymap_display do
        vim.api.nvim_buf_add_highlight(self.buf, -1, 'String', linenum - 1, hint_name_width, -1)
    end
end

function M.KeyHints:show()
    local keymap = self.keymap
    local keymap_display = {
        '     Next -> ' .. keymap.next,
        '     Prev -> ' .. keymap.prev,
        '     Quit -> ' .. keymap.quit,
        '  Rev Msg -> ' .. keymap.revision_message,
        ' Move Msg -> ' .. keymap.move_message,
        'Lock Base -> ' .. keymap.lock_diff_base,
        'Show Diff -> ' .. keymap.toggle_diff,
        'Diffsplit -> ' .. keymap.toggle_split,
        'Telescope -> ' .. keymap.telescope,
        '    Hints -> ' .. keymap.keyhints,
    }
    local hint_name_width = string.len('Telescope -> ')
    local key_width = -1
    for _, v in pairs(keymap) do
        if string.len(v) > key_width then
            key_width = string.len(v)
        end
    end

    local win_width = hint_name_width + key_width + 1

    self.win = self:create_window(win_width, #keymap_display)
    self:create_buffer(keymap_display, hint_name_width)
end

function M.KeyHints:close()
    if self.buf and vim.api.nvim_buf_is_valid(self.buf) then
        vim.api.nvim_buf_delete(self.buf, { force = true })
        self.buf = nil
    end
end

function M.KeyHints:toggle()
    if self.win and vim.api.nvim_win_is_valid(self.win) then
        self:close()
    else
        self:show()
    end
end

function M.KeyHints:refresh()
    if self.win and vim.api.nvim_win_is_valid(self.win) then
        self:close()
        self:show()
    end
end

return M

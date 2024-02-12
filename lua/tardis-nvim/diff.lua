local M = {}

---@class TardisDiff
---@field session TardisSession
---@field diff_base string
---@field diff_split boolean
---@field diff_buf integer
---@field diff_win integer
---@field locked boolean
M.Diff = {}

---@param session TardisSession
function M.Diff:new(session)
    local diff = {}
    self.__index = self
    self.session = session
    return setmetatable(diff, self)
end

function M.Diff:has_diff_buf()
    return self.diff_buf and vim.api.nvim_buf_is_valid(self.diff_buf)
end

---@param win integer
---@param enable boolean
function M.Diff:show(win, enable)
    if not vim.api.nvim_win_is_valid(win) then
        return
    end
    vim.api.nvim_set_current_win(win)
    local cmd = enable and 'diffthis' or 'diffoff'
    vim.cmd(cmd)
end

---@return integer
-- A hidden floating window so that we can use the diffthis command with a single visible window
function M.Diff:create_dummy_win()
    local win = vim.api.nvim_open_win(self.diff_buf, false, {
        relative = 'win',
        win = self.session.origin_win,
        height = 1,
        width = 1,
        bufpos = { 0, 0 },
        hide = true,
    })
    return win
end

---@return integer
function M.Diff:create_split_win()
    local split_opt = vim.api.nvim_get_option_value('splitright', {})
    vim.api.nvim_set_option_value('splitright', false, {})
    vim.cmd('vsplit')
    vim.api.nvim_set_option_value('splitright', split_opt, {})
    self.diff_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(self.diff_win, self.diff_buf)
    return self.diff_win
end

function M.Diff:create_buffer()
    local config = self.session.parent.config.settings
    local initial_diff_base = config.diff_base

    if self.diff_split == nil then
        self.diff_split = config.diff_split
    end

    if initial_diff_base == '' or self.diff_split == false then
        initial_diff_base = self.session.buffers[2].revision
        self.diff_base = ''
        self.locked = false
    else
        initial_diff_base = self.session.adapter.get_rev_parse(initial_diff_base)
        self.diff_base = initial_diff_base
        self.locked = true
    end
    self.diff_buf = vim.api.nvim_create_buf(false, true)

    self:set_diff_lines(initial_diff_base)
    vim.api.nvim_set_option_value('filetype', self.session.filetype, { buf = self.diff_buf })
    vim.api.nvim_set_option_value('modifiable', false, { buf = self.diff_buf })


    if self.diff_split then
        self.diff_win = self:create_split_win()
    else
        self.diff_win = self:create_dummy_win()
    end

    self:show(self.diff_win, true)
    self:show(self.session.origin_win, true)

    self.session:set_keymaps(self.diff_buf)
end

---@param revision string
function M.Diff:set_diff_lines(revision)
    local lines = self.session.adapter.get_file_at_revision(revision, self.session)
    local locked = self.locked and ' [locked]' or ''
    local diff_name = self.session.path .. ' @ ' .. revision .. ' - TARDIS diff base' .. locked
    vim.api.nvim_buf_set_name(self.diff_buf, diff_name)
    vim.api.nvim_set_option_value('modifiable', true, { buf = self.diff_buf })
    vim.api.nvim_buf_set_lines(self.diff_buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value('modifiable', false, { buf = self.diff_buf })
end

function M.Diff:close()
    if self:has_diff_buf() then
        self:show(self.diff_win, false)
        vim.api.nvim_buf_delete(self.diff_buf, { force = true })
        vim.api.nvim_set_current_win(self.session.origin_win)
    end
end

function M.Diff:toggle_diff()
    if self:has_diff_buf() then
        self:close()
        vim.cmd('diffoff')
    else
        self:create_buffer()
        self:update_diff()
        self.session.info:update_info_buffer()
    end
end

function M.Diff:toggle_split()
    self.diff_split = not self.diff_split
    self:close()
    self:create_buffer()
end

---@param index integer?
function M.Diff:update_diff(index)
    if not self:has_diff_buf() or self.locked then
        return
    end
    index = index or self.session.current_buffer_index + 1
    index = math.min(index, #self.session.buffers)
    local revision = self.session.buffers[index].revision
    self:set_diff_lines(revision)
end

function M.Diff:lock_diff_base()
    local diff_name = vim.api.nvim_buf_get_name(self.diff_buf)
    if self.locked then
        self.diff_base = ''
        self.locked = false
    else
        diff_name = diff_name .. ' [locked]'
        local prev = math.min(self.session.current_buffer_index + 1, #self.session.buffers)
        self.diff_base = self.session.buffers[prev].revision
        self.locked = true
    end
    vim.api.nvim_buf_set_name(self.diff_buf, diff_name)
    self:update_diff()
end

return M

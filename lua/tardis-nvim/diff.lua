local M = {}

---@class TardisDiff
---@field session TardisSession
---@field diff_base string
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

function M.Diff:create_buffer()
    local initial_diff_base = self.session.parent.config.settings.diff_base
    if not initial_diff_base then
        return
    end

    if initial_diff_base == '' then
        initial_diff_base = self.session.buffers[2].revision
        self.diff_base = ''
    else
        initial_diff_base = self.session.adapter.get_rev_parse(initial_diff_base)
        self.diff_base = initial_diff_base
    end
    self.locked = false

    local split_opt = vim.api.nvim_get_option_value('splitright', {})
    vim.api.nvim_set_option_value('splitright', false, {})
    vim.cmd('vsplit')

    self.diff_win = vim.api.nvim_get_current_win()
    self.diff_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(self.diff_win, self.diff_buf)
    vim.api.nvim_set_current_win(self.diff_win)
    self:set_diff_lines(initial_diff_base)
    vim.api.nvim_set_option_value('filetype', self.session.filetype, { buf = self.diff_buf })
    vim.api.nvim_set_option_value('modifiable', false, { buf = self.diff_buf })

    self:show(self.diff_win, true)
    self:show(self.session.origin_win, true)

    vim.api.nvim_set_option_value('splitright', split_opt, {})

    self.session:set_keymaps(self.diff_buf)
end

---@param revision string
function M.Diff:set_diff_lines(revision)
    local lines = self.session.adapter.get_file_at_revision(revision, self.session)
    local diff_name = vim.fn.expand(self.session.path) .. ' @ ' .. revision .. ' - TARDIS diff base'
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

---@param index integer?
function M.Diff:update_diff(index)
    if not self:has_diff_buf() or self.diff_base ~= '' then
        return
    end
    index = index or self.session.current_buffer_index + 1
    index = math.min(index, #self.session.buffers)
    local revision = self.session.buffers[index].revision
    self:set_diff_lines(revision)
end

function M.Diff:lock_diff_base()
    local diff_name = vim.api.nvim_buf_get_name(self.diff_buf)
    if self.diff_base == '' then
        diff_name = diff_name .. ' [locked]'
        local prev = math.min(self.session.current_buffer_index + 1, #self.session.buffers)
        self.diff_base = self.session.buffers[prev].revision
        self.locked = true
    else
        self.diff_base = ''
        self.locked = false
    end
    vim.api.nvim_buf_set_name(self.diff_buf, diff_name)
    self:update_diff()
end

return M

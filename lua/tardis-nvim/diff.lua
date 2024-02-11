local M = {}

---@class TardisDiff
---@field session TardisSession
---@field diff_base string
---@field diff_buf integer
---@field diff_win integer
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

function M.Diff:create_buffer()
    local initial_diff_base = self.session.parent.cmd_opts.diff_base
        or self.session.parent.config.settings.diff_base
    if not initial_diff_base or self.session.parent.cmd_opts.diff_base == false then
        return
    end

    if initial_diff_base == '' then
        initial_diff_base = self.session.buffers[2].revision
        self.diff_base = ''
    else
        initial_diff_base = self.session.adapter.get_rev_parse(initial_diff_base)
        self.diff_base = initial_diff_base
    end

    local split_opt = vim.api.nvim_get_option_value('splitright', {})
    vim.api.nvim_set_option_value('splitright', false, {})
    vim.cmd('vsplit')

    self.diff_win = vim.api.nvim_get_current_win()
    self.diff_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(self.diff_win, self.diff_buf)
    vim.api.nvim_set_current_win(self.diff_win)
    self:set_diff_lines(initial_diff_base)
    vim.api.nvim_set_option_value('filetype', self.session.filetype, { buf = self.diff_buf })
    vim.api.nvim_set_option_value('readonly', true, { buf = self.diff_buf })
    vim.cmd('diffthis')

    vim.api.nvim_set_current_win(self.session.origin_win)
    vim.cmd('diffthis')

    vim.api.nvim_set_option_value('splitright', split_opt, {})
end

---@param revision string
function M.Diff:set_diff_lines(revision)
    local lines = self.session.adapter.get_file_at_revision(revision, self.session)
    local diff_name = vim.fn.expand(self.session.path) .. ' @ ' .. revision .. ' - TARDIS diff base'
    vim.api.nvim_buf_set_name(self.diff_buf, diff_name)
    vim.api.nvim_buf_set_lines(self.diff_buf, 0, -1, false, lines)
end

function M.Diff:close()
    if self:has_diff_buf() then
        vim.api.nvim_set_current_win(self.diff_win)
        vim.cmd('diffoff')
        vim.api.nvim_buf_delete(self.diff_buf, { force = true })
        vim.api.nvim_set_current_win(self.session.origin_win)
    else
        vim.cmd('diffoff')
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

function M.Diff:update_diff(index)
    if not self:has_diff_buf() or self.diff_base ~= '' then
        return
    end
    index = index or self.session.current_buffer_index + 1
    index = math.min(index, #self.session.buffers)
    local revision = self.session.buffers[index].revision
    self:set_diff_lines(revision)
end

return M

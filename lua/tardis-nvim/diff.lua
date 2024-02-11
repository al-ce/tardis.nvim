local M = {}

---@class TardisDiff
---@field session TardisSession
---@field diff_base string
---@field diff_buf integer
M.Diff = {}

---@param session TardisSession
function M.Diff:new(session)
    local diff = {}
    self.__index = self
    self:init(session)
    return setmetatable(diff, self)
end

---@param session TardisSession
function M.Diff:init(session)
    self.session = session
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

    self.diff_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, self.diff_buf)
    self:set_diff_lines(initial_diff_base)
    vim.api.nvim_set_option_value('filetype', self.session.filetype, { buf = self.diff_buf })
    vim.api.nvim_set_option_value('readonly', true, { buf = self.diff_buf })
    vim.cmd('vertical diffsplit')
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
        vim.cmd('windo diffoff')
        vim.api.nvim_set_current_win(self.session.origin_win)
        vim.cmd('e ' .. self.session.path)
        vim.api.nvim_win_set_cursor(0, self.session.origin_pos)
        vim.api.nvim_buf_delete(self.diff_buf, { force = true })
    else
        vim.cmd('diffoff')
    end
end

function M.Diff:has_diff_buf()
    return self.diff_buf and vim.api.nvim_buf_is_valid(self.diff_buf)
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

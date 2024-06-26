local M = {}

---@class TardisBuffer
---@field session TardisSession
---@field fd integer
---@field revision string
M.Buffer = {}

---@param session TardisSession
---@param revision string
---@param fd integer?
---@return TardisBuffer
function M.Buffer:new(session, revision, fd)
    local buffer = {}
    self.__index = self

    buffer.session = session
    buffer.revision = revision
    buffer.fd = fd

    return setmetatable(buffer, self)
end

function M.Buffer:set_lines()
    local origin_win = self.session.origin_win
    local cur_win = vim.api.nvim_get_current_win()
    self.session.diff:show(origin_win, false)
    local current_pos = vim.api.nvim_win_get_cursor(origin_win)
    local target_line_count = vim.api.nvim_buf_line_count(self.fd)
    if current_pos[1] >= target_line_count then
        current_pos[1] = target_line_count
    end
    vim.api.nvim_win_set_buf(origin_win, self.fd)
    vim.api.nvim_win_set_cursor(origin_win, current_pos)
    self.session.diff:show(origin_win, true)
    self.session.info:update_info_buffer()
    vim.api.nvim_set_current_win(cur_win)
end

---@param fd integer
function M.Buffer:open(fd)
    if self.fd then
        self:close(true)
    end
    self.fd = fd
end

---@param force boolean?
function M.Buffer:close(force)
    if not self.fd then
        return
    end
    force = force or true
    vim.api.nvim_buf_delete(self.fd, { force = force })
    self.fd = nil
end

return M

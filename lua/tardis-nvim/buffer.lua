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

---@param session TardisSession
function M.Buffer:focus_pre(session)
    if session:has_diff_buf() then
        vim.cmd('diffoff')
    end
end

---@param session TardisSession
function M.Buffer:focus_post(session)
    if session:has_diff_buf() then
        vim.cmd('diffthis')
    end
end

---@param session TardisSession
function M.Buffer:focus(session)
    self:focus_pre(session)
    local current_pos = vim.api.nvim_win_get_cursor(0)
    local target_line_count = vim.api.nvim_buf_line_count(self.fd)
    if current_pos[1] >= target_line_count then
        current_pos[1] = target_line_count
    end
    vim.api.nvim_win_set_buf(0, self.fd)
    vim.api.nvim_win_set_cursor(0, current_pos)
    self:focus_post(session)
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
    if not self.fd then return end
    force = force or true
    vim.api.nvim_buf_delete(self.fd, { force = force })
    self.fd = nil
end

return M

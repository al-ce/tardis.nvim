local M = {}

---@class TardisInfo
---@field infobuf integer
---@field session TardisSession
M.Info = {}

---@param self TardisInfo
function M.Info:new(session)
    local info = {}
    self.__index = self

    info.session = session
    return setmetatable(info, self)
end

function M.Info:has_info_buf()
    return self.infobuf and vim.api.nvim_buf_is_valid(self.infobuf)
end

function M.Info:toggle_info_buffer()
    if self:has_info_buf() then
        vim.api.nvim_buf_delete(self.infobuf, { force = true })
        self.infobuf = nil
    else
        self:create_info_buffer(self.session:get_current_buffer().revision)
    end
end

---@param revision string
function M.Info:create_info_buffer(revision)
    local message = self.session.adapter.get_revision_info(revision, self.session)
    if not message or #message == 0 then
        vim.notify('revision_message was empty')
        return
    end
    local fd = vim.api.nvim_create_buf(false, true)
    self.infobuf = fd
    vim.api.nvim_buf_set_lines(fd, 0, -1, false, message)
    vim.api.nvim_set_option_value('filetype', 'git', { buf = fd })
    vim.api.nvim_set_option_value('readonly', true, { buf = fd })
    vim.keymap.set('n', 'q', function()
        vim.api.nvim_buf_delete(fd, { force = true })
    end, { buffer = fd })

    vim.api.nvim_open_win(fd, false, {
        relative = 'win',
        anchor = 'NE',
        width = 82,
        height = #message,
        row = 0,
        col = vim.api.nvim_win_get_width(0),
    })
end

function M.Info:update_info_buffer()
    if self:has_info_buf() then
        self:toggle_info_buffer()
        local buf = self.session:get_current_buffer()
        local curr_revision = buf.revision
        self:create_info_buffer(curr_revision)
    end
end

function M.Info:close()
    if self:has_info_buf() then
        vim.api.nvim_buf_delete(self.infobuf, { force = true })
    end
end

return M

local adapters = require('tardis-nvim.adapters')
local buffer = require('tardis-nvim.buffer')
local diff = require('tardis-nvim.diff')

local M = {}

---@class TardisSession
---@field id integer
---@field parent TardisSessionManager
---@field augroup integer
---@field filetype string
---@field path string
---@field origin integer
---@field origin_pos integer[]
---@field origin_win integer
---@field diff TardisDiff
---@field buffers TardisBuffer[]
---@field adapter TardisAdapter
---@field infobuf integer
M.Session = {}

---@param id integer
---@param parent TardisSessionManager
function M.Session:new(id, parent)
    local session = {}
    setmetatable(session, self)
    self.__index = self
    session:init(id, parent)

    return session
end

---@param revision string
function M.Session:create_buffer(revision)
    local fd = vim.api.nvim_create_buf(false, true)
    local file_at_revision = self.adapter.get_file_at_revision(revision, self)
    local filename = self.path .. ' @ ' .. revision .. ' - TARDIS'

    vim.api.nvim_buf_set_name(fd, filename)
    vim.api.nvim_buf_set_lines(fd, 0, -1, false, file_at_revision)
    vim.api.nvim_set_option_value('filetype', self.filetype, { buf = fd })
    vim.api.nvim_set_option_value('readonly', true, { buf = fd })

    local keymap = self.parent.config.keymap
    vim.keymap.set('n', keymap.next, function()
        self:next_buffer()
    end, { buffer = fd })
    vim.keymap.set('n', keymap.prev, function()
        self:prev_buffer()
    end, { buffer = fd })
    vim.keymap.set('n', keymap.quit, function()
        self:close()
    end, { buffer = fd })
    vim.keymap.set('n', keymap.revision_message, function()
        self:toggle_info_buffer()
    end, { buffer = fd })

    return fd
end

function M.Session:has_info_buf()
    return self.infobuf and vim.api.nvim_buf_is_valid(self.infobuf)
end

function M.Session:toggle_info_buffer()
    if self:has_info_buf() then
        vim.api.nvim_buf_delete(self.infobuf, { force = true })
        self.infobuf = nil
    else
        self:create_info_buffer(self:get_current_buffer().revision)
    end
end

---@param revision string
function M.Session:create_info_buffer(revision)
    local message = self.adapter.get_revision_info(revision, self)
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

function M.Session:update_info_buffer()
    if self:has_info_buf() then
        self:toggle_info_buffer()
        local buf = self:get_current_buffer()
        local curr_revision = buf.revision
        self:create_info_buffer(curr_revision)
    end
end

---@param id integer
---@param parent TardisSessionManager
---@param adapter_type string
function M.Session:init(id, parent, adapter_type)
    local adapter = adapters.get_adapter(adapter_type)
    if not adapter then
        return
    end

    self.adapter = adapter
    self.filetype = vim.api.nvim_get_option_value('filetype', { buf = 0 })
    self.origin = vim.api.nvim_get_current_buf()
    self.origin_pos = vim.api.nvim_win_get_cursor(0)
    self.origin_win = vim.api.nvim_get_current_win()
    self.id = id
    self.parent = parent
    self.path = vim.fn.expand('%:p')
    self.buffers = {}

    local log = self.adapter.get_revisions_for_current_file(self)
    if vim.tbl_isempty(log) then
        vim.notify('No previous revisions of this file were found', vim.log.levels.WARN)
        return
    end

    self.diff = diff.Diff:new(self)

    for i, revision in ipairs(log) do
        local fd = nil
        if i < parent.config.settings.initial_revisions then
            fd = self:create_buffer(revision)
        end
        table.insert(self.buffers, buffer.Buffer:new(self, revision, fd))
    end
    parent:on_session_opened(self)
end

function M.Session:close_post()
    if self:has_info_buf() then
        vim.api.nvim_buf_delete(self.infobuf, { force = true })
    end
end

function M.Session:close()
    self.diff:close()
    for _, buf in ipairs(self.buffers) do
        buf:close()
    end
    if self.parent then
        self.parent:on_session_closed(self)
    end
    self:close_post()
end

---@return TardisBuffer
function M.Session:get_current_buffer()
    return self.buffers[self.current_buffer_index]
end

---@param index integer
function M.Session:goto_buffer(index)
    local buf = self.buffers[index]
    if not buf then
        return
    end
    if not buf.fd then
        buf.fd = self:create_buffer(buf.revision)
    end
    buf:focus()
    self.current_buffer_index = index
    self:update_info_buffer()
end

function M.Session:next_buffer()
    self.diff:update_diff()
    self:goto_buffer(self.current_buffer_index + 1)
end

function M.Session:prev_buffer()
    self.diff:update_diff()
    self:goto_buffer(self.current_buffer_index - 1)
end

return M

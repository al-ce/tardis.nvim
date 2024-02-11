local adapters = require('tardis-nvim.adapters')
local buffer = require('tardis-nvim.buffer')
local diff = require('tardis-nvim.diff')
local info = require('tardis-nvim.info')
local tardis_telescope = require('tardis-nvim.telescope')

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
---@field info TardisInfo
M.Session = {}

---@param id integer
---@param parent TardisSessionManager
---@return TardisSession
function M.Session:new(id, parent)
    local session = {}
    setmetatable(session, self)
    self.__index = self
    session:init(id, parent)

    return session
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


    for i, revision in ipairs(log) do
        local fd = nil
        if i < parent.config.settings.initial_revisions then
            fd = self:create_buffer(revision)
        end
        table.insert(self.buffers, buffer.Buffer:new(self, revision, fd))
    end

    self.info = info.Info:new(self)
    if self.parent.config.settings.info.on_launch then
        self.info:create_info_buffer(log[1])
    end

    self.diff = diff.Diff:new(self)

    parent:on_session_opened(self)
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

    self:set_keymaps(fd)
    return fd
end

---@param bufnr integer
function M.Session:set_keymaps(bufnr)
    local telescope_opts = self.parent.config.settings.telescope
    local keymap = self.parent.config.keymap
    -- stylua: ignore
    local kv = {
        [keymap.next] = function() self:next_buffer() end,
        [keymap.prev] = function() self:prev_buffer() end,
        [keymap.quit] = function() self:close() end,
        [keymap.revision_message] = function() self.info:toggle_info_buffer() end,
        [keymap.move_message] = function() self.info:move_info_buffer() end,
        [keymap.telescope] = function() tardis_telescope.git_commits(self, telescope_opts) end,
        [keymap.lock_diff_base] = function()
            if self.diff.diff_base == '' then
                local prev = math.min(self.current_buffer_index + 1, #self.buffers)
                self.diff.diff_base = self.buffers[prev].revision
            else
                self.diff.diff_base = ''
                self.diff:update_diff()
            end
        end,
    }
    for k, v in pairs(kv) do
        vim.keymap.set('n', k, v, { buffer = bufnr })
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
    self.info:close()
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
    self.info:update_info_buffer()
end

function M.Session:next_buffer()
    self:goto_buffer(self.current_buffer_index + 1)
    self.diff:update_diff()
end

function M.Session:prev_buffer()
    self:goto_buffer(self.current_buffer_index - 1)
    self.diff:update_diff()
end

return M

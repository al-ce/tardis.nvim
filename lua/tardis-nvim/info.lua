local M = {}

---@class TardisInfo
---@field infobuf integer
---@field infowin integer
---@field infosplit boolean
---@field session TardisSession
M.Info = {}

---@param session TardisSession
---@return TardisInfo
function M.Info:new(session)
    local info = {}
    self.__index = self

    info.session = session
    return setmetatable(info, self)
end

function M.Info:has_info_buf()
    return self.infobuf and vim.api.nvim_buf_is_valid(self.infobuf)
end

function M.Info:has_info_win()
    return self.infowin and vim.api.nvim_win_is_valid(self.infowin)
end

function M.Info:toggle_info_buffer()
    if self:has_info_buf() then
        vim.api.nvim_buf_delete(self.infobuf, { force = true })
        self.infobuf = nil
        return
    end
    self:create_info_buffer(self.session:get_current_buffer().revision)
    if not self.infosplit then
        return
    end
    local cur_win = vim.api.nvim_get_current_win()
    local cur_pos = vim.api.nvim_win_get_cursor(cur_win)
    if self.session.diff.diff_split and self.session.diff:has_diff_buf() then
        self.session.diff:toggle_split() -- toggle twice to keep info split under both windows
        self.session.diff:toggle_split()
    end
    self.session.diff:update_diff()
    if cur_win ~= self.session.origin_win then
        vim.cmd('wincmd p')
        vim.api.nvim_win_set_cursor(0, cur_pos)
    end
end

function M.Info:create_split_win(opts)
    local global_split_opt = vim.api.nvim_get_option_value('splitbelow', { scope = 'global' })
    vim.api.nvim_set_option_value('splitbelow', true, { scope = 'global' })
    vim.cmd(opts.height .. 'split')
    self.infowin = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(self.infowin, self.infobuf)
    vim.api.nvim_set_current_win(self.session.origin_win)
    vim.api.nvim_set_option_value('splitbelow', global_split_opt, { scope = 'global' })
end

function M.Info:create_float_win(opts)
    local origin_height = vim.api.nvim_win_get_height(self.session.origin_win)
    local origin_width = vim.api.nvim_win_get_width(self.session.origin_win)
    local row = opts.position:match('N') and 0 or origin_height
    local col = opts.position:match('W') and 0 or origin_width
    self.infowin = vim.api.nvim_open_win(self.infobuf, false, {
        relative = 'win',
        anchor = opts.position,
        height = opts.height,
        width = opts.width,
        border = 'single',
        row = row + opts.y_off,
        col = col + opts.x_off,
    })
end

---@param revision string
function M.Info:create_info_buffer(revision)
    local cur_win = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(self.session.origin_win)

    local message = self.session.adapter.get_revision_info(revision, self.session)
    if not message or #message == 0 then
        vim.notify('revision_message was empty')
        return
    end
    local fd = vim.api.nvim_create_buf(false, true)
    self.infobuf = fd
    vim.api.nvim_buf_set_lines(fd, 0, -1, false, message)
    vim.api.nvim_set_option_value('filetype', 'git', { buf = fd })
    vim.api.nvim_set_option_value('modifiable', false, { buf = fd })
    vim.keymap.set('n', 'q', function()
        vim.api.nvim_buf_delete(fd, { force = true })
    end, { buffer = fd })

    local opts = self.session.parent.config.settings.info
    self.infosplit = opts.split
    if self.infosplit then
        self:create_split_win(opts)
    else
        self:create_float_win(opts)
    end
    vim.api.nvim_buf_set_name(fd, 'TARDIS Info')
    vim.api.nvim_set_current_win(cur_win)
end

function M.Info:update_info_buffer()
    if not self:has_info_buf() then
        return
    end
    local buf = self.session:get_current_buffer()
    local curr_revision = buf.revision
    if not self:has_info_win() then
        self:toggle_info_buffer()
        vim.notify('No info window found')
        self:create_info_buffer(curr_revision)
        return
    end
    local message = self.session.adapter.get_revision_info(curr_revision, self.session)
    if not message or #message == 0 then
        vim.notify('revision_message was empty')
        return
    end
    vim.api.nvim_set_option_value('modifiable', true, { buf = self.infobuf })
    vim.api.nvim_buf_set_lines(self.infobuf, 0, -1, false, message)
    vim.api.nvim_set_option_value('modifiable', false, { buf = self.infobuf })
end

function M.Info:move_info_buffer()
    local info_opts = self.session.parent.config.settings.info
    local new_position = info_opts.position == 'NE' and 'SE' or 'NE'
    info_opts.y_off = info_opts.y_off * -1
    info_opts.position = new_position
    if self:has_info_buf() then
        self:toggle_info_buffer()
    end
    self:toggle_info_buffer()
end

function M.Info:close()
    if self:has_info_buf() then
        vim.api.nvim_buf_delete(self.infobuf, { force = true })
        self.infobuf = nil
        self.infowin = nil
    end
end

function M.Info:refresh()
    if not self:has_info_buf() then
        return
    end
    self:close()
    self:toggle_info_buffer()
end

return M

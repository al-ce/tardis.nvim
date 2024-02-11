local ses = require('tardis-nvim.session')
local M = {}

---@class TardisSessionManager
---@field sessions TardisSession[]
---@field config TardisConfig
---@field next integer
---@field cmd_opts table
M.SessionManager = {}

---@param config TardisConfig
function M.SessionManager:init(config)
    self.sessions = {}
    self.config = config
    self.next = 1
end

---@param config TardisConfig
---@return TardisSessionManager
function M.SessionManager:new(config)
    local session_manager = {}
    self.__index = self
    setmetatable(session_manager, self)
    session_manager:init(config)
    return session_manager
end

---@param opts table
function M.SessionManager:create_session(opts)
    self.cmd_opts = opts or {}
    local session = ses.Session:new(self.next, self)
    self.next = self.next + 1
    session:goto_buffer(1)
end

---@param session TardisSession
function M.SessionManager:on_session_opened(session)
    table.insert(self.sessions, session.id, session)
end

---@param session TardisSession
function M.SessionManager:on_session_closed(session)
    table.remove(self.sessions, session.id)
end

return M

local M = {}

---@class TardisSettings
---@field max_revisions integer
---@field initial_revisions integer
---@field diff_base string
---@field diff_split boolean
---@field info table
---@field telescope table
---@field keyhints table

---@class TardisKeymap
---@field next string
---@field prev string
---@field quit string
---@field revision_message string
---@field move_message string
---@field lock_diff_base string
---@field toggle_diff string
---@field toggle_split string
---@field telescope string
---@field keyhints string

---@class TardisConfig
---@field keymap TardisKeymap
---@field settings TardisSettings
--
---@class TardisPartialConfig
---@field keymap? TardisKeymap
---@field settings? TardisSettings

---@return TardisConfig
local function get_default_config()
    return {
        keymap = {
            next = '<C-j>',
            prev = '<C-k>',
            quit = 'q',
            revision_message = '<C-m>',
            move_message = '<C-a>',
            lock_diff_base = '<C-l>',
            toggle_diff = '<C-i>',
            toggle_split = '<C-s>',
            telescope = '<C-t>',
            keyhints = '<C-/>',
        },
        settings = {
            max_revisions = 256,
            initial_revisions = 10,
            diff_split = false,
            diff_base = '',
            info = {
                on_launch = true,
                split = true,
                height = 6,
                width = 82,
                position = 'SE',
                x_off = 0,
                y_off = -1,
            },
            telescope = {
                delta = true,
            },
            keyhints = {
                on_launch = true,
            },
        },
        debug = false,
    }
end

M.Config = {}

---@param user_config TardisPartialConfig?
---@return TardisConfig
function M.Config:new(user_config)
    user_config = user_config or {}
    local default_config = get_default_config()
    local config = vim.tbl_deep_extend('force', default_config, user_config)
    setmetatable(user_config, self)
    self.__index = self
    return config
end

return M

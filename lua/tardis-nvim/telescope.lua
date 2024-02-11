local M = {}

local actions = require('telescope.actions')
local actions_state = require('telescope.actions.state')
local builtin = require('telescope.builtin')
local previewers = require('telescope.previewers')

---@param path string
---@return function
local function delta(path)
    return previewers.new_termopen_previewer({
        get_command = function(entry)
            return {
                'git',
                '-c',
                'core.pager=delta',
                '-c',
                'delta.side-by-side=false',
                'diff',
                entry.value .. '^!',
                '--',
                path,
            }
        end,
    })
end

---@return boolean
local function has_delta()
    local ok, _ = pcall(function()
        return vim.fn.executable('delta')
    end)
    return ok
end

---@param session TardisSession
M.git_commits = function(session, opts)
    local telescope_ok, _ = pcall(require, 'telescope')

    if not telescope_ok then
        vim.notify('telescope.nvim not found', vim.log.levels.ERROR, { title = 'Tardis' })
        return
    end

    opts = opts or {}
    opts.current_file = session.path
    opts.bufnr = session.origin
    if opts.delta and has_delta() then
        opts.previewer = delta(session.path)
    end

    opts.attach_mappings = function(_, map)
        map({ 'i', 'n' }, '<CR>', function(prompt_bufnr)
            local selection = actions_state.get_selected_entry()
            actions.close(prompt_bufnr)
            session:goto_buffer(selection.index)
            session.diff:update_diff()
        end, { desc = 'Tardis: set revision' })

        map('i', session.parent.config.keymap.telescope, function(prompt_bufnr)
            actions.close(prompt_bufnr)
        end, { desc = 'Tardis: close Telescope' })

        -- Set selected entry as diff base and lock it in place
        if session.diff:has_diff_buf() then
            map({ 'i', 'n' }, '<C-CR>', function(prompt_bufnr)
                local selection = actions_state.get_selected_entry()
                actions.close(prompt_bufnr)
                session.diff:update_diff(selection.index)
                session.diff.diff_base = selection.value
            end, { desc = 'Tardis: set diff' })
        end
        return true
    end
    builtin.git_bcommits(opts)
end

return M

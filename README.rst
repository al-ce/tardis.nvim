.. image:: ./assets/tardis.webp

Tardis allows you to travel in time (git history) scrolling through each
revision of your current file.

Inspired by
`git-timemachine <https://github.com/emacsmirror/git-timemachine>`__
which I used extensively when I was using emacs.

Installation
============

Like with any other

.. code:: lua

   {
       'fredeeb/tardis.nvim',
       dependencies = { 'nvim-lua/plenary.nvim' },
       config = true,
   }

The default options are

.. code:: lua

    require('tardis-nvim').setup {
        keymap = {
            ["next"] = '<C-j>',         -- next entry in log (older)
            ["prev"] = '<C-k>',         -- previous entry in log (newer)
            ["quit"] = 'q',             -- quit all
            ["revision_message"] = '<C-m>', -- show revision message for current revision
            ["move_message"] = '<C-a>', -- move the revision info window to SE or NE
            ['lock_diff_base'] = '<C-l>', -- lock/unlock the diff base to current
            ['telescope'] = '<C-t>',    -- open telescope picker to go to revision
        },
        initial_revisions = 10,         -- initial revisions to create buffers for
        max_revisions = 256,            -- max number of revisions to load

        -- Set to "" to show diff against previously viewed revision
        -- Set to e.g. "HEAD" to always diff against that revision
        diff_base = nil,

        info = {
            position = 'NE',            -- position of info relative to window
            x_off = 2,                  -- offset of row
            y_off = 2,                  -- offset or column
            split = false,              -- open info in a split instead of float
        },

        -- any opts valid for telescope.builtin.git_bcommits
        telescope = {
            delta = true,               -- use delta as the preview pager
        }
    }

Usage
=====

Using tardis is pretty simple

::

   :Tardis

This puts you into a new buffer where you can use the keymaps, like
described above, to navigate the revisions of the currently open file

Override your configuration's diff base with the `diff_base` option in a
`tardis.tardis` call.

.. code:: lua
   require('tardis-nvim').tardis {
       diff_base = "HEAD~2"  -- e.g. would override `""` in the setup
   }

Telescope Integration
---------------------

`keymap.telescope` opens a telescope picker that shows the revisions of the
current file plus a preview of the diff. Make giant leaps through history!

The following mappings (along with your defaults) are available in the
telescope picker:

- `<CR>` changes the current revision to the selection and sets its diff base to
the previous commit.

- `<C-CR>` changes the diff base to the selection and locks it, without changing
the current revision to diff against. The diff base is 'locked', so cycling
through revisions with `keymap.next` and `keymap.prev` will always diff against
the locked base. Unlock with `keymap.lock_diff_base`.

- `keymap.telescope` closes the picker

Known issues
============

See |issues|

Contributing
============

Go ahead :)

.. |issues| image:: https://github.com/FredeEB/tardis.nvim/issues

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
        },
        initial_revisions = 10,         -- initial revisions to create buffers for
        max_revisions = 256,            -- max number of revisions to load
        -- Set to "" to show diff against previous revision while scrolling
        -- Set to e.g. "HEAD" to keep diffing against that revision
        diff_base = nil,
    }

Usage
=====

Using tardis is pretty simple

::

   :Tardis

This puts you into a new buffer where you can use the keymaps, like
described above, to navigate the revisions of the currently open file

Known issues
============

See |issues|

Contributing
============

Go ahead :)

.. |issues| image:: https://github.com/FredeEB/tardis.nvim/issues

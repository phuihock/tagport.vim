Requirement
===========

Exuberant Ctags (ctags)
    Generate tags file with ``--extra=f`` to enable import by module. I have the following in my ``.vimrc`` to keep my tags file updated.::

        autocmd! BufWritePost *.py  call UpdateTagsFile()
        noremap <F12>   :call RenewTagsFile()<Enter>

        function! UpdateTagsFile()
            exe 'silent !sed -i "\:expand(%):d" tags'
            exe 'silent !ctags -a -f tags --extra=f % 2>/dev/null'
            exe 'redraw!'
        endfunction

        function! RenewTagsFile()
            exe 'silent !rm tags'
            exe 'silent !ctags --recurse=yes -f tags --extra=f ' . getcwd() . ' 2>/dev/null'
            exe 'redraw!'
        endfunction

        " http://sontek.net/turning-vim-into-a-modern-python-ide#virtualenv
        python << EOF
        import os, sys, vim
        if 'VIRTUAL_ENV' in os.environ:
            ve_basedir = os.environ['VIRTUAL_ENV']
            sys.path.insert(0, ve_basedir)
            activate_this = os.path.join(ve_basedir, 'bin/activate_this.py')
            execfile(activate_this, dict(__file__=activate_this))
        EOF
   

Installation
============

1. Place this script in $HOME/.vim/ftplugin/python.


Usage
=====

1. Move cursor to a word you'd like to import.

#. Type ``<Leader>fi``

#. You'll be prompted with a list of import statements to yank into unnamed register ``'"'``.

#. Type a number.

#. Put the import statement anywhere you like with ``p``.  *Tip: quickly jump back to last cursor position with `` (double backticks)*


Options
=======
let g:tagport_aliases = {}
    There are times when importing from a different package is preferred as apposed to the actual Python module the class is defined. 
    For example, Django's ``Model`` is declared in ``django.db.models.base``. However, it is a common practice that ``Model`` 
    is imported from ``django.db.models`` instead.

    To do that, declare the following in ``.vimrc``::

        let g:tagport_aliases = {'django.db.models.base': 'django.db.models'}

    The next time you search for ``Model``, ``from django.db.models import Model`` is listed instead.


let g:tagport_ignore = []
    ``models`` can be found in many places, but not all are useful. You can hide any entry with ``g:tagport_ignore``.
    For example, if you want to hide all ``models`` from ``migrations`` directory, declare the following in ``.vimrc``::
        
        let g:tagport_ignore = ['.*migrations.*']

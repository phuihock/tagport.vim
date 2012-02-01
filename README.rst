Requirement
===========

Exuberant Ctags (ctags)
    Generate tags file with ``--extra=f`` to enable import by module. I have the following in my ``.vimrc`` to keep my tags file updated.::

        autocmd! BufWritePost *.py  call UpdateTagsFile()
        noremap <F12>   :call RenewTagsFile()<Enter>

        function! UpdateTagsFile()
            exe 'silent !sed -i "\:%:d" tags'
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

#. Put the import statement anywhere you like with ``p``.  *Tip: quickly jump back to last cursor position with '' (double single-quote)*

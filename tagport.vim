" tagport.vim - A script to find the Python module using the keyword under the cursor and
" yank the import statement into the unnamed register "".
"
" Requirement: Exuberant Ctags (ctags)
" Maintainer: Chang Phui-Hock <phuihock@gmail.com>
" Version: 0.1
" License:  This file is placed in the public domain.
"
" Place this script in $HOME/.vim/ftplugin/python.

if exists("g:loaded_tagport")
    finish
endif
let g:loaded_tagport = 1

function! s:StripDir(path)
python << EOF
from vim import *
import sys

apath = eval("a:path")
paths = sys.path
paths.sort(lambda a, b: cmp(len(b), len(a)))
for p in paths:
    if apath.startswith(p):
        apath = apath[len(p):].lstrip('/')
        break
command('return "%s"' % apath)
EOF
endfunction

function! s:AsPythonImport(path, expr)
    let path = s:StripDir(a:path)
    let path = substitute(path, '\(.*\).py$', '\1', "")
    let path = substitute(path, '/', '.', "g")
    if len(path) > 0
        return "from " . path . " import " . a:expr
    else
        return "import " . a:expr
endfunction

function! s:FindSource(expr)
    let sources = []

    " we are only interested in classes, modules and search paths
    let tags = taglist('\(^__init__\.py$\|^' . a:expr . '$\|^' . a:expr . '\.py$\)')
    for t in tags
        let filename = t['filename']
        if index(sources, filename) == -1
            let kind = toupper(t['kind'])
            if kind == 'F'
                if t['name'] == '__init__.py'
                    " this is a search path, eg. /a/b/c/__init__.py
                    let matches = matchlist(filename, '^\(/.*\)/' . a:expr . '/__init__.py$')
                    if len(matches) > 1
                        let source = matches[1]
                    else
                        continue
                    endif
                else
                    " this is a module, eg. /a/b/c.py
                    let source = matchlist(filename, '^\(/.*\)/' . a:expr . '.py$')[1]
                endif
            elseif kind == 'C'
                " this is a class, eg. class C(..)
                let source = filename
            else
                continue
            endif

            call add(sources, source)
        endif
    endfor 

    if len(sources) > 0
        let imports = []
        for s in sources
            let import = s:AsPythonImport(s, a:expr)
            if index(imports, import) == -1
                call add(imports, import)
            endif
        endfor
        call sort(imports)

        echo "  #" . "\tsource"
        for i in range(len(imports))
            echo "  " . (i + 1) . "\t" . imports[i]
        endfor

        let j = input("Type number and <Enter> to yank (empty cancels): ")
        
        "yank to unnamed register, linewise
        call setreg('"', imports[str2nr(j - 1)], "l")
    else
        echo "No match found"
    endif
endfunction 

function! s:FindByCWord()
    return s:FindSource(expand("<cword>"))
endfunction

noremap <Leader>fi  :call <SID>FindByCWord()<Enter>

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
if os.path.isfile(apath):
    mpath = os.path.dirname(apath)
else:
    mpath = apath

spath = ''

paths = sys.path[:]
paths.sort(lambda a, b: cmp(len(b), len(a)))
for p in paths:
    if mpath.startswith(p):
        subdirs = mpath[len(p):].lstrip('/')
        q = p


        # test if the path is importable
        is_valid = True
        for s in subdirs.split('/'):
            q = os.path.join(q, s)
            t = os.path.join(q, '__init__.py') 
            if not os.path.exists(t):
                is_valid = False 
                break

        if is_valid:
            spath = subdirs
            break

command('return "%s"' % spath)
EOF
endfunction

function! s:AsPythonImport(path, expr)
    let path = s:StripDir(a:path)
    if len(path) > 0
        let path = substitute(path, '/', '.', "g")

        if exists('g:tagport_aliases')
            if has_key(g:tagport_aliases, path)
                let path = g:tagport_aliases[path]
            endif
        endif

        if len(path) > 0
            let stmt = "from " . path . " import " . a:expr
        else
            let stmt = "import " . a:expr
        endif
        return [stmt, path, a:path, a:expr]
    endif
    return []
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
                    let matches = matchlist(filename, '^\(.*\)/' . a:expr . '/__init__.py$')
                else
                    " this is a module, eg. /a/b/c.py
                    let matches = matchlist(filename, '^\(.*\)/' . a:expr . '.py$')
                endif

                if len(matches) > 1
                    let source = matches[1]
                else
                    continue
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
            if len(import) > 0
                if index(imports, import[0]) == -1
                    let use_import = 1
                    if exists('g:tagport_ignore')
                        for ignore in g:tagport_ignore
                            if match(import[1], ignore) > -1
                                let use_import = 0
                                break
                            endif
                        endfor
                    endif

                    if use_import
                        call add(imports, import[0])
                    endif
                endif
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

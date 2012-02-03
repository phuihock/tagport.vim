" tagport.vim - A script to find the Python module using the keyword under the cursor and
" yank the import statement into the unnamed register "".
"
" Requirement: Exuberant Ctags (ctags)
" Maintainer: Chang Phui-Hock <phuihock@gmail.com>
" Version: 0.2
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
spath = ''
is_package = False

paths = sys.path[:]
paths.sort(lambda a, b: cmp(len(b), len(a)))

for p in paths:
    if apath.startswith(p):
        spath = apath[len(p):].lstrip('/')
        if spath:
            # do a shallow check of the path if indeed a package
            root = spath.split('/')[0]
            if os.path.exists(os.path.join(p, root, '__init__.py')):
                is_package = True
                break
            else:
                spath = ''
        else:
            is_package = True
            break
command('return ["%s", %i]' %(spath, is_package)) 
EOF
endfunction

function! s:GetRealPath(path)
python << EOF
from vim import *
import os

apath = eval("a:path")
rpath = os.path.realpath(apath)
command('return "%s"' % rpath)
EOF
endfunction

function! s:AsPythonImport(path, cword)
    let stripped_dir = s:StripDir(a:path)
    if len(stripped_dir[0]) > 0 || stripped_dir[1]
        let path = substitute(stripped_dir[0], '/', '.', "g")

        if exists('g:tagport_aliases')
            if has_key(g:tagport_aliases, path)
                let path = g:tagport_aliases[path]
            endif
        endif

        if len(path) > 0
            let stmt = "from " . path . " import " . a:cword
        else
            let stmt = "import " . a:cword
        endif

        if len(stmt) > 0
            return [stmt, path, a:path, a:cword]
        endif
    endif

    return []
endfunction

function! s:FindSource(cword)
    let ignorecase = &ignorecase
    set noignorecase

    let sources = []
    let imports = []

    " we are only interested in classes, modules and packages
    let tags = taglist('\(^__init__\.py$\|^' . a:cword . '$\|^' . a:cword . '\.py$\)')
    for t in tags
        let filename = s:GetRealPath(t['filename'])
        if index(sources, filename) == -1
            let kind = toupper(t['kind'])
            if kind == 'F'
                if t['name'] == '__init__.py'
                    " this is a package, eg. /a/b/c/__init__.py
                    let matches = matchlist(filename, '^\(.*\)/' . a:cword . '/__init__.py$')
                else
                    " this is a module, eg /a/b/c.py
                    let matches = matchlist(filename, '^\(.*\)/' . a:cword . '.py$')
                endif
            elseif kind == 'C' || kind == 'V'
                if match(filename, '__init__.py$') != -1
                    " this is a package, eg. /a/b/d/__init__.py
                    let matches = matchlist(filename, '^\(.*\)/__init__.py$')
                else
                    " this is a a class, eg class C(..)
                    let matches = matchlist(filename, '^\(.*\).py$')
                endif
            else
                continue
            endif

            if len(matches) > 0
                let import = s:AsPythonImport(matches[1], a:cword)
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

                call add(sources, filename)
            endif
        endif
    endfor 

    if len(imports) > 0
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

    let &ignorecase=ignorecase
endfunction 

function! s:FindByCWord()
    return s:FindSource(expand("<cword>"))
endfunction

noremap <Leader>fi  :call <SID>FindByCWord()<Enter>

" tagport.vim - A script to find the Python module using the keyword under the cursor and
" yank the import statement into the unnamed register "".
"
" Requirement: Exuberant Ctags (ctags)
" Maintainer: Chang Phui-Hock <phuihock@gmail.com>
" Version: 0.1
" License:  This file is placed in the public domain.
"
" Place this script in $HOME/.vim/ftplugin/python.

function s:StripDir(path)
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

function s:AsPythonImport(path, expr)
    let path = s:StripDir(a:path)
    let path = substitute(path, '\(.*\).py$', '\1', "")
    let path = substitute(path, '/', '.', "g")
    if len(path) > 0
        return "from " . path . " import " . a:expr
    else
        return "import " . a:expr
endfunction

function s:FindSource(expr)
    let sources = []
    let tags = taglist("^" . a:expr)
    for t in tags
        let filename = t['filename']
        if index(sources, filename) == -1
            if t['kind'] == 'F'
                let source = strpart(filename, 0, match(filename, "/" . a:expr . ".py"))
            else
                let source = filename
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

function s:FindByCWord()
    return s:FindSource(expand("<cword>"))
endfunction

noremap <Leader>fi  :call <SID>FindByCWord()<Enter>

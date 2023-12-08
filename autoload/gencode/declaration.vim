"==============================================================
"    file: declaration.vim
"   brief: 
" VIM Version: 7.4
"  author: tenfyzhong
"   email: tenfy@tenfy.cn
" created: 2016-06-06 15:03:16
"==============================================================
function! s:SearchFunction(content, line)
    let l:content = substitute(a:content, ';', '', 'g')
    let l:content = escape(l:content, '.*~\')
    let l:content = substitute(l:content, '\(\\\*\)', '\\_\\s*\1\\_\\s*', 'g')
    let l:content = substitute(l:content, ' ', '\\_\\s*', 'g')
    let l:content = substitute(l:content, '\([,()<>:&]\)', '\\_\\s*\1\\_\\s*', 'g')
    let l:searchResult = search(l:content, 'bn', a:line)
    return l:searchResult
endfunction

function! s:GetInsertSpace(spaceName) "{{{
    let l:spaceList = split(a:spaceName, '::')

    let l:break = 0
    for space in l:spaceList
        let l:spaceNameLine = search('\%(class\|namespace\)\_\s\+' . space, 'b')
        if l:spaceNameLine == 0
            let l:break = 1
        endif
    endfor

    if l:break != 0
        let l:fileExtend = expand('%:e')
        if l:fileExtend ==? 'h'
            " if already in header file, return 
            return l:spaceNameLine
        endif

        " in source file
        try
            exec ':A'
        catch
        endtry

        for space in l:spaceList
            let l:spaceNameLine = search('\%(class\|namespace\)\_\s\+' . space, 'b')
            if l:spaceNameLine == 0
                let l:break = 1
            endif
        endfor
    endif

    return l:spaceNameLine
endfunction "}}}

function! gencode#declaration#Generate() "{{{
    let l:curline = line('.')
    let l:functionLeftBraces = search('{', 'n')
    if l:functionLeftBraces == 0
        let l:functionLeftBraces = l:curline
    endif

    let l:functionDeclareList = getline(l:curline, l:functionLeftBraces)

    let l:matched = match(l:functionDeclareList, '\w\+\_\s*(')
    if l:matched == -1
        normal [(b
        let l:curline = line('.')
        let l:functionLeftBraces = search('{', 'n')
        if l:functionLeftBraces == 0
            let l:functionLeftBraces = l:curline
        endif

        let l:functionDeclareList = getline(l:curline, l:functionLeftBraces)

        let l:matched = match(l:functionDeclareList, '\w\+\_\s*(')
        if l:matched == -1
            echom 'definition not found'
            return
        endif
    endif

    let l:functionDeclare = join(l:functionDeclareList, ' ')
    let l:functionDeclare = substitute(l:functionDeclare, '\s\s\+', ' ', 'g')
    let l:functionDeclare = substitute(l:functionDeclare, '\s*\([(;]\)\s*', '\1', 'g')
    let l:functionDeclare = substitute(l:functionDeclare, '\s*\()\)', '\1', 'g')
    let l:functionDeclare = substitute(l:functionDeclare, '\(\w\+\)\s*\(\*\|&\+\)\s*\(\w\+\)', '\1\2 \3', '')  " format to: int* func(...);
    let l:functionMatchList = matchlist(l:functionDeclare, '^\s*\(\%(\%(\w[a-zA-Z0-9_:*&<>]*\)\s\)\+\)\(\%(\w[a-zA-Z0-9_]*::\)*\)\(\S\+\s*(.*)\s*\%(const\)\?\)') " \1 match return type, \2 match class name, \3 match function name and argument
    try
        let [l:matchall, l:returnType, l:spaceName, l:functionName; l:rest] = l:functionMatchList
    catch
        return
    endtry

    let l:spaceNameLine = <SID>GetInsertSpace(l:spaceName)
    if l:spaceNameLine == 0
        return
    endif

    call search('{')

    " jump to '}' of the class
    normal ]}
    let l:appendLine = line('.') - 1

    let l:appendContent = l:returnType . l:functionName 
    let l:appendContent = substitute(l:appendContent, '\s*$', '', '')
    let l:appendContent = l:appendContent . ';'

    "let l:findLine = search('\V'.l:appendContent, 'bn', l:spaceNameLine)
    let l:findLine = <SID>SearchFunction(l:appendContent, l:spaceNameLine)
    if l:findLine > 0
        call cursor(l:findLine, 0)
        echom l:appendContent . ' existed'
        return
    endif

    call append(l:appendLine, gencode#ConstructIndentLine(l:appendContent))
    call cursor(l:findLine - 1, 0)
endfunction "}}}

"==============================================================
"    file: definition.vim
"   brief: 
" VIM Version: 7.4
"  author: tenfyzhong
"   email: tenfy@tenfy.cn
" created: 2016-06-06 14:57:03
"==============================================================

function! s:ConstructReturnContent(returnContent) "{{{
    let l:returnContent = 'return ' . a:returnContent . ';'
    return gencode#ConstructIndentLine(l:returnContent)
endfunction "}}}

function! s:GetDeclaration(line) "{{{
    let l:pos = getpos('.')
    call cursor(a:line, 0)
    let l:functionBeginLine   = a:line
    let l:functionEndLine     = search(';\|{', 'n')
    call setpos('.', l:pos)
    if l:functionEndLine == 0
        let l:functionEndLine = l:functionBeginLine
    endif
    let l:functionList = getline(l:functionBeginLine, l:functionEndLine)
    let l:function     = join(l:functionList, " ")

    let l:matched = match(l:function, '\w\+\_\s*(')
    if l:matched == -1
        return ""
    endif

    return l:function
endfunction "}}}

function! s:GetDeclarationForward() "{{{
    let l:pos = getpos('.')
    normal [(b
    let l:line = line('.')
    call cursor(l:line, 0)
    let l:functionBeginLine   = l:line
    let l:functionEndLine     = search(';\|{', 'n')
    call setpos('.', l:pos)
    if l:functionEndLine == 0
        let l:functionEndLine = l:functionBeginLine
    endif
    let l:functionList = getline(l:functionBeginLine, l:functionEndLine)
    let l:function     = join(l:functionList, " ")

    let l:matched = match(l:function, '\w\+\_\s*(')
    if l:matched == -1
        return ""
    endif

    return l:function
endfunction "}}}

function! s:IsInlineDeclaration(declaration) "{{{
    return match(a:declaration, 'inline') != -1
endfunction "}}}

function! s:FormatDeclaration(declaration) "{{{
    let l:lineContent = a:declaration

    " remove virtual, static, explicit key word
    let l:lineContent = substitute(l:lineContent, '\%(virtual\|static\|explicit\|inline\|public\s*:\|private\s*:\|protected\s*:\)\s\+', '', 'g')

    " remove trailing specifiers that will not appear in the definition
    let l:lineContent = substitute(l:lineContent, '\s*\%(override\|final\|OVERRIDE\|FINAL\)\s*', '', 'g')

    let l:lineContent = substitute(l:lineContent, '^\s\+', '', '') " delete header space
    let l:lineContent = substitute(l:lineContent, '\(\w\+\)\s*\(\%(\*\|&\)\+\)\s*\(\S\+(\)', '\1\2 \3', '')  " format to: int* func(...);
    let l:lineContent = substitute(l:lineContent, '\s\s\+', ' ', 'g') " delete more space
    let l:lineContent = substitute(l:lineContent, '\s\+(', '(', '')
    let l:lineContent = substitute(l:lineContent, '(\s\+', '(', '')
    let l:lineContent = substitute(l:lineContent, '\s\+)', ')', '')
    return l:lineContent
endfunction "}}}

function! s:GetClassName(line) "{{{
    let l:cword = expand('<cword>')
    if l:cword !~ '{'
        return ''
    endif
    "let l:classBeginLine = search('\%(\<class\>\|\<struct\>\)\_\s\+\w\+\_\s\+\%(:\%(\_\s*\w\+\)\{1,2}\)\?\_\s*{', 'b')
    let l:classBeginLine = search('\%(\<class\>\|\<struct\>\)\_\s\+\w\+\>\_.*{', 'b')
    if l:classBeginLine == 0
        return ''
    endif
    let l:braceLine = search('{')
    if l:braceLine != a:line
        return ''
    endif
    let l:lineContent = getline(l:classBeginLine, a:line)
    let l:classDeclaration = join(l:lineContent, ' ')

    let l:className = matchlist(l:classDeclaration, '\(\<class\>\|\<struct\>\)\s\+\(\w[a-zA-Z0-9_]*\)')[2]
    return l:className
endfunction "}}}

function! s:GetParentClassName(className) "{{{
    let l:oldPosition = getpos('.')
    normal [{
    let l:classBraceLine = line('.')
    let l:className     = <SID>GetClassName(l:classBraceLine)
    if empty(l:className) || l:className == a:className
      call setpos('.', l:oldPosition)
      return ''
    endif
    let l:pClassName = <SID>GetParentClassName(l:className)
    if empty(l:pClassName) 
      return l:className
    endif
    return l:pClassName . '::' . l:className
endfunction "}}}

function! s:GetTemplate(line, className) "{{{
    if empty(a:className)
        return []
    endif

    call cursor(a:line, 0)
    let l:searchTemplate = search('template\_\s*<\%(\%(typename\|class\)\_\s\+\w\+\_\s*\%(\_\s*=\_\s*\S\+\)\?\_\s*,\?\_\s*\)\+>\_\s*\%(class\|struct\)\_\s*\<' . a:className . '\>', 'b')
    if l:searchTemplate == 0
        return []
    endif

    let l:templateContentList = getline(l:searchTemplate, a:line)
    let l:templateContent = join(l:templateContentList, ' ')
    let l:typeStr = substitute(l:templateContent, '.*<\(.*\)>.*', '\1', '')

    let l:typeProtoList = split(l:typeStr, ',')
    let l:typeList = []
    for type in l:typeProtoList
        let l:match = matchlist(type, '\s*\%(typename\|class\)\s*\(\w\+\)\s*\%(=\s*\w\+\)\?')
        call add(l:typeList, l:match[1])
    endfor

    return l:typeList
endfunction "}}}

function! s:GetFunctionTemplate(line, funcName) "{{{
    if empty(a:funcName)
        return 0
    endif

    call cursor(a:line, 0)
    let l:searchTemplate = search('template\_\s*<\%(\%(typename\|class\)\_\s\+\w\+\_\s*\%(\_\s*=\_\s*\S\+\)\?\_\s*,\?\_\s*\)\+>\s*\_s\?.*\<' . a:funcName . '\>', 'b')
    return searchTemplate
endfunction "}}}

function! s:GetNamespaceList(line) "{{{
    call cursor(a:line, 0)
    normal [{
    let l:braceLine = line('.')
    if l:braceLine == a:line
        return []
    endif

    let l:classBeginLine = search('namespace\_\s\+\w\+\_\s*{', 'b')
    let l:searchBraceLine = search('{')

    if l:braceLine != l:searchBraceLine
        return []
    else
        let l:namespaceContentList = getline(l:classBeginLine, l:searchBraceLine)
        let l:namespaceContent = join(l:namespaceContentList, ' ')
        let l:namespaceName = matchlist(l:namespaceContent, 'namespace\%(\_\s\+\(\w\+\)\)\?\_\s*{')[1]
        return add(<SID>GetNamespaceList(l:braceLine), l:namespaceName)
    endif
endfunction "}}}

function! s:SearchFunction(content, line)
    let l:content = escape(a:content, '.*~\')
    let l:content = substitute(l:content, '\(\\\*\)', '\\_\\s*\1\\_\\s*', 'g')
    let l:content = substitute(l:content, ' ', '\\_\\s*', 'g')
    let l:content = substitute(l:content, '\([,()<>:&]\)', '\\_\\s*\1\\_\\s*', 'g')
    let l:searchResult = search(l:content, '', a:line)
    return l:searchResult
endfunction

function! gencode#definition#Generate() "{{{
    let l:oldPosition = getpos('.')
    let l:line        = line('.')
    let l:declareationFileName = expand('%')
    let l:declaration = <SID>GetDeclaration(l:line)

    if empty(l:declaration)
        let l:declaration = <SID>GetDeclarationForward()
        if empty(l:declaration)
          echom "declaration not found"
        endif
    endif

    if match(l:declaration, '{') != -1
        echom "has defined"
        return
    endif

    let l:isInline    = <SID>IsInlineDeclaration(l:declaration)

    " if header file, change to source file
    let l:fileExtend = expand('%:e')
    let l:needChangeFile = !l:isInline && l:fileExtend ==? 'h'

    let l:formatedDeclaration  = <SID>FormatDeclaration(l:declaration)
    let l:declarationDecompose = matchlist(l:formatedDeclaration, '\(\%(\%(\w[a-zA-Z0-9_:*&<>, /]*\)\s\)*\)\(\~\?\(\w[a-zA-Z0-9_]*\)\s*\((\?.*)\)\?\s*\%(const\)\?\)\s*\%(=\s*\w\+\)\?\s*;') " match function declare, \1 match return type, \2 match function name and argument, \3 match argument
    try
        let [l:matchall, l:returnType, l:functionBody, l:functionName, l:argument, l:assign; l:rest] = l:declarationDecompose
        let l:functionBody = substitute(l:functionBody, '\_\s*=[^,)]\+\([,)]\)\?', '\1', 'g')
    catch
        return
    endtry

    if empty(l:argument) && match(l:declaration, 'static') == -1
        echom "no need to define"
        return
    endif

    if empty(l:argument) && !empty(l:assign)
        echom "no need to define"
        return
    endif

    let l:templatePos = <SID>GetFunctionTemplate(l:line, l:functionName)
    if l:templatePos != 0
        let l:needChangeFile = 0
        call cursor(l:templatePos, 0)
        let l:line        = line('.')
        let l:declareationFileName = expand('%')
        let l:declaration = <SID>GetDeclaration(l:line)

        let l:formatedDeclaration  = <SID>FormatDeclaration(l:declaration)
        let l:declarationDecompose = matchlist(l:formatedDeclaration, '\(\%(\%(\w[a-zA-Z0-9_:*&<>,]*\)\s\)*\)\(\~\?\w[a-zA-Z0-9_]*\s*\((\?.*)\)\?\s*\%(const\)\?\)\s*\%(=\s*\w\+\)\?\s*;') " match function declare, \1 match return type, \2 match function name and argument, \3 match argument
        try
            let [l:matchall, l:returnType, l:functionBody, l:argument, l:assign; l:rest] = l:declarationDecompose
            let l:functionBody = substitute(l:functionBody, '\_\s*=[^,)]\+\([,)]\)\?', '\1', 'g')
        catch
            return
        endtry
    endif

    " jump to previous unmatch {
    normal [{
    let l:classBraceLine = line('.')
    let l:className     = <SID>GetClassName(l:classBraceLine)
    let l:templateTypeList   = <SID>GetTemplate(l:classBraceLine, l:className)
    let l:parentClassName     = <SID>GetParentClassName(l:className)

    let l:templateTypeBody = ''
    if !empty(l:className) && !empty(l:templateTypeList)
        let l:needChangeFile = 0

        let l:templateTypeBody = '<' . l:templateTypeList[0]
        let l:i = 1
        while l:i < len(l:templateTypeList)
            let l:templateTypeBody = l:templateTypeBody . ', ' . l:templateTypeList[l:i]
            let l:i = l:i + 1
        endwhile
        let l:templateTypeBody = l:templateTypeBody . '>'
        let l:className = l:className . l:templateTypeBody
    endif

    "let l:getNamespaceLine = empty(l:className) ? l:line : l:classBraceLine
    let l:getNamespaceLine = l:line
    if !empty(l:className) 
      if !empty(l:parentClassName)
        let l:getNamespaceLine = line('.')
      else
        let l:getNamespaceLine = l:classBraceLine
      endif
    endif

    let l:namespaceList = <SID>GetNamespaceList(l:getNamespaceLine)
    call cursor(l:getNamespaceLine, 0)

    if l:needChangeFile
        try
            call setpos('.', l:oldPosition)
            exec ':A'
        catch
        endtry
    endif

    let l:definitionFileName = expand('%')

    " remove using namespace
    while !empty(l:namespaceList)
        let l:processNamespace = l:namespaceList[0]
        let l:searchNamespace = search('using\_\s\+namespace\_\s\+' . l:processNamespace . '\_\s*;')
        if l:searchNamespace > 0
            call remove(l:namespaceList, 0, 0)
        else
            break
        endif
    endwhile
    
    let l:digInNamespaceLine = 0
    while !empty(l:namespaceList)
        let l:processNamespace = l:namespaceList[0]
        let l:searchNamespace = search('namespace\_\s\+' . l:processNamespace . '\_\s*{', 'e')

        if l:searchNamespace != 0
            let l:digInNamespaceLine = l:searchNamespace
            call remove(l:namespaceList, 0, 0)
        else
            break
        endif
    endwhile

    " no in the same file
    let l:namespace = join(l:namespaceList, '::') 
    if !empty(l:namespace) && l:namespace[-2:-1] != '::'
        let l:namespace = l:namespace . '::'
    endif

    if !empty(l:className) 
      if empty(l:parentClassName)
        let l:lineContent = l:returnType . l:namespace . l:className . '::' . l:functionBody
      else
        let l:lineContent = l:returnType . l:namespace . l:parentClassName . '::' . l:className . '::' . l:functionBody
      endif
    else
        let l:lineContent = l:returnType . l:namespace . l:functionBody
    endif

    if empty(l:argument)
        let l:lineContent = l:lineContent . ';'
    endif


    " if definition existed, finish
    let l:pos = getpos('.')
    call cursor(l:digInNamespaceLine, 0)
    normal ]}
    let l:digInNamespaceEndLine = line('.')
    call cursor(l:digInNamespaceLine, 0)

    " let l:searchResult = search('\V' . l:lineContent, '', l:digInNamespaceEndLine)
    let l:searchResult = <SID>SearchFunction(l:lineContent, l:digInNamespaceEndLine)
    if l:searchResult > 0
        echom l:lineContent . ' existd'
        return
    endif

    if l:digInNamespaceLine > 0 && l:digInNamespaceEndLine > 0
        let l:appendLine = l:digInNamespaceEndLine - 1
    else
        let l:appendLine = line('$')
        let l:fileExtend = expand('%:e')
        " if in header file, set the append line before the '#endif' line
        if l:fileExtend ==? 'h'
            call cursor(l:appendLine, 0)
            let l:appendLine = search('#endif', 'b')
            if l:appendLine > 0
                let l:appendLine = l:appendLine - 1
            else 
                let l:appendLine = line('$')
            endif
        endif
    endif

    let l:appendLineContent = getline(l:appendLine)

    let l:appendContent = []

    " insert a blank line 
    if l:appendLineContent !~ '^\s*$'
        call add(l:appendContent, '')
    endif

    if !empty(l:templateTypeBody)
        " let l:templateDeclaration = l:templateTypeBody 
        let l:templateDeclaration = substitute(l:templateTypeBody, '\w\+', 'typename &', 'g')
        let l:templateDeclaration = 'template' . l:templateDeclaration
        call add(l:appendContent, l:templateDeclaration)
    endif

    call add(l:appendContent, l:lineContent)

    if l:lineContent =~ '(.*)'
        call add(l:appendContent, '{')

        if exists("g:cpp_gencode_function_attach_statement")
            for statement in g:cpp_gencode_function_attach_statement
                call add(l:appendContent, gencode#ConstructIndentLine(statement))
            endfor
        endif

        if l:returnType =~ 'bool'
            call add(l:appendContent, <SID>ConstructReturnContent('true'))
        elseif l:returnType =~ 'const char\*\s*' 
            call add(l:appendContent, <SID>ConstructReturnContent('""'))
        elseif l:returnType =~ 'char'
            call add(l:appendContent, <SID>ConstructReturnContent("'\\0'"))
        elseif l:returnType =~ 'int\|unsigned\|long\|char\|uint\|short\|float\|double'
            call add(l:appendContent, <SID>ConstructReturnContent('0'))
        elseif l:returnType =~ 'void'
            " empty
        elseif l:returnType =~ '\%(std::\)string\s*$'
            call add(l:appendContent, <SID>ConstructReturnContent('""'))
        elseif l:returnType =~ '\*'
            call add(l:appendContent, <SID>ConstructReturnContent('NULL'))
        elseif l:returnType =~ '&'
            let l:returnType = substitute(l:returnType, '&', '', 'g')
            let l:returnType = substitute(l:returnType, ' ', '', 'g')
            call add(l:appendContent, <SID>ConstructReturnContent(l:returnType . '()'))
        elseif strlen(l:returnType) > 0
            let l:returnType = substitute(l:returnType, ' ', '', 'g')
            call add(l:appendContent, <SID>ConstructReturnContent(l:returnType . '()'))
        endif
        call add(l:appendContent, '}')
    endif

    call add(l:appendContent, '')
    call append(l:appendLine, l:appendContent)
    call cursor(l:appendLine + 1, 0)
    if l:needChangeFile
        exec ':A'
    endif
endfunction "}}}

if exists('g:vjde_completion') || &cp
    finish
endif
let g:vjde_completion=1 "{{{1
let s:key_preview=''
let s:preview_buffer=[]

let s:base_types=["void","int","long","float","double","boolean","char","byte"]
let s:directives={}
func! s:VjdeDirectiveAttribute(name,...) "{{{2
	let attr = VjdeTagAttributeElement_New(a:name)
	if a:0>0
		let attr.values+=a:1
	endif
	return attr
endf
func! s:VjdeDirectiveInit() "{{{2
	let elepage = VjdeTagElement_New("page")
	call elepage.AddAttribute(s:VjdeDirectiveAttribute("language",["java"]))
	call elepage.AddAttribute(s:VjdeDirectiveAttribute("extends"))
	call elepage.AddAttribute(s:VjdeDirectiveAttribute("import"))
	call elepage.AddAttribute(s:VjdeDirectiveAttribute("session",["true","false"]))
	call elepage.AddAttribute(s:VjdeDirectiveAttribute("buffer"))
	call elepage.AddAttribute(s:VjdeDirectiveAttribute("autoFlush",["true","false"]))
	call elepage.AddAttribute(s:VjdeDirectiveAttribute("isThreadSafe",["true","false"]))
	call elepage.AddAttribute(s:VjdeDirectiveAttribute("errorPage"))
	call elepage.AddAttribute(s:VjdeDirectiveAttribute("info"))
	call elepage.AddAttribute(s:VjdeDirectiveAttribute("isErrorPage",["true","false"]))
	call elepage.AddAttribute(s:VjdeDirectiveAttribute("pageEncoding",["GBK","GB2312","ISO-8859-1","UTF-8"]))
	call elepage.AddAttribute(s:VjdeDirectiveAttribute("contentType"))
	call elepage.AddAttribute(s:VjdeDirectiveAttribute("isELIgnored",["true","false"]))

	let eleinclude = VjdeTagElement_New("include")
	call eleinclude.AddAttribute(s:VjdeDirectiveAttribute("file"))

	let eletaglib  = VjdeTagElement_New("taglib")
	call eletaglib.AddAttribute(s:VjdeDirectiveAttribute("uri"))
	call eletaglib.AddAttribute(s:VjdeDirectiveAttribute("tagdir"))
	call eletaglib.AddAttribute(s:VjdeDirectiveAttribute("prefix"))

	let s:directives['page']=elepage
	let s:directives['include']=eleinclude
	let s:directives['taglib']=eletaglib
endf
call s:VjdeDirectiveInit()

func! VjdeAddToPreview(str) "{{{2
	call add(s:preview_buffer,a:str)
endf
func! VjdeClearPreview() "{{{2
	let s:preview_buffer=[]
endf
func! VjdeGetPreview() "{{{2
	return s:preview_buffer
endf

func! VjdeGetTypeName(var) "{{{2
        return s:GettypeName(a:var)
endf
func! s:GettypeName(var) " {{{2
    let l:firsttime = 0
    let l:firstpos = 0
    let l:oldl= line('.')
    let l:oldc= col('.')
    "let l:pattern = "\\<\\i\\+\\>\\(\\s*<.*>\\)*[\\[\\]\\t\\* ]\\+\\<".a:var."\\>"
    "let l:pattern = '\(return\|new\)\@!\<\i\+\>\(\s*<.*>\)*\(\s*\[.*\]\)*\s\+\<'.a:var.'\>'
    "let l:pattern = '\(return\)\@!\<\i\+\>\(\s*<.*>\)*\(\s*\[.*\]\)*\s\+\<'.a:var.'\>'
    "let l:pattern = '\(return\|import\|package\)\@!\<[^@\$=<>+\-\*\/%?:\&|\^ \t]\+\(\s*<.*>\)*\(\s*\[.*\]\)*\s*\<'.a:var.'\>'
    let l:pattern = '\(return\|import\|package\|public\|private\|protected\|static\|final\|synchronzied\|native\)\@!\(\<\i\+\>\.\)*\<\i\+\>\(\s*<.*>\)*\(\s*\[.*\]\)*\s\+\<'.a:var.'\>'
    let l:ldefine=search(l:pattern,"b")
    while l:ldefine > 0 
        let l:curr_line = getline(l:ldefine)
        let l:col_index = match(l:curr_line,l:pattern)
        "if synIDattr(synID(l:ldefine,matchend(l:curr_line,l:pattern),1),"name") == ""
        "if synIDattr(synID(l:ldefine,l:col_index+1,1),"name") == ""
        let synname= synIDattr(synIDtrans(synID(l:ldefine,l:col_index+1,1)),"name")
        if synname != "Comment" && synname!="Constant" &&synname!="Special"
            call cursor(l:oldl,l:oldc)
            "let r = matchstr(l:curr_line,'\<\i\+\>',l:col_index)
            let r = matchstr(l:curr_line,'[^ \t\[<]\+',l:col_index)
            "let r = matchstr(l:curr_line,'[^ \t]*',l:col_index)
            if r=='new'
                return a:var
            else 
                return r
            endif
        else
            if ( l:firsttime == 0 )
                let l:firsttime = 1
                let l:firstpos = l:ldefine
            else
                if ( l:firstpos == l:ldefine)
                    call cursor(l:oldl,l:oldc)
                    return ""
                endif
            endif
            let l:ldefine=search(l:pattern,"b")
        endif
    endw
    call cursor(l:oldl,l:oldc)
    return ""
endf

func! VjdeCommentFun(line,base,col,findstart) "{{{2
    if a:findstart
        return VjdeFindStart(a:line,a:base,a:col,'[@ \t"]')
    endif
    let ele = a:line[s:last_start-1]=='@'
    let g:vjde_tag_loader = VjdeTagLoaderGet("xdoclet",g:vjde_install_path.'/vjde/tlds/xdoclet.def')
    if ele  " element
        call VjdeTagCompletion('',a:base,2)
        return s:retstr
    endif
    let l = search('\*\s*@[^ \t]\+','nb')
    if l<=0 
        return ""
    endif
    let tag = strpart(matchstr(getline(l),'@[^ \t]\+',0),1)

    let ele = a:line[s:last_start-1]=~'[ \t]'
    if ele " attribute
        call VjdeTagCompletion(tag,a:base,3)
        return s:retstr
    endif
    let id1=VjdeFindStart(a:line,'',a:col,'[ \t]')
    let id2=VjdeFindStart(a:line,'',a:col,'[=]')
    if ( id1 < 0 || id2<id1)
        return id1."--".id2
    endif
    call VjdeTagCompletion(tag,strpart(a:line,id1,id2-id1-1),11,a:base)
    return s:retstr
endf



func! s:VjdeGetAllTaglibPrefix() "{{{2
    let l:line_imp = search ('^\s*<%@\s\+taglib\s\+\>',"nb")
    let l:res = []
    if l:line_imp == 0 
        return l:res
    endif
    while l:line_imp > 0 
        let l:str = getline(l:line_imp)
        let index = matchend(l:str,'^\s*<%@\s\+taglib\s\+.*\<uri\>\s*="')
        if  index!= -1 
            let index2 = SkipToIgnoreString(l:str,index+1,'"')
            if index2 >index+1
                call add(l:res,strpart(l:str,index+1,index2-index-1))
            endif
        endif
        let l:line_imp -= 1
    endw

    return l:res
endf
func! s:GetJspImportStr() "{{{2
    let l:line_imp = search ('^\s*<%@\s\+page\s\+\<import\>',"nb")
    let l:res = "java.lang.*;"
    if l:line_imp == 0 
        return l:res
    endif
    while l:line_imp > 0 
        let l:str = getline(l:line_imp)
        let index = matchend(l:str,'^\s*<%@\s\+page\s\+\<import\>\s*="')
        if  index!= -1 
            let index2 = SkipToIgnoreString(l:str,index+1,'"')
            if index2 >index+1
                let l:res =l:res.strpart(l:str,index,index2-index)
                if l:str[index2-1]!=';'
                    let l:res = l:res.';'
                endif
            endif
        endif
        let l:line_imp -= 1
    endw

    return substitute(l:res,',',';','g')
endf


func! s:VjdeCompletionByVIM(imps) "{{{2
	if empty(g:vjde_java_cfu)
		"let g:vjde_java_cfu = VjdeJavaCompletion_New(g:vjde_install_path.'/vjde/vjde.jar',g:vjde_lib_path)
		let g:vjde_java_cfu = VjdeJavaCompletion_New(g:vjde_install_path.'/vjde/vjde.jar',g:vjde_out_path.g:vjde_path_spt.g:vjde_lib_path)
	endif
	if index(s:base_types,s:type)>=0
		return 0
	endif
	call g:vjde_java_cfu.FindClass(s:type,a:imps)
	if !g:vjde_java_cfu.success
		return 0
	endif
	let index =1
	let length = len(s:types)
	let success = g:vjde_java_cfu.success
	while index < length && success
		let returntype = ''
		for member in g:vjde_java_cfu.class.members
			if s:types[index]==member.name
				let returntype = member.type
			endif
		endfor
		if returntype==''
			for method in g:vjde_java_cfu.class.methods
				if s:types[index] == method.name
					let returntype=method.ret_type
				endif
			endfor
		endif
		if returntype==''
			let success = 0
		else
			if index(s:base_types,returntype)>=0
				let success = 0
			else
				call g:vjde_java_cfu.FindClass(returntype,'')
				let success = g:vjde_java_cfu.success
			endif
		endif
		let index+=1
	endwhile
	let s:success = success
	return s:success
endf


"1 java 0 taglib 2 html 3 comment 4 xsl
func! VjdeCompletionFun(line,base,col,findstart) "{{{2
    if a:findstart 
        let ext = expand('%:e')
        if ext == 'java'
            if synIDattr(synIDtrans(synID(line('.'),a:col-1,1)),"name") == "Comment"
                let s:cfu_type=3
            else
                let s:cfu_type=4
            endif
        elseif ext=='jsp' " 0 1 2
            let t = s:VjdeJspTaglib() 
            let s:cfu_type=t
        elseif ext=='xsl'
            let s:cfu_type=5
        endif
    endif

    if s:cfu_type == 0 "taglib
            let s:retstr= s:VjdeTaglibCompletionFun(a:line,a:base,a:col,a:findstart)
    elseif s:cfu_type==1 "java in jsp
	    let s:retstr=s:VjdeJspCompletionFun(a:line,a:base,a:col,a:findstart)
    elseif s:cfu_type==2 "html
	    let g:vjde_def_loader=VjdeTagLoaderGet('html',g:vjde_install_path.'/vjde/tlds/html.def')
            let s:retstr= VjdeHTMLFun(a:line,a:base,a:col,a:findstart)
            let s:retstr.=join(s:VjdeGetAllTaglibPrefix(),"\n")
    elseif s:cfu_type==3 "comment
            let s:retstr= VjdeCommentFun(a:line,a:base,a:col,a:findstart)
    elseif s:cfu_type==4 "java
        let s:retstr = s:VjdeJavaCompletionFun(a:line,a:base,a:col,a:findstart)
    "elseif s:cfu_type==5 "xsl
        "return VjdeXslCompletionFun(a:line,a:base,a:col,a:findstart)
    endif
    if g:vjde_show_preview && strlen(s:retstr)!=0
	    let s:beginning=a:base
	    let s:key_preview=''
	    if !g:vjde_preview_gui
		    call s:VjdeUpdatePreviewBuffer(a:base)
	    endif
    endif
    return s:retstr
endf
"1 java in jsp 0 taglib 2 html
func! s:VjdeJspTaglib() "{{{2
        let grp = synIDattr(synIDtrans(synID(line('.'),col('.'),1)),"name")
        if (grp == 'jspExpr' || grp=='jspScriptlet' || grp=='jspDecl')
            return 1
        else
             let ed = matchend(getline(line('.')),'^\s*<%') 
             if ( ed != -1)
                 return 0
             endif
             let ed = matchend(getline(line('.')),'^\s*<jsp:') 
             if ( ed!=-1) 
                 return 2
             endif
             let ed = matchend(getline(line('.')),'^\s*<[0-9a-zA-Z]\+:') 
             if ( ed != -1)
                 return 0
             endif
             let ed = matchend(getline(line('.')),'^\s*<') 
             if ( ed != -1)
                 return 2
             endif
             return 1
         endif
endf

func! s:VjdeParentCFUVIM(pars,imps) "{{{2
	let s:preview_buffer=[]
for par in a:pars
    let s:type = par
    call s:VjdeCompletionByVIM(a:imps)
    if !g:vjde_java_cfu.success
        continue
    endif
    if g:vjde_show_preview
	    call s:VjdeGeneratePreviewBuffer(s:beginning)
    endif
    let s:retstr.= s:VjdeCreateString4CFU(s:beginning)
endfor
endf

func! s:VjdePkgCfuByVIM(prefix,base)
	let s:preview_buffer=[]
    call add(s:preview_buffer,'import '.a:prefix.':')
    let len = strlen(a:prefix)
    let isclass=0
    for item in VjdeJavaSearchPackagesAndClasses(g:vjde_install_path.'/vjde/vjde.jar',g:vjde_lib_path,a:prefix,a:base)
	    let part = strpart(item,len) 
	    let s:retstr.= part."\n"
	    if isclass
		    call add(s:preview_buffer,'class '.part.';')
	    else
		    if part[0] =~'[a-z]'
			    call add(s:preview_buffer,'package '.part.'.*;')
		    else
			    call add(s:preview_buffer,'class '.part.';')
			    let isclass = 1
		    endif
	    endif
    endfor
endf
func! s:VjdeJavaCompletionFun(line,base,col,findstart) "{{{2
    if a:findstart
        return VjdeFindStart(a:line,a:base,a:col,'[.@ \t]')
    endif

    let s:retstr=""
    let idx = match(a:line,'^\s*import\s*')
    if ( idx >= 0 ) 
        let str = substitute(a:line,'\s*import\s*\(static\)*\s*\(.*\)','\2','')
	call s:VjdePkgCfuByVIM(str,a:base)
        return s:retstr
    endif
    if a:line[s:last_start-1]=='@'
        call VjdeCommentFun(a:line,a:base,a:col,a:findstart)
        return s:retstr
    endif


    let s:beginning = a:base
    let l:imps = GetImportsStr()

    let s:types=[]
    if a:line[s:last_start-1]=~'[ \t]'
        let ps = VjdeFindParent(1)
        call s:VjdeParentCFUVIM(ps,l:imps)
	if strlen(s:retstr)==0 " not found , completion for package
		call s:VjdePkgCfuByVIM('',a:base)
	endif
        return s:retstr
    endif

    call s:VjdeObejectSplit(s:VjdeFormatLine(strpart(a:line,0,a:col)))


    if  len(s:types)<1 
        return ""
    endif

    if   len(s:types)<1 || s:types[0]== "this"|| s:types[0]== "super"
        "TODO add parent implements here
        let ps = VjdeFindParent(len(s:types)<1 || s:types[0]=="this")
        call s:VjdeParentCFUVIM(ps,l:imps)
        return s:retstr
    endif
    
    let staticcfu=0
    let s:type=s:GettypeName(s:types[0])
    if s:type == ""
	if s:types[0][0]=~'[a-z]' " something like java.util ...
		call s:VjdePkgCfuByVIM(join(s:types,'.').'.',a:base)
		return s:retstr
	endif
        let s:type=s:types[0]
	let staticcfu = 1
    end

    
    call s:VjdeCompletionByVIM(l:imps)
    if !g:vjde_java_cfu.success
	    let s:retstr=""
    else
	    let s:retstr=s:VjdeCreateString4CFU(s:beginning)
	    if g:vjde_show_preview
		  call s:VjdeGeneratePreviewBuffer(s:beginning)
	    endif
    endif
    return s:retstr
endf

func! s:VjdeCreateString4CFU(base) "{{{2
	let str=''
	    if strlen(a:base)==0
		    for member in g:vjde_java_cfu.class.members
			    let str.=member.name."\n"
		    endfor
		    for method in g:vjde_java_cfu.class.methods
			    let str.=method.name."\n"
		    endfor
	    else
		    for member in g:vjde_java_cfu.class.SearchMembers('stridx(member.name,"'.a:base.'")==0')
			    let str.=member.name."\n"
		    endfor
		    for method in g:vjde_java_cfu.class.SearchMethods('stridx(method.name,"'.a:base.'")==0')
			    let str.=method.name."\n"
		    endfor

	    endif
	    return str
endf
func! s:VjdeFormatLine(line) "{{{2
    let len = strlen(a:line)
    let index0 = SkipToIgnoreString(a:line,0,'[=<>+\-\*\/%?:\&|\^|]')
    let index=0
    while index0 != -1
        let index = index0
        let index0 = SkipToIgnoreString(a:line,index0+1,'[=<>+\-\*\/%?:\&\^|]')
    endw
    let index0 = s:MatchToIgnoreString(a:line,index+1,'^return')
    if  index0 != -1
        let index = index0+6
    endif
    let index0 = s:MatchToIgnoreString(a:line,index+1,'^new')
    if  index0 != -1
        let index = index0+3
    endif
    let index = SkipToIgnoreString(a:line,index,'[^=<>+\-\*\/%?:\&\^|]')
    if index == -1
	    return ""
    else
	    "let index = index0
    endif


    let l:index2= index
    let ret_index = index

    let l:stack = [l:index2]
    while  l:index2 < len
        let c= a:line[l:index2]
        if  c == '(' || c=='['
            call add(l:stack,l:index2+1)
        elseif c == ')' || c==']'
            call remove(l:stack,-1)
        elseif c == '\'
            let l:index2 = l:index2+1
        elseif c=='"'
            let l:index2 = SkipToIgnoreString(a:line,l:index2+1,'"')
            if  l:index2 == -1 " Can't find the next \" for the current one
                return ""
            endif
        endif
        let l:index2 = l:index2+1
    endw
    if len(l:stack)>0 
        let ret_index=remove(l:stack,-1)
    else
        return ""   " incorrectly line
    endif
    let l:index2 = matchend(a:line,'^\(return\s\+\|new\s\+\|([^)]*)\s*\)',ret_index)
    if  l:index2 != -1
        let ret_index = l:index2 
    endif
    "let l:index2 = matchend(a:line,"new\\s\\+",ret_index)
    "if  l:index2 != -1
        "let ret_index = l:index2 
    "endif
    "let l:index2 = matchend(a:line,"return\\s\\+",ret_index)
    "if  l:index2 != -1
        "let ret_index = l:index2 
    "endif
    return strpart(a:line,ret_index)
endf

func! s:VjdeObejectSplit(line) "{{{2
    let s:types=[]
    let len = strlen(a:line)
    let index = SkipToIgnoreString(a:line,0,'\a')
    let oind = s:ObjectSplit(a:line,index)
    while ( oind!=-1 && oind < len )
        if a:line[oind]=='('
            let oind = SkipToIgnoreString(a:line,oind+1,')')
            if ( oind == -1 )
                return s:types
            endif
            let oind = SkipToIgnoreString(a:line,oind,'\.')
            if ( oind == -1 )
                return s:types
            endif
        endif
        if a:line[oind]=='['
           let oind = SkipToIgnoreString(a:line,oind+1,'\]')
           if ( oind == -1 )
               return s:types
           endif
        endif
        let oind = oind+1
        let oind = s:ObjectSplit(a:line,oind)
    endw
    return s:types
endf

func! s:ObjectSplit(line,index) "{{{2
    let oend = SkipToIgnoreString(a:line,a:index,'[\.(\[]')
    if ( oend!= -1 && oend!=a:index)
        call add(s:types,strpart(a:line,a:index,oend-a:index))
    end
    return oend
endf

func! s:MatchToIgnoreString(line,index,target) "{{{2
    let start = a:index
    let len = strlen(a:line)
    while start < len
        if ( match(a:line,a:target,start)==start) 
            return start
        endif
        if ( a:line[start]=='\')
            let start=start+1
        elseif (a:line[start]=='"')
            let start=SkipToIgnoreString(a:line,start+1,'"')
            if start == -1
                return -1
            end
        endif
        let start=start + 1
    endwhile
    return -1
endf

func! VjdespFun(line) "{{{2
    call s:VjdeObejectSplit(a:line)
    echo s:types
endf

func! s:VjdeInfomation() "{{{2
    let ext = expand('%:e')
    if ext == 'java'
        return s:VjdeInfo()
    elseif ext=='jsp'
        let t = s:VjdeJspTaglib()
        if t == 1
            return s:VjdeJspInfo()
        elseif t == 0
            return s:VjdeTaglibInfo()
        else
            return 
        endif
    elseif ext=='xsl'
        return s:VjdeXslInfo()
    endif
endf
func! s:VjdeGotoDecl() "{{{2
    let key = expand('<cword>')
    let m_line = line('.')
    let m_col = col('.')
    let line = getline(m_line)
    let idx = matchend(line,'.\>',m_col)
    call s:VjdeObejectSplit(s:VjdeFormatLine(strpart(line,0,idx)).".")
    if len(s:types)<1
        echo "no object find by ".key
        return 
    endif
    if s:types[0]== "this"
        "TODO add parent implements here
        return ""
    endif
    let s:type=s:GettypeName(s:types[0])
    if s:type == ""
        let s:type=s:types[0]
    end

    let l:imps = GetImportsStr()
    if expand("%:e")=="jsp"
	    let l:imps = s:GetJspImportStr()
    endif
    let s:retstr=""

    if ( len(s:types) > 1 )
        let s:beginning = remove(s:types,-1)
    else 
        let s:beginning = ""
    endif
 
    call s:VjdeCompletionByVIM(l:imps)

    let classname=''
    if g:vjde_java_cfu.success
	    let classname=g:vjde_java_cfu.class.name
    else
        echo 'class under cursor is not found.'
        return
    endif
    if g:vjde_auto_mark == 1
        mark J
    endif
    let fp = findfile(substitute(classname,'\.','/','g').'.java')
    if fp != ''
        exec 'edit '.fp
    else
        echo 'source for :'.classname.' is not found in[path]:'.&path
	return
    endif
    if s:beginning == "" 
        return 
    endif
    call search('\s*\(\<public\|protected\|\)\s*\(static\s\|virtual\s\|final\s\)*[^ \t]\+\s\+\<'.s:beginning.'\>','w')
endf
func! s:VjdeTaglibPrefix(line) "{{{2
    let id1 = stridx(a:line,'<')
    let id2 = stridx(a:line,':',id1)
    if ( id1 < 0 || id2<id1) 
        return ""
    endif
    return strpart(a:line,id1+1,id2-id1-1)
endf
func! s:VjdeTaglibTag(line) "{{{2
    let id1 = stridx(a:line,':')
    let id2 = SkipToIgnoreString(a:line,id1,'[ \t]')
    if ( id1 < 0 || id2<id1) 
        return ""
    endif
    return strpart(a:line,id1+1,id2-id1-1)
endf
func! s:VjdeTaglibInfo() "{{{2
    let key = expand('<cword>')
    let m_line = line('.')
    let m_col = col('.')
    let line = getline(m_line)
    let start=m_col
    let isattr=0
    while start >=0
        if line[start] =~ '[ \t]'
            let isattr = 1
            break
        elseif line[start]==':'
            let isattr = 0
            break
        end
        let start = start-1
    endw
    let prefix = s:VjdeTaglibPrefix(line)
    if prefix=='jsp'
        let uri="http://java.sun.com/jsp/jsp"
    "elseif prefix=='xsl'
    else
        let uri = s:VjdeTaglibGetURI(prefix)
        if (uri == '')
            return "no found uri for prefix:".prefix
        endif
    endif
    let tag = s:VjdeTaglibTag(line)
    if isattr
        if ( tag == '' ) 
            echo "no found tag for :".line
            return
        endif
        call s:VjdeTaglibInfoRuby(uri,key,"1",tag)
    else
        call s:VjdeTaglibInfoRuby(uri,key,"0","")
    endif
endf

func! s:VjdeTaglibInfoRuby(uri,base,attr,tag) "{{{2
ruby<<EOF
if VIM::evaluate('a:attr')=="1"
   $vjde_tld_loader.each_attr4uri(VIM::evaluate('a:uri'),VIM::evaluate('a:tag'),VIM::evaluate('a:base')) { |t|
        t.to_s.each_line { |s| puts s}
    }
else
    $vjde_tld_loader.each_tag4uri(VIM::evaluate('a:uri'),VIM::evaluate('a:base')) { |t|
        t.to_s.each_line { |s| puts s}
    }
end
EOF
endf
func! s:VjdeInfo(...) "{{{2
    let key = expand('<cword>')
    let m_line = line('.')
    let m_col = col('.')
    let line = getline(m_line)
    let idx = matchend(line,'.\>',m_col-1)
    let curr_part = strpart(line,0,idx)
    let matchdef = matchend(line,'\(\<\i\+\.\>\)*\(public\|private\|static\|protected\|final\)\@!\<\(\(\i\+\|'.key.'\)\)\>\(\s*<.*>\)*\(\s*\[.*\]\)*\s\+\<\(\i\+\|'.key.'\)\>',0)
    if matchdef>=0
	    let s:types=[]
	    if matchdef==idx
		    let s:type=s:GettypeName(key)
	    else
		    let s:type=key
	    endif
    else
	    call s:VjdeObejectSplit(s:VjdeFormatLine(strpart(line,0,idx)).".")
	    if len(s:types)<1
		echo "no object find by ".key
		return 
	    endif
	    if s:types[0]== "this"
		"TODO add parent implements here
		return ""
	    endif
	    let s:type=s:GettypeName(s:types[0])
	    if s:type == ""
		let s:type=s:types[0]
	    endif
    endif

    let l:imps = GetImportsStr()
    let s:retstr=""

    if ( len(s:types) > 1 )
        let s:beginning = remove(s:types,-1)
    else 
        let s:beginning = ""
    endif
    echo s:type
 
    call s:VjdeCompletionByVIM(l:imps)
    if !g:vjde_java_cfu.success
	    let s:retstr=''
    else
	    let s:retstr = s:VjdeCreateString4CFU(s:beginning)
    endif
    if a:0 >=1 && a:1==1
	    return
    endif

    if g:vjde_java_cfu.success
	    call s:VjdeGeneratePreviewBuffer(s:beginning)
	    for item in s:preview_buffer
		    echo item
	    endfor
    endif
endf


func! s:VjdeJspInfo() "{{{2
    let key = expand('<cword>')
    let m_line = line('.')
    let m_col = col('.')
    let line = getline(m_line)
    let idx = matchend(line,'.\>',m_col)
    call s:VjdeObejectSplit(s:VjdeFormatLine(strpart(line,0,idx)).".")
    if len(s:types)<1
        echo "no object find by ".key
        return 
    endif
    if s:types[0]== "this"
        "TODO add parent implements here
        return ""
    endif
    let s:type=s:GettypeName(s:types[0])
    if s:type == ""
        let s:type=s:types[0]
    end

    let l:imps = ""
    
    if s:types[0] == 'out'
        let s:type = 'javax.servlet.jsp.JspWriter'
    elseif s:types[0]=='request'
        let s:type = 'javax.servlet.ServletRequest'
    elseif s:types[0]=='response'
        let s:type = 'javax.servlet.ServletResponse'
    elseif s:types[0]=='page'
        let s:type = 'java.lang.Object'
    elseif s:types[0]=='session'
        let s:type = 'javax.servlet.http.HttpSession'
    elseif s:types[0]=='application'
        let s:type = 'javax.serlet.ServletContext'
    else
        let s:type=s:GettypeName(s:types[0])
        if s:type == ""
            let s:type=s:types[0]
        end
        "TODO find the import for jsp pages
        let l:imps = s:GetJspImportStr()
    endif
 

    "let l:imps = GetImportsStr()
    let s:retstr=""

    if ( len(s:types) > 1 )
        let s:beginning = remove(s:types,-1)
    else 
        let s:beginning = ""
    endif
 
    call s:VjdeCompletionByVIM(l:imps)

    if g:vjde_java_cfu.success
	    call s:VjdeGeneratePreviewBuffer(s:beginning)
	    for item in s:preview_buffer
		    echo item
	    endfor
    endif
endf
func! s:VjdeJspCompletionFun(line,base,col,findstart) "{{{2
    if a:findstart
        return VjdeFindStart(a:line,a:base,a:col,'[\.]')
    endif

    let s:beginning = a:base

    "call s:VjdeObejectSplit(s:VjdeFormatLine(strpart(a:line,0,a:col)).'.')
    call s:VjdeObejectSplit(s:VjdeFormatLine(strpart(a:line,0,a:col)))
    "call s:VjdeObejectSplit(a:line)

    if  len(s:types)<1 
        return ""
    endif
    if s:types[0]== "this"
        "TODO add parent implements here
        return ""
    endif
    let l:imps=""
    let l:imps = s:GetJspImportStr()

    if s:types[0] == 'out'
        let s:type = 'javax.servlet.jsp.JspWriter'
    elseif s:types[0]=='request'
        let s:type = 'javax.servlet.ServletRequest'
    elseif s:types[0]=='response'
        let s:type = 'javax.servlet.ServletResponse'
    elseif s:types[0]=='page'
        let s:type = 'java.lang.Object'
    elseif s:types[0]=='session'
        let s:type = 'javax.servlet.http.HttpSession'
    elseif s:types[0]=='application'
        let s:type = 'javax.serlet.ServletContext'
    else
        let s:type=s:GettypeName(s:types[0])
        if s:type == ""
		if s:types[0][0]=~'[a-z]' " something like java.util ...
			call s:VjdePkgCfuByVIM(join(s:types,'.').'.',a:base)
			return s:retstr
		endif
		let s:type=s:types[0]
        end
        "TODO find the import for jsp pages
    endif
    

    let s:retstr=""
    call s:VjdeCompletionByVIM(l:imps)

    if !g:vjde_java_cfu.success
	    let s:retstr=""
    else
	    let s:retstr=s:VjdeCreateString4CFU(s:beginning)
	    if g:vjde_show_preview 
		  call s:VjdeGeneratePreviewBuffer(s:beginning)
	    endif
    endif
    return s:retstr
endf

func! s:VjdeTaglibCompletionFun(line,base,col,findstart) "{{{2
    if a:findstart
        return VjdeFindStart(a:line,a:base,a:col,'[ \t:@"]')
    endif
    let s:retstr=""
    "let id1 = stridx(a:line,'<') " TODO:find uncompleted <
    let id1 = VjdeFindUnendPair(a:line,'<','>',0,a:col) " TODO:find uncompleted <
    let id2 = stridx(a:line,':',id1)
    if ( id1 < 0 )
        return s:retstr
    endif
    if ( id2 == -1 ) " this is a <%@ ....
        call s:VjdeDirectiveCFUVIM(a:line,a:base,a:col,a:findstart)
        return s:retstr
    endif
    if !has('ruby') 
	    return ""
    endif
    let prefix=strpart(a:line,id1+1,id2-id1-1) 
    if prefix=='jsp'
        let uri="http://java.sun.com/jsp/jsp"
    else
        let uri = s:VjdeTaglibGetURI(prefix)
        if ( uri == '' ) 
            "return "no found uri for prefix:".prefix
            return ""
        endif
    endif

    let id5 = a:col
    while id5 >=0 
        if a:line[id5]=~'[ \t:]'
            break
        endif
        let id5-=1
    endw
    if id5 < 0 
        "return "unknown"
        return ""
    endif
    if a:line[id5]!=':' 
        let id3 = match(a:line,'[ \t]',id2)
        if ( id3 < id2 ) 
            return ""
        endif
        let tag = strpart(a:line,id2+1,id3-id2-1)
        call s:VjdeTaglibCompletionRuby(uri,a:base,1,tag)
    else 
        call s:VjdeTaglibCompletionRuby(uri,a:base,0,'')
    endif
    return s:retstr
endf

func! s:VjdeTaglibGetURI(prefix)  "{{{2
    let l:line_tld = search('prefix\s*=\s*"'.a:prefix.'"\s\+',"nb")
    if l:line_tld==0
        return ''
    endif
    return substitute(getline(l:line_tld),'.\+\suri\s*=\s*"\([^"]*\)".*','\1',"")
endf

func! s:VjdeDirectiveCFUVIM(line,base,col,findstart) "{{{2
    let s:preview_buffer=[]
    let str=''
    let attr= match(a:line,'<%@\s\+\(page\|include\|taglib\)\s')>=0?1:0
    if attr
	    let mtag = matchstr(a:line,'\(page\|include\|taglib\)')
	    if mtag==''
		    return ''
	    endif
	    call add(s:preview_buffer,mtag.'=>attributes:')
	    for attribute in s:directives[mtag].attributes
		    if  stridx(attribute.name,a:base)==0
			    let str.=attribute.name."\n"
			    call add(s:preview_buffer,'attribute '.attribute.name.';')
		    endif
	    endfor
    else
	    for mdir in keys(s:directives)
		    if  stridx(mdir,a:base)==0
			    let str.=mdir."\n"
			    call add(s:preview_buffer,'Directive '.mdir.';')
		    endif
	    endfor
    endif
    let s:retstr=str

    return s:retstr
endf
" uri http://java.... ; base ; attr 1 find attr 0 find tag
"
func! s:VjdeTaglibCompletionRuby(uri,base,attr,tag) "{{{2
    let s:preview_buffer=[]
ruby<<EOF
str = ""
if VIM::evaluate('a:attr')=="1"
    VIM::command('call add(s:preview_buffer,"'+VIM::evaluate('a:tag')+'=>attributes:")')
   $vjde_tld_loader.each_attr4uri(VIM::evaluate('a:uri'),VIM::evaluate('a:tag'),VIM::evaluate('a:base')) { |t|
   name= t.get_text("name").value
    str << name
    VIM::command('call add(s:preview_buffer,"attribute '+name+';")')
    if (name[-1,1]!='"')
        str << "=\\\"\n"
    else
        str << "\n"
    end
    }
    else
    VIM::command('call add(s:preview_buffer,"'+VIM::evaluate('a:uri')+':")')
    $vjde_tld_loader.each_tag4uri(VIM::evaluate('a:uri'),VIM::evaluate('a:base')) { |t|
        name = t.get_text("name").value
        str << name
        VIM::command('call add(s:preview_buffer,"tag '+name+';")')
        str << "\n"
    }
end
VIM::command("let s:retstr=\""+str+"\"")
EOF
endf

func! s:VjdeXslInfo() "{{{2
    let key = expand('<cword>')
    let m_line = line('.')
    let m_col = col('.')
    let line = getline(m_line)
    let start=m_col
    let isattr=0
    while start >=0
        if line[start] =~ '[ \t]'
            let isattr = 1
            break
        elseif line[start]==':'
            let isattr = 0
            break
        end
        let start = start-1
    endw
    let prefix = s:VjdeTaglibPrefix(line)

    if prefix!='xsl'
        echo "this cfu not useable for:".prefix
        return s:retstr
    endif
    let uri="http://www.w3c.org/1999/XSL/Transform"

    let tag = s:VjdeTaglibTag(line)
    if isattr
        if ( tag == '' ) 
            echo "no found tag for :".line
            return
        endif
        call s:VjdeTaglibInfoRuby(uri,key,"1",tag)
    else
        call s:VjdeTaglibInfoRuby(uri,key,"0","")
    endif
endf


func! s:VjdeXMLSetupNSLoader(prefix) "{{{2
    let l:line_imp = search('\sxmlns:'.a:prefix.'="[^"]*"','nb') " find xmlns:{name}=\".............\"
    if l:line_imp <= 0
        return 0
    endif
    let l:str = matchstr(getline(l:line_imp),'\sxmlns:'.a:prefix.'="[^"]*"')
    let id1 = stridx(l:str,'"')
    let ns = strpart(l:str,id1+1,strlen(l:str)-id1-2)
    if ns == 'http://www.w3c.org/1999/XSL/Transform' || ns == 'http://www.w3.org/1999/XSL/Transform'
        ruby $vjde_def_loader=Vjde::VjdeDefLoader.[]("xsl",VIM::evaluate('g:vjde_install_path')+"/vjde/tlds/xsl.def")
        let s:isfind=1
        return 
    elseif ns == 'http://www.w3.org/TR/html401' || ns == 'http://www.w3.org/TR/html4'|| ns == 'http://www.w3.org/TR/html'
        ruby $vjde_def_loader=Vjde::VjdeDefLoader.[]("html",VIM::evaluate('g:vjde_install_path')+"/vjde/tlds/html.def")
        let s:isfind = 1
        return
    end
    let s:isfind = 0
ruby<<EOF
   loader = $vjde_dtd_loader.find(VIM::evaluate("ns"))
   $vjde_def_loader=loader if loader!=nil
   VIM::command("let s:isfind=1") if loader!=nil
EOF
endf
func! s:VjdeXMLFindDTD() "{{{2
    let l:line_imp = search('<!DOCTYPE\s\+[^ \t]\+\s\+','nb') 
    "let l:line_imp = search('<!DOCTYPE\s\+[^ \t]\+\s\+SYSTEM\s\+"[^"]\+"','nb') 
    if l:line_imp <= 0
        let s:isfind = 0
        return
    endif
    "let l:str = matchstr(getline(l:line_imp),'<!DOCTYPE\s\+[^ \t]\+\s\+SYSTEM\s\+"[^"]\+"')
    "let id1 = stridx(l:str,'"')
    "let ns = strpart(l:str,id1+1,strlen(l:str)-id1-2)
    let s:isfind = 0
ruby<<EOF
    lnum = VIM::evaluate("l:line_imp").to_i
    str = VIM::Buffer.current[lnum]
    while str['>'] ==nil
        lnum +=1 
        str << " " << VIM::Buffer.current[lnum]
    end
    loader = nil
    str.sub!(/<!DOCTYPE\s+([^ \t]+)\s+(PUBLIC|SYSTEM)\s+"([^"]+)"\s*("([^"]*)")*/) { |p| 
        loader = $vjde_dtd_loader.find($3) if $3!=nil
        loader = $vjde_dtd_loader.find($5) if loader==nil && $5!=nil
    }
    $vjde_def_loader=loader if loader!=nil
    VIM::command("let s:isfind=1") if loader!=nil
EOF
endf


func! VjdeHTMLFun(line,base,col,findstart) "{{{2
    if a:findstart
        return VjdeFindStart(a:line,a:base,a:col,'[ \t=<"]')
    endif
    let s:retstr=""

    let ele = a:line[s:last_start-1]=='<'
    if ele " element
       call VjdeTagCompletion('',a:base,2)
       return s:retstr
    endif
    let def_line = search('<','nb')
    if def_line == -1
        return ' I can not find <'
    endif
    let def_col = a:col
    if  def_line < line('.')
        let def_col=9999
    endif

    let def_l = getline(def_line)
    let id1 = VjdeFindUnendPair(def_l,'<','>',0,def_col)
    let id2 = SkipToIgnoreString(def_l,id1,'[ \t]')
    if id1 < 0 || id2 <=id1
        return ""
    endif
    let tag = strpart(def_l,id1+1,id2-id1-1)

    let ele = a:line[s:last_start-1]=~'[ \t]'
    if ele " attribute
        call VjdeTagCompletion(tag,a:base,3)
        return s:retstr
    endif

    let id1=VjdeFindStart(a:line,'',a:col,'[ \t]')
    let id2=VjdeFindStart(a:line,'',a:col,'[=]')
    if ( id1 < 0 || id2<id1)
        return id1."--".id2
    endif
    let ele = a:line[s:last_start]=='"'
    "echo tag
    "echo strpart(a:line,id1,id2-id1-1)
    "echo a:base
    call VjdeTagCompletion(tag,strpart(a:line,id1,id2-id1-1),10+ele,a:base)
    return s:retstr
endf

func! VjdeFindStart(line,base,col,mode_p) "{{{2
        let start = a:col
        while start > 0 && a:line[start - 1] !~ a:mode_p
            let start = start - 1
        endwhile
        let s:last_start=start
        return start
endf

func! VjdeTagCompletion(tag,base,t,...) "{{{2
	call VjdeClearPreview()
	if empty(g:vjde_tag_loader)
		return 
	endif
	let str=''
	"element attribute value
	if a:t=="10" || a:t=="11" || a:t=="1" 
		let pre = a:1
		call VjdeAddToPreview(a:tag.'=>'.a:base.'=>values:')
		if strlen(pre)==0
			for val in g:vjde_tag_loader.FindValues(a:tag,a:base)
				if strlen(val)==0
					continue
				endif
				let str.=val."\n"
				call VjdeAddToPreview('value '.val.';')
			endfor
		else
			for val in g:vjde_tag_loader.SearchValues(a:tag,a:base,'stridx(vjde_item,"'.pre.'")==0')
				if strlen(val)==0
					continue
				endif
				let str.=val."\n"
				call VjdeAddToPreview('value '.val.';')
			endfor
		endif
	elseif a:t=='2' "tag
		call VjdeAddToPreview('element:')
		let cond='1'
		if strlen(a:base)>0
			let cond = 'stridx(vjde_item.name,"'.a:base.'")==0'
		endif
		for val in g:vjde_tag_loader.SearchTags(cond)
			let str.=val.name."\n"
			call VjdeAddToPreview('element '.val.name.';')
		endfor
	elseif a:t=='3' "attribute
		call VjdeAddToPreview(a:tag.'=>attributes:')
		let cond='1'
		if strlen(a:base)>0
			let cond = 'stridx(vjde_item.name,"'.a:base.'")==0'
		endif
		for val in g:vjde_tag_loader.SearchAttributes(a:tag,cond)
			let str.=val.name."\n"
			call VjdeAddToPreview('attribute '.val.name.';')
		endfor
	elseif a:t=='4' "children
	endif
	let s:retstr=str[0:1024]
endf
func! VjdeXMLFun(line,base,col,findstart) "{{{2
    if a:findstart
        return VjdeFindStart(a:line,a:base,a:col,'[ \t=<:"]')
    endif

    let aline=a:line
    let abase=a:base
    let acol=a:col

    let ele = aline[s:last_start-1] =~'[:<]'

    if ele
	    let def_line=line('.')
    else
	    let def_line = search('<','nb')
    endif
    if def_line == -1
	return ''
    endif
    let def_l = getline(def_line)
    if aline[s:last_start-1]=='<'
	    let id1 = s:last_start-1
    else
	    let id1 = VjdeFindUnendPair(def_l,'<','>',0,a:col)
    endif
    if id1 == -1
	return ''
    endif
    
    
    let prefix=''
    let id3 = stridx(def_l,':',id1)
    if id3 != -1 " has a namespace
	let prefix=strpart(def_l,id1+1,id3-id1-1) 
    endif

    let s:retstr=''
    if prefix!='' 
        call s:VjdeXMLSetupNSLoader(prefix) 
    else " find DTD and setup $vjde_def_loader
        call s:VjdeXMLFindDTD()
    endif
    if s:isfind == 0 
            return ' I can''t find namespace or dtd for :'.prefix
    endif

    if ele
        let tag=''
        if g:vjde_xml_advance
            "TODO search child
            "let tag = s:VjdeFindUnendElement(c_linenum,a:col)
            let tag = s:VjdeFindUnendElement(def_line,id1)
            if ( tag != '')
                if prefix!=''
                    call VjdeHTMLRuby(strpart(tag,strlen(prefix)+1),abase,4)
                else 
                    call s:VjdeHTMLRuby(tag,abase,4)
                endif
                return s:retstr
            endif
        endif
        call s:VjdeHTMLRuby('',abase,2)
        return s:retstr
    endif

    let id2 = SkipToIgnoreString(def_l,id1,'[ \t]')
    if id3!=-1
        let id1=id3
    endif
    let tag = strpart(def_l,id1+1,id2-id1-1)

    let ele = aline[s:last_start-1]=~'[ \t]'
    if ele " attribute
        call s:VjdeHTMLRuby(tag,abase,3)
        return s:retstr
    endif

    let id1=VjdeFindStart(aline,'',acol,'[ \t]')
    let id2=VjdeFindStart(aline,'',acol,'[=]')
    if ( id1 < 0 || id2<id1)
        return id1."--".id2
    endif
    let ele = aline[s:last_start]=='"'
    call s:VjdeHTMLRuby(tag,strpart(aline,id1,id2-id1-1),10+ele,abase)
    return s:retstr
endf
func! s:VjdeFindUnendElement(line_num,col_num) "{{{2
    let l = a:line_num
    let col = a:col_num
    let l:rpos=[[-1,0],[0,0]]
    while l > 0 && col>0
        let pos = s:VjdeFindPairBack(l,col,'<','>') " search for < .... >
        "echo pos
        if pos[0][0] < 0
            return ''
        endif
        let str = getline(pos[0][0])
        if str[pos[0][1]]=='/' " end element </...>
            let name = strpart(str,pos[0][1]+1,pos[1][1]-pos[0][1]-2)
            let l = search('<\<'.name.'\>','nb') " find <ele-name ... >
            if  l > 0 
                let str = getline(l)
                let col = match(str,'<\<'.name.'\>')
            endif
            continue
        endif
        if str[pos[0][1]]=~'[?!]' " end element <!--...> 
            let l = pos[0][0]    " next
            let col=pos[0][1] -1
            continue
        endif
        let str = getline(pos[1][0])
        if str[pos[1][1]-2]=='/' " end element  <.../>
            let l = pos[0][0]
            let col=pos[0][1]
            continue
        endif
       let l:rpos=pos
        break
    endw
    
    "echo l:rpos
    if l:rpos[0][0]>0
        "echo getline(l:rpos[0][0])
        return strpart(matchstr(getline(l:rpos[0][0]),'<[^ \t]\+',l:rpos[0][1]-1),1)
    else
        return ''
    endif
endf
func! s:VjdeFindPairBack(line,col,m_start,m_end) "{{{2
    let line = a:line
    let col = a:col
    let res = [[0,0],[0,0]]
    let e = VjdeFindStart(getline(line),'',col,a:m_end)
    while e <= 0 && line>0
        let line = line-1
        let str = getline(line)
        let e = VjdeFindStart(str,'',strlen(str),a:m_end)
    endw
    let res[1][0]=line
    let res[1][1]=e

    let e = VjdeFindStart(getline(line),'',e,a:m_start)
    while e <= 0 && line>0
        let line = line-1
        let str = getline(line)
        let e = VjdeFindStart(str,'',strlen(str),a:m_start)
    endw
    let res[0][0]=line
    let res[0][1]=e
    return res
endf

func! s:VjdePreviewWindowInit() "{{{2
	setlocal pvw
	setlocal buftype=nofile
	setlocal nobuflisted
	setlocal ft=preview
	let chars='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._:%@!'
	let start=strlen(chars)
	while start>0
		let var = chars[start-1]
		exec 'inoremap <buffer> '.var.' <Esc>:call VjdePreviewKeyPress("'.var.'")<cr>a'
		let start -= 1
	endwhile
	inoremap <buffer> <Backspace> <Esc>:call VjdePreviewKeyPress('Backspace')<cr>a
	inoremap <buffer> <Space> <Esc>:call VjdePreviewSelect(' ')<cr>a
	inoremap <buffer> <cr> <Esc>:call VjdePreviewSelect("\n")<cr>a
	"inoremap <buffer> . <Esc>:call VjdePreviewSelect('.')<cr>a.
	inoremap <buffer> ( <Esc>:call VjdePreviewSelect('(')<cr>a(
	inoremap <buffer> [ <Esc>:call VjdePreviewSelect('[')<cr>a[
	inoremap <buffer> ; <Esc>:call VjdePreviewSelect(';')<cr>a;
	inoremap <buffer> ? <Esc>:call VjdePreviewSelect('?')<cr>a?
	"inoremap <buffer> : <Esc>:call VjdePreviewSelect(':')<cr>a:
	inoremap <buffer> " <Esc>:call VjdePreviewSelect('"')<cr>a"
	inoremap <buffer> <C-CR> <Esc>:call VjdePreviewSelect("C-CR")<cr>a
	inoremap <buffer> <M-d> <Esc>:call VjdeShowJavadoc()<cr>a

	nnoremap <buffer> <Space> :call VjdePreviewSelect(' ')<cr>a
	nnoremap <buffer> <cr> :call VjdePreviewSelect("\n")<cr>a
	nnoremap <buffer> <C-CR> :call VjdePreviewSelect("C-CR")<cr>a
	nnoremap <buffer> <M-d> :call VjdeShowJavadoc()<cr>
	nnoremap <buffer> <Backspace> :call VjdePreviewKeyPress('Backspace')<cr>
	au CursorHold <buffer> call VjdeShowJavadoc()
	hi def link User1 Tag
endf
func! VjdePreviewSelect(k) "{{{2
	let clnr = line('.')
	let word = s:key_preview
	if a:k !="\n" 
		"let clnr = search('^[^ \t]\+\s\([^(;]\+\)[(;].*$','')
		let clnr = search('^[^ \t]\+\s\('.s:beginning.word.'[^(;]*\)[(;].*$','')
	endif
	if clnr>1
		let cstr = getline(clnr)
		let word = substitute(cstr,'^[^ \t]\+\s\([^(;]\+\)[(;].*$','\1','')
		let word = strpart(word,strlen(s:beginning))
	endif
        match none
	q!
	silent! wincmd p
	call s:VjdeInsertWord(word)
	"let lnr = line('.')
	"let lcol = col('.')
	"let str = getline(lnr)
	"call setline(lnr,strpart(str,0,lcol).word.strpart(str,lcol))
	"exec 'normal '.strlen(word).'l'
endf "}}}2
func! s:VjdeInsertWord(word) "{{{2
	let lnr = line('.')
	let lcol = col('.')
	let str = getline(lnr)
	call setline(lnr,strpart(str,0,lcol).a:word.strpart(str,lcol))
	exec 'normal '.strlen(a:word).'l'
endf "}}}2
func! VjdePreviewKeyPress(k) "{{{2
	"let s:beginning .= a:k
	if a:k != "Backspace"
		let s:key_preview .= a:k
	elseif strlen(s:key_preview)>0
		let s:key_preview = strpart(s:key_preview,0,strlen(s:key_preview)-1)
	endif
	call s:VjdeUpdatePreviewBuffer(s:beginning.s:key_preview)
endf "}}}2
func! VjdeShowJavadoc() "{{{2
	if !has('ruby')
		return
	endif
    if bufname("%")!="Vjde_preview"
	    return
    endif
    let lnr = line('.')
    if lnr < 2
	    return
    endif
    let fname=g:vjde_javadoc_path.substitute(substitute(getline(1),'^\([^:]\+\):.*$','\1',''),'\.','/','g').'.html'
    let funname=substitute(getline(lnr),'^[^ \t]\+\s\([^)]\+[)]\|[^(;]\+\).*$','\1','')
ruby<<EOF
lnr = VIM::evaluate("lnr").to_i
$vjde_doc_reader.read(VIM::evaluate("fname"),VIM::evaluate("funname"))
VIM::Buffer.current.append(lnr,"**")
lnr += 1
$vjde_doc_reader.to_text_arr.each { |l|
	l[-1]=''
	VIM::Buffer.current.append(lnr," * #{l}")
	lnr +=1
}
VIM::Buffer.current.append(lnr," *")
EOF
endf "}}}2
func! VjdeGetPreviewWindowBuffer() "{{{2
	let l:b_n = -1
	if &pvw
		let l:b_n = bufnr("%")
		if bufname("%")!= 'Vjde_preview'
			let l:b_n = -1
		end
		return  l:b_n
	end
	silent! wincmd P
	if !&pvw
		exec 'silent! bel '.&pvh.'sp Vjde_preview'
		call s:VjdePreviewWindowInit()
		let l:b_n = bufnr("%")
		"setlocal noma
	else
		let l:b_n = bufnr("%")
		if bufname("%")!= 'Vjde_preview'
			let l:b_n = -1
		end
	end
	silent! wincmd p
	return l:b_n
endf "}}}2
func! VjdeJavaPreview(char) "{{{2
	if strlen(&cfu)<=0
		return 
	endif
	let Cfufun = function(&cfu)
	let show_prev_old = g:vjde_show_preview
	let g:vjde_show_preview=1
	let linestr= getline(line('.'))
	let cnr = col('.')
	let s:preview_buffer=[]
	let s = Cfufun(linestr,'',cnr,1)
	let mretstr=Cfufun(linestr,strpart(linestr,s,cnr-s),cnr,0)
	let g:vjde_show_preview=show_prev_old

        if mretstr!=""
	    let s:beginning=strpart(linestr,s,cnr-s)
	    if len(s:preview_buffer)==2  " only one 
		    let word = mretstr[0:-2]
		    call s:VjdeInsertWord(strpart(word,strlen(s:beginning)))
		    return
	    endif
	    if g:vjde_preview_gui && g:vjde_preview_lib!=''
		    let useshort = 0
		    if &cfu=='VjdeCompletionFun' && (s:cfu_type==1 || s:cfu_type==4 )
			    let useshort=1
		    endif
		    let word = VjdeCallPreviewWindow(s:beginning,useshort)
		    if strlen(word)>0
			    call s:VjdeInsertWord(word)
		    endif
	    else
		    let s:key_preview=''
		    call s:VjdeUpdatePreviewBuffer(s:beginning)
		    call VjdeGetPreviewWindowBuffer()
		    wincmd P
		    if &pvw
			    let s:key_preview=''
			    exec 'silent! normal $'
		    end
	    endif
        endif
endf "}}}2
func! VjdeCallPreviewWindow(base,useshort) "{{{2
	let pos = VjdeGetCaretPos()
	"let x = winline()
	"let y = wincol()
	let x = pos[0]
	let y = pos[1]
	let tw = &columns
	let th = &lines
	let width=g:vjde_preview_gui_width
	let height= g:vjde_preview_gui_height
	let str = VjdePreviewGetLines()
	let cmdline = y.';'.x.';'.tw.";".th.";".width.';'.height.';'
	let cmdline .= getwinposx().';'.getwinposy().';'
	let cmdline .= a:useshort.';'.a:base.";\n".str
	let cstr = libcall(g:vjde_preview_lib,'_Z7previewPc',cmdline)
	let cstr = substitute(cstr,'\([^(;]\+\)[(;].*$','\1','')
	return strpart(cstr,strlen(a:base))
endf "}}}
func! VjdeGetCaretPos() "{{{2 
	let cols = wincol()
	let lines = winline()
	let cnr = winnr()

	let oei = &ei
	set ei=WinEnter,WinLeave,BufEnter,BufLeave

	let wcount = 0
	wincmd  h
	let prenr = cnr
	let lastnr = winnr()
	while prenr != lastnr
		let wcount +=1
		let cols += winwidth(0)+1
		let prenr = lastnr
		wincmd h
		let lastnr = winnr()
	endw
	if wcount >0
		exec wcount.'wincmd l'
	endif
	
	let wcount = 0
	wincmd k
	let prenr = cnr
	let lastnr = winnr()
	while prenr != lastnr
		let wcount +=1
		let lines += winheight(0)+1
		let prenr = lastnr
		wincmd k
		let lastnr = winnr()
	endw
	if wcount > 0
		exec wcount.'wincmd j'
	endif
	exec 'set ei='.oei
	return [cols,lines]
endf "}}}2
func! VjdeJavaParameterPreview() "{{{2
	let show_prev_old = g:vjde_show_preview
	let g:vjde_show_preview=1
	call s:VjdeInfo(1) " call vjdei, not show the infomation
	call s:VjdeShowParameterInPreview()
	let g:vjde_show_preview=show_prev_old
endf "}}}2
func! s:VjdeShowParameterInPreview() "{{{2
   let prev = 1
   let bufnr = -1

   let prenr = VjdeGetPreviewWindowBuffer()
   if prenr==-1
	   return
   endif
   if prenr !=bufnr('%')
	   silent! wincmd P
   endif
   exec '0,$d'
   if g:vjde_java_cfu.success
	   if strlen(s:beginning)>0
		for method in g:vjde_java_cfu.class.SearchMethods('method.name=="'.s:beginning.'"')
			call append('$',method.ToString())
		endfor
	   else
		   for constructor in g:vjde_java_cfu.class.constructors
			   call append('$',constructor.ToString())
		   endfor
	   endif
   endif
   silent! wincmd p
endf "}}}2
func! s:VjdeGeneratePreviewBuffer(base) "{{{2
	if g:vjde_java_cfu.success
		call add(s:preview_buffer,g:vjde_java_cfu.class.name.':')
	    if strlen(a:base)==0
		    for member in g:vjde_java_cfu.class.members
			    call add(s:preview_buffer,member.type.' '.member.name.';')
		    endfor
		    for method in g:vjde_java_cfu.class.methods
			    call add(s:preview_buffer,method.ToString())
		    endfor
	    else
		    for member in g:vjde_java_cfu.class.SearchMembers('stridx(member.name,"'.a:base.'")==0')
			    call add(s:preview_buffer,member.type.' '.member.name.';'
		    endfor
		    for method in g:vjde_java_cfu.class.SearchMethods('stridx(method.name,"'.a:base.'")==0')
			    call add(s:preview_buffer,method.ToString())
		    endfor
	    endif
	endif
	return
endf "}}}2
func! VjdeUpdatePreview(base) "{{{2
	call s:VjdeUpdatePreviewBuffer(a:base)
endf
"a:1 beforeenter a:2 afterenter a:3 beforeleave a:4 afterleave
func! s:VjdeUpdatePreviewBuffer(base,...) "{{{2
    if len(s:preview_buffer)==0
	return 
    endif
    let prenr = VjdeGetPreviewWindowBuffer()
    let thesame = 1
    if prenr ==-1
        return
    endif
    if prenr != bufnr("%")
        if a:0>=1 && type(a:1)==2 
            call a:1()
        endif
        silent! wincmd P
        if a:0>=2 && type(a:2)==2 
            call a:2()
        endif
	let thesame = 0
    endif
    exec '1,$d'
    exec 'setlocal statusline=%t\ %w\ :%1*'.substitute(a:base,'%','%%','').'\|%0*'
    if ( prenr == bufnr("%"))
        if strlen(a:base)>0 
            call append(1,filter(copy(s:preview_buffer),'v:val =~ ''^[^ \t]\+\s'.a:base.'.*$'''))
            exec 'match Tag /\s'.a:base.'/' 
        else 
            call append(0,s:preview_buffer)
            match none
        end
        call setline(1,s:preview_buffer[0].a:base)
    endif
    call cursor(1,col('$'))
    if !thesame
        if a:0>=3 && type(a:3)==2 
            call a:3()
        endif
        silent! wincmd p
        if a:0>=4 && type(a:4)==2 
            call a:4()
        endif
    endif
endf
func! VjdePreviewGetLines() "{{{2
	return join(s:preview_buffer,"\n")
endf "}}}
 "{{{2
command! -nargs=0 Vjdei call  s:VjdeInfomation()  
command! -nargs=0 Vjdegd call  s:VjdeGotoDecl()  
"command! -nargs=+ Vjdetld echo s:VjdeTaglibCompletionFun(<f-args>) 
"command! -nargs=1 Vjdeft echo s:VjdeFormatLine(<f-args>)  

"command! -nargs=0 Vjdetest  call s:VjdeObejectSplit(s:VjdeFormatLine(getline(line('.'))).'.') <BAR> echo s:types <BAR> echo s:VjdeFormatLine(getline(line('.'))).'.wfc'
"command! -nargs=0 Vjdetest1  echo s:VjdeFormatLine(getline(line('.')))

"command! -nargs=1 Vjdedef echo s:GettypeName(<f-args>)  
"command! -nargs=0 VjdeXML echo s:VjdeFindUnendElement(line('.'),col('.'))  

command! -nargs=0 Vjdetest echo s:GetJspImportStr()


"   vim600:fdm=marker:ff=unix


" Liscnece info
 

" Define shell names for filetypes. Order sets the priority
let s:shell = { 'python' : ['ipython', 'python'], 'javascript': ['node'] }

" TODO: scope to script
function! SafeOpenTerm(mods)
	let term_bufnr = -1
	let shells = ['']
	 
	" Use default if can't guess
	if has_key(s:shell, &filetype) == 0
		return PrivateOpenTerminal('', a:mods)
	endif

	for shell in get(s:shell, &filetype, ['']) 
		if executable(shell) > 0
			return PrivateOpenTerminal(shell, a:mods)
		endif
	endfor
	 
	echom "Failed to find suitable terminal from: " . join(shells, ", ")
	return term_bufnr
endfunction

" Sends the currently selected visual selection to the terminal
function! RunCell(startline, endline)
	" 0. Check if shell bufer open, if not open one
	" if multiple shells open → error message
	let term_bufnr = bufnr("notebookterm-")
	if term_bufnr ==# -1
		let term_bufnr = SafeOpenTerm('')
	endif

	" 1. Get range of text to send to terminal
	let raw = join(getline(a:startline, a:endline), "\n") . "\n"

	" 2. Copy text in selected range to variable
	" How to stop text appearing before shell loads ?
	" TODO: Check if terminal is in INSERT mode, if not, make it
	call term_sendkeys(term_bufnr, raw)
	call term_wait(term_bufnr)
	normal j
endfunction

command -range RunCell call RunCell("<line1>", "<line2>")
nnoremap <Leader>r :RunCell "<CR>
vnoremap <Leader>r :RunCell "<CR>

" Have to check that `shell` exists first because even if `bash` 
" doesn't exist it will open a terminal and use it as a command.
" In this case, the terminal will exist and will get a buffer.
" TODO: Scope to script
function! PrivateOpenTerminal(shell, mods)
	let mods = split(a:mods)

	let horisontal_split = 1
	for mod in mods
		if mod ==? 'vertical'
			let horisontal_split = 0
		endif
	endfor

	" Work out terminal command
	let term_cmd = " belowright terminal ++close "
	if horisontal_split
		let term_cmd = term_cmd . "++rows=15 "
	endif

	" open shell
	execute a:mods . term_cmd . a:shell 
	" Set buffer name so we can find it again
	let bufname = "notebookterm-" . a:shell
	execute "file! " . bufname
	" Jump back to previous split
	execute "normal! \<C-w>p"  
	"return bufnr("$")
	return bufnr(bufname) " -1 if not. (this never happens unfortunately)
endfunction

function! OpenTerminal(shell, mods)
	let term_bufnr = -1
	if a:shell !=# '' && executable(a:shell) < 1
		echom "Failed to find shell: " . a:shell
		return term_bufnr
	endif

	" Close existing terminals before opening a new one.
	let term_bufnr = bufnr("notebookterm-")
	if term_bufnr >= 0
		execute "bdelete! " . term_bufnr
	endif

	return PrivateOpenTerminal(a:shell, a:mods)
endfunction

command -nargs=? OpenTerminal call OpenTerminal(<q-args>, <q-mods>)

" TODO:
"  - Scope functions to local or plugin
"  - Make `RunCell` put the terminal into insert mode before executing code

" Extension bits
" - detect shell type from code (first filetype setting then maybe advanced
"   analysis?!)


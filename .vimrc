" To use this code specify the following in ~/.vimrc:
"
"  set exrc
"  set secure
"
" 'set exrc' will enable support for per-project .vimrc.
" 'set secure' will ensure we don't execute autocmd, shell, or write commands
" unless owned by you.
"
" Alternatively, copy this code into your ~/.vimrc.
"
" Ensure license information is added to new Ruby files.
augroup ruby_files
    au BufNewFile *.rb 0r .vim/skeleton/license.skel
augroup end

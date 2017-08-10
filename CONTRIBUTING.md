# Contributing to `chef-ramsay`

At the moment, the requirements for contributing to `chef-ramsay` are simple
and straightfoward:

1. Fork the repo.
2. Checkout a new branch.
3. Open a pull request.

## Licensing

To ensure consistency, all code needs to contain the license header. For
convenience, the header can be found at [.vim/skeleton/license.skel](/.vim/skeleton/license.skel).
For even more convenience, and if one uses `vim`, one can use the code in
[.vimrc](/.vimrc) at the root of this project. It will ensure that any new
files (with the extension `.rb`) will receive the license header.

To use the `.vimrc` file in this repo, one needs to specify the following in
`~/.vimrc`:

```
  set exrc
  set secure
```

`set exrc` will enable support for per-project `.vimrc` meaning `vim` will find
and use the `.vimrc` in this repo.

`set secure` will ensure `vim` doesn't execute autocmd, shell, or write commands
 unless owned by you.

 Alternatively, be diligent about copying the license header into new files.

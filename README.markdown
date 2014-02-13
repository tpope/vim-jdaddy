# jdaddy.vim

Check out these **must have** mappings for working with JSON in Vim:

* `aj` provides a text object for the outermost JSON object, array, string,
  number, or keyword.
* `gqaj` "pretty prints" (wraps/indents/sorts keys/otherwise cleans up) the
  JSON construct under the cursor.
* `gwaj` takes the JSON object on the clipboard and extends it into the JSON
  object under the cursor.

There are also `ij` variants that target innermost rather than outermost JSON
construct.

## Installation

If you don't have a preferred installation method, I recommend
installing [pathogen.vim](https://github.com/tpope/vim-pathogen), and
then simply copy and paste:

    cd ~/.vim/bundle
    git clone git://github.com/tpope/vim-jdaddy.git

## Self-Promotion

Like jdaddy.vim?  Follow the repository on
[GitHub](https://github.com/tpope/vim-jdaddy) and vote for it on
[vim.org](http://www.vim.org/scripts/script.php?script_id=4863).  And if
you're feeling especially charitable, follow [tpope](http://tpo.pe/) on
[Twitter](http://twitter.com/tpope) and
[GitHub](https://github.com/tpope).

## License

Copyright © Tim Pope.  Distributed under the same terms as Vim itself.
See `:help license`.

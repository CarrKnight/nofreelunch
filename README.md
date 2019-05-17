Quick Summary
=============

In the `setup.R` file are all the code that estimate parameters and cross-validates their quality. It is mostly just a bunch of functions that call better packages in a uniform way.

All the estimation examples are in separate `RMarkdown` files. Whenever called they produce html files that are relatively easy to look at and store all their estimations in the `errors`,`contained` and `intervals` folders.

The paper itself is the `nofreelunch.Rmd` file, and it reads from those folders to write the tables. That's it.



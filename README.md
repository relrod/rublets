Rublets
=======

Rublets is an IRC bot in ruby which uses tsion's *on_irc* library, with a small collection of other rubygems, to provide a safe general-purpose code-evaluation IRC bot.

How It Works
------------

Rublets takes advantage of an SELinux feature called *sandboxing*. On any Linux system with SELinux, you can run the `sandbox` command to safely evaluate commands without risk of harming the computer. Rublets, by default, stores its sandbox data in ~/.rublets/ of whichever user it runs as.

When Rublets is asked to evaluate ruby, it does the following:

1. Write the code to a file that the sandboxed ruby can access.
2. Write the code to a file that can not be reached by the sandbox, for audit purposes.
3. Ask the sandbox to evaluate the code using `ruby`.
4. Remove the sandbox-accessible code.

Setting up rubies
-----------------

Rublets uses RVM so that it can evaluate multiple ruby versions/implementations. Setting up RVM for use with Rublets is a bit tricky.

Set up RVM as your regular user with however many rubies you want, then from the rublets directory, run `./setup-rvm.sh`

What it can evaluate (if given selinux permissions, and if the interpreters/compilers are installed) in no particular order:
----------------------------------------------------------------------------------------------------------------------------

* [Ruby](http://www.ruby-lang.org)
* [Python](http://www.python.org) (only one line though - seems pointless)
* [Perl](http://www.perl.org)
* [Scala](http://www.scala-lang.org)
* [JavaScript](https://developer.mozilla.org/en/JavaScript)
* [Lua](http://lua.org)
* [Haskell](http://haskell.org)
* [OCaml](http://caml.inria.fr/)
* [Forth](https://www.gnu.org/software/gforth/)
* [C](http://gcc.gnu.org/)
* [C++](http://gcc.gnu.org/)
* [Objective C](http://gcc.gnu.org/)
* [Bash](https://www.gnu.org/software/bash/)
* [Erlang](http://erlang.org)
* [Io](http://iolanguage.com)
* [PHP](http://php.net)
* [Perpetual](https://github.com/programble/perpetual)
* Common Lisp ([sbcl](http://sbcl.org))

Config
------

Rublets uses @programble's Configru gem interally. All this means for you, the user, is that you need to copy rublets.yml.dist to rublets.yml, edit it, and be on your way.

Contributions
-------------

Contributions are gladly accepted. Please run the specs and ensure they pass.

License
-------

The original project (duckinator/rubino) from which Rublets was forked, was ISC.
However, most if not all of the original code has been greatly modified or removed.
With permission from @duckinator for anything I am missing, that is still original,
I am releasing this project as GPLv2+, as of the commit in which this text appears.

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

Setting up languages
--------------------

Rublets uses RVM so that it can evaluate multiple ruby versions/implementations. Setting up RVM for use with Rublets is a bit tricky.

Set up RVM as your regular user with however many rubies you want, and ensure it is in $PATH.

All other languages can be evaluated by making sure their interpreters are installed and in $PATH.

The bot has only been tested on Fedora Rawhide, but in theory, should work elsewhere.

Dependencies
------------

We depend on @programble's [forklimit](https://github.com/programble/forklimit) library. Have it in
your LD path installed as forklimit.so.0. For CentOS and Fedora, this is available in the
[eval.so yum repo](https://github.com/eval-so/infrastructure/wiki/Yum-Repo).

Commands
--------

* `![language]> [code]` - (example: `!perl> print 1;`) - Evaluate code
* `!version [language]` - (example: `!version php`) - Return the version of the package that provides PHP.
* `!>> [ruby code]` - (example: `!>> puts "hello!"`) - Shortcut for Ruby evaluations
* `!languages` or `!langs` - List all languages that Rublets knows about
* `!rubies` - List all RVM rubies that Rublets can see

What it can evaluate (if given selinux permissions, and if the interpreters/compilers are installed):
-----------------------------------------------------------------------------------------------------


<table>
<tr>
  <td>Shells</td>
  <td>
    <a href="https://www.gnu.org/software/bash/">Bash</a>
    <a href="http://www.zsh.org/">Zsh</a>
  </td>
</tr>
<tr>
  <td>C-like</td>
  <td>
    <a href="http://gcc.gnu.org/">C</a>
    <a href="http://gcc.gnu.org/">C++</a>
    <a href="http://www.golang.org/">Go</a>
    <a href="http://gcc.gnu.org/">Objective-C</a>
  </td>
</tr>
<tr>
  <td>Lisps</td>
  <td>
    <a href="https://github.com/programble/apricot">Apricot</a>
    <a href="http://clojure.org/">Clojure</a>
    <a href="http://www.clisp.org/">CLISP</a>
    <a href="https://github.com/programble/perpetual">Perpetual</a>
    <a href="http://racket-lang.org">Racket</a>
    <a href="https://en.wikipedia.org/wiki/Scheme_%28programming_language%29">Kawa Scheme</a>
    <a href="http://call-cc.org/">Chicken Scheme</a>
    <a href="http://sbcl.org">sbcl</a>
  </td>
</tr>
<tr>
  <td>Erlang VM</td>
  <td>
    <a href="http://elixir-lang.org">Elixir</a>
    <a href="http://erlang.org">Erlang</a>
  </td>
</tr>
<tr>
  <td>Stack-based</td>
  <td>
    <a href="http://factorcode.org/">Factor</a>
    <a href="https://www.gnu.org/software/gforth/">Forth</a>
  </td>
</tr>
<tr>
  <td>Functional</td>
  <td>
    <a href="http://haskell.org">Haskell</a>
    <a href="http://caml.inria.fr/">OCaml</a>
    <a href="http://smlnj.cs.uchicago.edu/">SML(/NJ)</a>
  </td>
</tr>
<tr>
  <td>Prototype-based</td>
  <td>
    <a href="http://iolanguage.com">Io</a>
    <a href="https://developer.mozilla.org/en/JavaScript">JavaScript</a>
    <a href="http://lua.org">Lua</a>
  </td>
</tr>
<tr>
  <td>Misc</td>
  <td>
    <a href="https://github.com/boredomist/arroyo">Arroyo</a>
    <a href="https://github.com/pocmo/Ruby-Brainfuck">Brainfuck</a>
    <a href="http://claylabs.com/clay/">Clay</a>
    <a href="https://futureboy.us/frinkdocs/">Frink (non-foss)</a>
    <a href="http://www.golfscript.com/golfscript/">Golfscript (no license)</a>
    <a href="http://www.jsoftware.com/">J</a>
    <a href="http://lolcode.com/">LOLCODE</a>
    <a href="http://maxima.sourceforge.net/">Maxima</a>
    <a href="http://ooc-lang.org/">OOC</a>
    <a href="http://www.freepascal.org/">Pascal</a>
    <a href="http://www.gprolog.org/">Prolog</a>
    <a href="http://smalltalk.gnu.org">Smalltalk</a>
    <a href="https://www.sqlite.org/">SQLite 3</a>
  </td>
</tr>
<tr>
  <td>Scripting</td>
  <td>
    <a href="https://github.com/programble/befrunge">Befunge</a>
    <a href="http://www.perl.org">Perl 5</a>
    <a href="http://perl6.org">Perl 6</a>
    <a href="http://php.net">PHP</a>
    <a href="http://www.python.org">Python</a>
    <a href="http://docs.python.org/release/3.2.3/whatsnew/index.html">Python 3</a>
    <a href="http://www.ruby-lang.org">Ruby</a>
    <a href="http://tcl.sourceforge.net/">TCL</a>
  </td>
</tr>
<tr>
  <td>JVM-based</td>
  <td>
    <a href="http://ceylon-lang.org/">Ceylon</a>
    <a href="http://clojure.org/">Clojure</a>
    <a href="http://groovy.codehaus.org/">Groovy</a>
    <a href="http://openjdk.java.net/">Java</a>
    <a href="http://www.scala-lang.org">Scala</a>
  </td>
</tr>
<tr>
  <td>.NET</td>
  <td>
    <a href="http://msdn.microsoft.com/en-us/vstudio/hh388566">C#</a>
    <a href="http://fsharp.org/">F#</a>
  </td>
</tr>
</table>

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

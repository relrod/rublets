Rublets
=======

Rublets is an IRC bot in ruby which uses tsion's *on_irc* library, with a small collection of other rubygems, to provide a safe ruby-evaluation IRC bot.

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

I hope to have a script that makes this process much easier in the future, but the gist of it is this:

1. Install rvm as your user, as if you were actually using RVM for regular use.
2. `rvm install 1.9.3` or whichever rubies you want Rublets to be able to evaluate.
3. `mv ~/.rvm ./rublets/rvm`
4. `mv ./rublets/rvm/rubies ./rublets/rubies`
5. `rm -rf ./rublets/rvm/gems ./rublets/rvm/archives ./rublets/rvm/src` # This saves a lot of space. The Rublets 'rvm' directory gets copied on each eval. Smaller = faster.

Contributions
-------------

Contributions are gladly accepted. Please run the specs and ensure they pass.

License
-------

As per the original project (duckinator/rubino) from which Rublets was forked, the code is ISC. Some portions of this project may one day be relicensed as GPLv2+.

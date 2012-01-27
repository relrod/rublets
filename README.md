Rublets
=======

Rublets is an IRC bot in ruby which uses tsion's *on_irc* library, with a small collection of other rubygems, to provide a safe ruby-evaluation IRC bot.

How It Works
------------

Rublets takes advantage of an SELinux feature called *sandboxing*. On any Linux system with SELinux, you can run the `sandbox` command to safely evaluate commands without risk of harming the computer. Rublets, by default, stores its sandbox data in ~/.rublets/ of whichever user it runs as.

Contributions
-------------

Contributions are gladly accepted. Please run the specs and ensure they pass.

License
-------

As per the original project (duckinator/rubino) from which Rublets was forked, the code is ISC. Some portions of this project may one day be relicensed as GPLv2+.

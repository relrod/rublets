USING: listener continuations kernel sequences prettyprint io ;
[ { } read-quot with-datastack ] with-interactive-vocabs
dup empty? [ drop ] [ "Stack: " write . ] if

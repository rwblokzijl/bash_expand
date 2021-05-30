# bash_expand

A preprocessor for config files

```
SYNOPSIS
        bash_expand [OPTION]... [input-file]...
        for full details on the input options see `man perl`

COMMON USAGE
        Basic input output:
            - bash_expand [input-file] > [output-file]
        Read from stdin
            - cat [input-file] | bash_expand > [output-file]
        Edit inplace
            - bash_expand -i [input-file]

DESCRIPTION
        bash_expand is a preprocessor for config files that allows the use of
        INLINE BASH COMMANDS in normal config files. It effectively is a turing
        complete preprocessor for config files. It performs the following to the
        input:
        1. Take everything _between_ {{  }} and apply bash expansion (using echo).
          Some uses:
            - {{$HOME}}
            - {{$(ls /some/dir)}}
        2. treat every _line_ that starts with a ; as a bash command
          Some uses:
            ; source some_script_that_sets_vars.sh
            ; export $VAR = $(command)
            ; if [[ -z $VAR ]]; then
                some config
            ; else
                some other config
            ; fi
            ;# this is a comment that always works, even in json files
        3. take every line that look like "; import <file>" and replace it with this
          script applied to that file. This also allows for recursion, so BE CAREFUL
          with your exit conditions. Too many levels of recursion can exhaust the
          script'\''s stack space, causing a segfault ;p
```

Example config file: https://github.com/rwblokzijl/i3/blob/master/i3_gen/i3.config/config.template

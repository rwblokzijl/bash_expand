#!/bin/bash
# Author: Wessel Blokzijl (https://github.com/rwblokzijl)

#                                 Usage:
if [[ $1 == "-h" || $1 == "--help" ]]; then
    echo \
'NAME
        bash_expand - a preprocessor for config files
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
          script'\''s stack space, causing a segfault ;p' && exit
fi

#                             How its done:
#
# We essentially turn the whole config into a script that echos the desired
# config and then run it in bash. To turn the config into valid bash script we
# use `sed` (actually perl) to turn every line of the $INPUT into an echo
# statement that prints the desired output line. Technically we use perl for
# substitutions, but these are effectively sed commands:

# this part would output the exact input file after running it through bash:
ESCAPE="s/'/'\\\''/g if /^[^;]/;"       # escape every ' to make the echo work
WRAP="s/^(.*)$/echo '\$1'/ if /^[^;]/;" # wrap normal lines in an echo '$LINE'
RESTORE_EMPTY="s/^$/echo ''/;"          # make sure empty lines aren't skipped

# Take import files and apply this script (recurse)
export BASH_EXPAND_COMMAND=$0
IMPORT='s/^\;\s*import\s*(.*)$/$ENV{BASH_EXPAND_COMMAND} $1/;'

# Remove the ; for bash lines
ADD_BASH='s/^\;\s*(.*)$/$1/;'

# apply some echo magic to all between {{ }}. The /g (greedy) at the end makes
# the regex stop matching at the first }} it finds. This allows us to expand
# multiple {{}}s per line (this is why we use perl instead of sed, as sed does
# not allow greedy matching)
EXPAND='s/{{\s*(.*?)\s*}}/'\''\$(echo '\''echo $1'\'' | bash)'\''/g;'

# apply alls substitutions, run through bash and output
perl -pe "${ESCAPE} ${WRAP} ${RESTORE_EMPTY} ${IMPORT} ${ADD_BASH} ${EXPAND}" $@ | bash


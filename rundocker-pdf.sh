#!/bin/bash

POSITIONAL=()

COMPILE_FOR_HUGO=false

while [[ $# -gt 0 ]] ; do
    key="$1"

    case $key in
        --hugo)
            COMPILE_FOR_HUGO=true
            shift
            ;;
        *)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

docker run --rm -v $PWD:/usr/share/blog meroff/hugo-with-pandoc:latest ./bin/compile-pdf.sh --hugo ${COMPILE_FOR_HUGO}

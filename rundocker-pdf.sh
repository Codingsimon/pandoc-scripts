#!/bin/bash

POSITIONAL=()

while [[ $# -gt 0 ]] ; do
    key="$1"

    case $key in
        --hugo)
            EXPORT_DIR="./"
            shift
            ;;
        *)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

docker run --rm -v $PWD:/usr/share/blog meroff/hugo-with-pandoc:latest ./bin/compile-pdf.sh ${EXPORT_DIR}

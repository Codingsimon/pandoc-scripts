#!/bin/bash
echo $1
docker run --rm -v $PWD:/usr/share/blog meroff/hugo-with-pandoc ./bin/compile-pdf.sh $1

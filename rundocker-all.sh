#!/bin/bash
docker run --rm -v $PWD:/usr/share/blog meroff/hugo-with-pandoc ./bin/compile-pdf.sh $1
docker run --rm -v $PWD:/usr/share/blog meroff/hugo-with-pandoc ./bin/compile-html.sh $1
#!/bin/bash
docker run --rm -v $PWD:/usr/share/blog meroff/hugo-with-pandoc:latest $1

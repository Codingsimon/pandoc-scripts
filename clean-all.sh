#! /bin/bash
find -type f -name "*.sh" -exec chmod 755 {} \;
find . -name "tex2pdf*" -type d -prune -exec rm -rf '{}' '+'
find -type f -name "TEMP*" -exec rm {} \;
find -type f -name "start.sh" -exec rm {} \;
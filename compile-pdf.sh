#!/bin/bash

pwd

# Einrichten einer Python Umgebung innerhalb des containers

python3 -m venv venv

# Aktivieren der Python Umgebung
source venv/bin/activate

# Installation der Requirements
# Hier können Python Pakete eingetragen werden die für Pandoc Filter benötigt werden

pip install -r .pandoc/requirements.txt --no-binary :all:

source bin/base.env

if [[ -e "settings.env" ]] ; then
source settings.env
fi

# Erstellen von Büchern (siehe README.md)
if [[ ${CREATE_AUTOMATIC_BOOKS} = true ]] ; then
    find . -maxdepth ${SEARCH_DEPTH} -name 'book*.sh' -print0 | xargs -0 -I{} -n1 -P${THREADS} /bin/bash -c './bin/make-files.sh --pdf --source "{}" '
      find . -maxdepth ${SEARCH_DEPTH} -name 'book*.sh' -print0 | xargs -0 -I{} -n1 -P${THREADS} /bin/bash -c 'echo --pdf --source "{}" '  
fi

if [[ ${CREATE_MANUAL_BOOKS} = true ]] ; then
    find . -maxdepth ${SEARCH_DEPTH} -name 'book*.txt' -print0 | xargs -0 -I{} -n1 -P${THREADS} /bin/bash -c './bin/make-files.sh --pdf --source "{}" '
fi

# Erstellen von PDFs pro Ordner
if [[ ${CREATE_SINGLE_PAGES} = true ]] ; then
    find . -maxdepth ${SEARCH_DEPTH} -type f -name "*${MARKDOWN_EXTENSION}" -not -name "_index${MARKDOWN_EXTENSION}" -print0 | xargs -0 -I{} -n1 -P${THREADS} /bin/bash -c './bin/make-files.sh --pdf --source "{}" '
fi

 

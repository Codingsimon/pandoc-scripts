#!/bin/bash
# Einrichten einer Python Umgebung innerhalb des containers

python3.6 -m venv venv

# Aktivieren der Python Umgebung
source venv/bin/activate

# Installation der Requirements
# Hier können Python Pakete eingetragen werden die für Pandoc Filter benötigt werden
pip install -r .pandoc/requirements.txt

find -type f -name "*.sh" -exec chmod 755 {} \;

find -type f -name "TEMP*" -exec rm {} \;

source bin/base.env
source .env

# Erstellen von Büchern (siehe README.md)
if [[ ${CREATE_AUTOMATIC_BOOKS} = true ]] ; then
find . -maxdepth ${SEARCH_DEPTH} -name 'book*.sh' -print0 | xargs -0 -I{} -n1 -P${THREADS} /bin/bash -c './bin/makepdf.sh --html --source "{}" --outdir '$1
fi

if [[ ${CREATE_MANUAL_BOOKS} = true ]] ; then
find . -maxdepth ${SEARCH_DEPTH} -name 'book*.txt' -print0 | xargs -0 -I{} -n1 -P12 /bin/bash -c './bin/makepdf.sh --html --source "{}" --outdir '$1
fi

# Erstellen von PDFs pro Ordner
if [[ ${CREATE_SINGLE_PAGES} = true ]] ; then
find . -maxdepth ${SEARCH_DEPTH} -type f -name "${MARKDOWN_FILENAME}${MARKDOWN_EXTENSION}" -print0 | xargs -0 -I{} -n1 -P12 /bin/bash -c './bin/makepdf.sh --html --source "{}" --outdir '$1
fi


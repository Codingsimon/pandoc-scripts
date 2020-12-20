#!/bin/bash

POSITIONAL=()

COMPILE_FOR_HUGO=false

while [[ $# -gt 0 ]] ; do
    key="$1"

    case $key in
        --hugo)
            COMPILE_FOR_HUGO=$2
            shift
            shift
            ;;
        *)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
    esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

# Einrichten einer Python Umgebung innerhalb des containers
apt-get -qq update && DEBIAN_FRONTEND=noninteractive && apt-get -qq install -y python3-venv python3-dev python3-wheel

python3 -m venv venv

# Aktivieren der Python Umgebung
source venv/bin/activate

# Installation der Requirements
# Hier können Python Pakete eingetragen werden die für Pandoc Filter benötigt werden
pip install wheel
pip install -r .pandoc/requirements.txt

bin/clean-all.sh

source bin/base.env

if [[ -e "settings.env" ]] ; then
source settings.env
fi

# Erstellen von Büchern (siehe README.md)
if [[ ${CREATE_AUTOMATIC_BOOKS} = true ]] ; then
    find . -maxdepth ${SEARCH_DEPTH} -name 'book*.sh' -print0 | xargs -0 -I{} -n1 -P${THREADS} /bin/bash -c './bin/make-files.sh --pdf --source "{}" --hugo '$COMPILE_FOR_HUGO
fi

if [[ ${CREATE_MANUAL_BOOKS} = true ]] ; then
    find . -maxdepth ${SEARCH_DEPTH} -name 'book*.txt' -print0 | xargs -0 -I{} -n1 -P${THREADS} /bin/bash -c './bin/make-files.sh --pdf --source "{}" --hugo '$COMPILE_FOR_HUGO
fi

# Erstellen von PDFs pro Ordner
if [[ ${CREATE_SINGLE_PAGES} = true ]] ; then
    find . -maxdepth ${SEARCH_DEPTH} -type f -name "*${MARKDOWN_EXTENSION}" -not -name "_index${MARKDOWN_EXTENSION}" -print0 | xargs -0 -I{} -n1 -P${THREADS} /bin/bash -c './bin/make-files.sh --pdf --source "{}" --hugo '$COMPILE_FOR_HUGO
fi


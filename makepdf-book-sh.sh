#!/bin/bash

## The following script is divided into two parts. 
## - create a PDF from multiple markdown files
## - create a PDF from a single markdown file

# Setup environment variables
source $(dirname "$0")/setup.sh $PWD $1 

# Change to the file directory
cd "$WORKING_DIR"

# Create temporary markdown file
if [[ ${BOOK} = true ]] ; then
    if [[ ${BOOK_FILETYPE} = BASH ]] ; then
        #[[ -e ${BASENAME}.pandoc ]] && echo ./${BASENAME}.pandoc > $FILENAME_TEMP.index
        export MARKDOWN_FILENAME
        export MARKDOWN_EXTENSION
        ./${BASENAME}.sh >> $FILENAME_TEMP.index
    else
        cat "${BASENAME}.txt" > $FILENAME_TEMP.index
    fi
    cat $FILENAME_TEMP.index
    # Combine files
    while read p; do
        SED_YAML_HEADER='/^---[[:space:]]*$/{x;s/^/x/;/x\{2\}/{x;q;};x;}'
        if [[ $p = "./_index${MARKDOWN_EXTENSION}" ]] ; then
            sed ${SED_YAML_HEADER} _index${MARKDOWN_EXTENSION} >> $FILENAME_TEMP
        else
            DIR=$(dirname "${p}")
            sed ${SED_YAML_HEADER} $p >> $FILENAME_TEMP
            if [[ ! $(basename "${p}") = "_"* ]] ; then
                echo "#" `sed ${SED_YAML_HEADER} $p | grep title | sed 's/^[^:]*:[[:space:]]*//'` >> $FILENAME_TEMP
                echo >> $FILENAME_TEMP
            fi
            awk "NR > `sed ${SED_YAML_HEADER} $p | wc -l` { print }" < $p | sed 's@\(!\[.*\]\)(\(.*\))\(.*\)@\1('"$DIR"'\/\2)\3@g' >> $FILENAME_TEMP
        fi
        printf "\n\n" >> $FILENAME_TEMP
    done < $FILENAME_TEMP.index
    
else
    cat ${BASENAME}${MARKDOWN_EXTENSION} > $FILENAME_TEMP
fi

if [[ $BOOK = true ]] ; then
    ## Settings applied when a book is detected (*.sh or *.txt as input)

    ## titlepage
    [[ -n ${BOOK_WITH_TITLEPAGE} ]] && COMMAND_TITLEPAGE="-V titlepage=${BOOK_WITH_TITLEPAGE}"

    ## table of ...
    [[ -n ${BOOK_WITH_TOC} ]] && COMMAND_TOC="-V toc=${BOOK_WITH_TOC}"
    [[ -n ${BOOK_WITH_LOT} ]] && COMMAND_LOT="-V lot=${BOOK_WITH_LOT}"
    [[ -n ${BOOK_WITH_LOF} ]] && COMMAND_LOF="-V lof=${BOOK_WITH_LOF}"

    ## onsided
    [[ -n ${BOOK_ONESIDE} ]] && COMMAND_LOF="-V classoption=oneside"
else
## Single Document Settings
    [[ -n ${SINGLE_TOC_ON_OWN_PAGE} ]] && COMMAND_TOC_ON_OWN_PAGE="-V toc-own-page=${SINGLE_TOC_ON_OWN_PAGE}"
    ## titlepage
    [[ -n ${SINGLE_WITH_TITLEPAGE} ]] && COMMAND_TITLEPAGE="-V titlepage=${SINGLE_WITH_TITLEPAGE}"

    ## table of ...
    [[ -n ${SINGLE_WITH_TOC} ]] && COMMAND_TOC="-V toc=${SINGLE_WITH_TOC}"
    [[ -n ${SINGLE_WITH_LOT} ]] && COMMAND_LOT="-V lot=${SINGLE_WITH_LOT}"
    [[ -n ${SINGLE_WITH_LOF} ]] && COMMAND_LOF="-V lof=${SINGLE_WITH_LOF}"
    FILTER_DEMOTE_HEADER="--filter demoteHeaders.hs"
fi

## pandoc-crossref
if [[ ${PANDOC_CROSSREF} = true ]] ; then
    if [[ -e "$BASE_DIR/$BIN_DIR/pandoc-crossref.yml" ]] ; then
        CROSSREF_PRESET_FILE="$BASE_DIR/$BIN_DIR/pandoc-crossref.yml"
    fi
    if [[ -e "$BASE_DIR/pandoc-crossref.yml" ]] ; then
        CROSSREF_PRESET_FILE="$BIN_DIR/pandoc-crossref.yml"
    fi
    if [[ -e "$WORKING_DIR/pandoc-crossref.yml" ]] ; then
        CROSSREF_PRESET_FILE="$BIN_DIR/pandoc-crossref.yml"
    fi
    COMMAND_CROSSREF="--filter pandoc-crossref -M crossrefYaml=${CROSSREF_PRESET_FILE}"
fi

## Listings
[[ ${USE_LISTINGS} = true ]] && COMMAND_LISTINGS="--listings -M listings=true"

## Links
[[ -n ${COLORLINKS} ]] && COMMAND_COLORLINKS="-V colorlinks=${COLORLINKS}"

if [[ ! -z $(grep "\chapter{.*}\|\part{.*}" "$FILENAME_TEMP") ]] ; then 
    COMMAND_BOOK="-V book"
fi

echo ${PANDOC_COMMAND} /usr/share/blog/titlepage.yml $FILENAME_TEMP -o "$BASENAME.pdf" -s \
    ${FILTER_DEMOTE_HEADER} \
    ${COMMAND_CROSSREF} \
    --template=${PANDOC_PDF_TEMPLATE} \
    ${COMMAND_BOOK} \
    ${COMMAND_TITLEPAGE} \
    ${COMMAND_TOC} \
    ${COMMAND_LOT} \
    ${COMMAND_LOF} \
    ${COMMAND_TOC_ON_OWN_PAGE} \
    ${COMMAND_LISTINGS} \
    ${COMMAND_COLORLINKS} \
    $CUSTOM \
    -V logo-jku=$BASE_DIR/.pandoc/templates/jku_de.pdf \
    -V logo-k=$BASE_DIR/.pandoc/templates/arr.pdf \
    -V img-cc=$BASE_DIR/.pandoc/templates/cc.png > start.sh 

cat start.sh

bash start.sh

$FILENAME_TEMP
rm start.sh
[[ -e $FILENAME_TEMP.index ]] && rm $FILENAME_TEMP.index
printf "%100s\n" |tr " " "!"
printf "%100s\n" |tr " " "!"

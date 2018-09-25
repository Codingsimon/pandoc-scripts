#!/bin/bash

## The following script is divided into two parts. 
## - create a HTML from multiple markdown files
## - create a HTML from a single markdown file

## read commonly used functions
. $(dirname "$0")/functions.sh

## sleep as it seems that the processes interfer if startet at the same time
sleep_one_second

# Setup environment variables
source $(dirname "$0")/setup.sh $PWD $1 

# Change to the file directory
cd "$WORKING_DIR"

# Create temporary markdown file
if [[ ${BOOK} = true ]] ; then
    if [[ ${BOOK_FILETYPE} = BASH ]] ; then
        export MARKDOWN_FILENAME
        export MARKDOWN_EXTENSION
        ./${BASENAME}.sh >> $FILENAME_TEMP.index
    else
        cat "${BASENAME}.txt" > $FILENAME_TEMP.index
    fi

    [[ ${DEBUG} = true ]] && cat $FILENAME_TEMP.index

    # Combine files
    while read p; do
        if [[ $p = "./_index${MARKDOWN_EXTENSION}" ]] ; then
            # first the frontmatter defined in the source file
            create_frontmatter "book"
        else
            DIR=$(dirname "${p}")
            # add a first level heading for content files
            if [[ ! $(basename "${p}") = "_"* ]] ; then
                echo "#" `sed ${SED_YAML_HEADER} $p | grep "title:" | sed 's/^[^:]*:[[:space:]]*//'` >> $FILENAME_TEMP
                print_empty_lines ${FILENAME_TEMP}
            fi
            # add the source file content without frontmatter
            LINES=$(sed ${SED_YAML_HEADER} ${p} | wc -l)
            awk "NR > $LINES" < $p | sed 's@\(!\[.*\]\)(\(.*\))\(.*\)@\1('"$DIR"'\/\2)\3@g' >> $FILENAME_TEMP
            print_empty_lines ${FILENAME_TEMP}
        fi
    done < $FILENAME_TEMP.index  
else
    create_frontmatter "single"
    LINES=$(sed ${SED_YAML_HEADER} ${BASENAME}${MARKDOWN_EXTENSION} | wc -l)
    awk "NR > $LINES { print }" < ${BASENAME}${MARKDOWN_EXTENSION} >> $FILENAME_TEMP
    print_empty_lines ${FILENAME_TEMP}
fi

###############################################################################
# Pandoc filter
###############################################################################
# demote headings if content file
if [[ ! $BOOK = true ]] ; then
    FILTER_DEMOTE_HEADER="--filter demoteHeaders.hs"
fi

## pandoc-crossref
## Improvement depending on language
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

# pandoc-citeproc
# TODO add CSL and options
if [[ ${PANDOC_CITEPROC} = true ]] ; then
    COMMAND_CITEPROC="--filter pandoc-citeproc"
fi

# qr code for youtube videos
[[ ${PANDOC_YOUTUBE_VIDEO_LINKS} = true ]] && COMMAND_YOUTUBE_FILTER="--filter pandoc-youtube-video-links.py"

## define output directory
OUTPUT_DIR="./"

if [[ $2 ]]; then
  OUTPUT_DIR="$BASE_DIR/$2/build/html/$WORKING_DIR"
  mkdir -p "$OUTPUT_DIR"
  if [[ ! $BOOK = true ]] ; then
    find . -type f -not -name "*${MARKDOWN_EXTENSION}" -exec cp '{}' $OUTPUT_DIR'/{}' ';'
  fi
fi

echo ${PANDOC_COMMAND} $FILENAME_TEMP -t html5 -o "$OUTPUT_DIR/$BASENAME.html" \
    ${FILTER_DEMOTE_HEADER} \
    ${COMMAND_CROSSREF} \
    ${COMMAND_CITEPROC} \
    ${COMMAND_YOUTUBE_FILTER} \
    ${COMMAND_LISTINGS} \
    ${CUSTOM} \
    ${CUSTOM_APPEND} > start.sh 

# cat start.sh

bash start.sh

# cleanup temporary files
rm $FILENAME_TEMP
rm start.sh
[[ -e $FILENAME_TEMP.index ]] && rm $FILENAME_TEMP.index
[[ ${DEBUG} = true ]] && printf "%100s\n" |tr " " "!"
[[ ${DEBUG} = true ]] && printf "%100s\n" |tr " " "!"

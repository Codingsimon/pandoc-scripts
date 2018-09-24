#!/bin/bash

## The following script is divided into two parts. 
## - create a PDF from multiple markdown files
## - create a PDF from a single markdown file
sleep `printf "0.%04d\n" $(( RANDOM % 10000 ))`
# Setup environment variables
source $(dirname "$0")/setup.sh $PWD $1 

# Change to the file directory
cd "$WORKING_DIR"

SED_YAML_HEADER='/---[[:space:]]*$/{x;s/^/x/;/x\{2\}/{x;q;};x;}'

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
    [[ ${DEBUG} = true ]] && cat $FILENAME_TEMP.index
    # Combine files
    while read p; do
        if [[ $p = "./_index${MARKDOWN_EXTENSION}" ]] ; then
            echo "---" >> $FILENAME_TEMP
            sed ${SED_YAML_HEADER} _index${MARKDOWN_EXTENSION} | sed  '1d;$d' >> $FILENAME_TEMP
            echo "---" >> $FILENAME_TEMP

            echo "---" >> $FILENAME_TEMP
            if [[ -e $BASE_DIR/settings-book.yml ]] ; then
                cat $BASE_DIR/settings-book.yml >> $FILENAME_TEMP
            fi
            echo "---" >> $FILENAME_TEMP

            echo "---" >> $FILENAME_TEMP
            if [[ -e $BASE_DIR/settings-general.yml ]] ; then
                cat $BASE_DIR/settings-general.yml >> $FILENAME_TEMP
            fi
            echo "---" >> $FILENAME_TEMP
            echo >> $FILENAME_TEMP
        else
            DIR=$(dirname "${p}")
            # sed ${SED_YAML_HEADER} $p >> $FILENAME_TEMP
            if [[ ! $(basename "${p}") = "_"* ]] ; then
                echo "#" `sed ${SED_YAML_HEADER} $p | grep "title:" | sed 's/^[^:]*:[[:space:]]*//'` >> $FILENAME_TEMP
                echo >> $FILENAME_TEMP
                echo >> $FILENAME_TEMP
            fi
            LINES=$(sed ${SED_YAML_HEADER} ${p} | wc -l)
            awk "NR > $LINES" < $p | sed 's@\(!\[.*\]\)(\(.*\))\(.*\)@\1('"$DIR"'\/\2)\3@g' >> $FILENAME_TEMP
            echo >> $FILENAME_TEMP
            echo >> $FILENAME_TEMP
        fi
    done < $FILENAME_TEMP.index  
else
    echo "---" >> $FILENAME_TEMP
    sed ${SED_YAML_HEADER} ${BASENAME}${MARKDOWN_EXTENSION} | sed  '1d;$d' >> $FILENAME_TEMP
    echo "---" >> $FILENAME_TEMP

    echo "---" >> $FILENAME_TEMP
    if [[ -e $BASE_DIR/settings-single.yml ]] ; then
        cat $BASE_DIR/settings-single.yml >> $FILENAME_TEMP
    fi
    echo "---" >> $FILENAME_TEMP

    echo "---" >> $FILENAME_TEMP
    if [[ -e $BASE_DIR/settings-general.yml ]] ; then
        cat $BASE_DIR/settings-general.yml >> $FILENAME_TEMP
    fi
    echo "---" >> $FILENAME_TEMP
    
    LINES=$(sed ${SED_YAML_HEADER} ${BASENAME}${MARKDOWN_EXTENSION} | wc -l)
    awk "NR > $LINES { print }" < ${BASENAME}${MARKDOWN_EXTENSION} >> $FILENAME_TEMP
    echo >> $FILENAME_TEMP
    echo >> $FILENAME_TEMP
fi

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

if [[ ${PANDOC_CITEPROC} = true ]] ; then
    COMMAND_CITEPROC="--filter pandoc-citeproc"
fi

## Listings
[[ ${USE_LISTINGS} = true ]] && COMMAND_LISTINGS="--listings -M listings=true"

## Better solution would be to convert to tex and check
if [[ ! -z $(grep "\chapter{.*}\|\part{.*}" "$FILENAME_TEMP") ]] ; then 
    COMMAND_BOOK="-V book"
fi

[[ -n ${DIVISION_LEVEL} ]] && COMMAND_TOP_LEVEL_DIVISION="--top-level-division=${DIVISION_LEVEL}"

[[ ${PANDOC_YOUTUBE_VIDEO_LINKS} = true ]] && COMMAND_YOUTUBE_FILTER="--filter pandoc-youtube-video-links.py"

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
    ${COMMAND_BOOK} \
    ${COMMAND_LISTINGS} \
    ${COMMAND_TOP_LEVEL_DIVISION} \
    ${CUSTOM} \
    ${CUSTOM_APPEND} \
    -V logo-jku=$BASE_DIR/.pandoc/templates/jku_de.pdf \
    -V logo-k=$BASE_DIR/.pandoc/templates/arr.pdf \
    -V img-cc=$BASE_DIR/.pandoc/templates/cc.png > start.sh 

# cat start.sh

bash start.sh

rm $FILENAME_TEMP
rm start.sh
[[ -e $FILENAME_TEMP.index ]] && rm $FILENAME_TEMP.index
[[ ${DEBUG} = true ]] && printf "%100s\n" |tr " " "!"
[[ ${DEBUG} = true ]] && printf "%100s\n" |tr " " "!"

#!/bin/bash

OUTPUT_DIR="build"

POSITIONAL=()

echo "POSITIONAL"
echo POSITIONAL

while [[ $# -gt 0 ]] ; do
    key="$1"
echo "caseBlock"
echo key

    case $key in
        -s|--source)
            SF="$2"
            shift # past argument
            shift # past value
            ;;
        --pdf)
            OUTPUT_FORMAT="pdf"
            shift
            ;;
        *)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
    esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ -z $OUTPUT_FORMAT ]] ; then 
    echo Es wurde kein Ausgabeformat übergeben
fi

## The following script is divided into two parts. 
## - create a PDF from multiple markdown files
## - create a PDF from a single markdown file

## read commonly used functions
. $(dirname "$0")/functions.sh

## sleep as it seems that the processes interfer if startet at the same time
sleep_one_second

# Setup environment variables
source $(dirname "$0")/setup.sh "$PWD" "$SF"

if [[ ${BASENAME} = "README" ]] ; then
	exit
fi

# Change to the file directory
cd "$WORKING_DIR"

# exit if file is found in .pandoc or bin
if [[ $WORKING_DIR =~ ".pandoc" || $WORKING_DIR =~ "bin" ]] ; then
    echo "found pandoc in .pandoc"
    exit;
fi

# Create temporary markdown file
if [[ ${BOOK} = true ]] ; then
    if [[ ${BOOK_FILETYPE} = BASH ]] ; then
        # file index is created by a bash file
        export MARKDOWN_FILENAME
        export MARKDOWN_EXTENSION
        ./${BASENAME}.sh > ${FILENAME_TEMP}.index
    else
        # file index is manually defined in a text file
        cat "${BASENAME}.txt" > ${FILENAME_TEMP}.index
    fi

    # remove README.md and all files found in .pandoc or bin
    cat ${FILENAME_TEMP}.index | grep -v "README.md" | grep -v "\/\.pandoc\/" | grep -v "\/\bin\/" > ${FILENAME_TEMP}_FIX.index
    mv ${FILENAME_TEMP}_FIX.index ${FILENAME_TEMP}.index

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
                echo "#" `sed ${SED_YAML_HEADER} "${p}" | grep "title:" | sed 's/^[^:]*:[[:space:]]*//'` >> $FILENAME_TEMP
                print_empty_lines ${FILENAME_TEMP}
            fi
            # add the source file content without frontmatter
            LINES=$(sed ${SED_YAML_HEADER} "${p}" | wc -l)
            awk "NR > $LINES" < "$p" | sed 's@\(!\[.*\]\)(\(.*\))\(.*\)@\1('"$DIR"'\/\2)\3@g' >> $FILENAME_TEMP
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
    if [[ -e ${BASE_DIR}/${CITEPROC_BIBLIOGRAPHY} && ${BIBLIOGRAPHY_BY_DIRECTORY} = false ]] ; then
        COMMAND_CITEPROC="${COMMAND_CITEPROC} -M bibliography=$BASE_DIR/${CITEPROC_BIBLIOGRAPHY} -M link-citations -M reference-section-title=Literaturverzeichnis"
    fi
    if [[ -n ${CITEPROC_STYLE} && -e ${BASE_DIR}/.pandoc/csl/${CITEPROC_STYLE} ]] ; then
        COMMAND_CITEPROC="${COMMAND_CITEPROC} --csl=${BASE_DIR}/.pandoc/csl/${CITEPROC_STYLE}"
    fi
fi

# qr code for youtube videos
[[ ${PANDOC_YOUTUBE_VIDEO_LINKS} = true ]] && COMMAND_YOUTUBE_FILTER="--filter pandoc-youtube-video-links.py"

[[ ${PANDOC_AWESOME_BOX} = true ]] && COMMAND_AWESOME_FILTER="--filter pandoc_alert_boxes.py"

if [[ $OUTPUT_FORMAT = "pdf" ]]; then
    ## Listings
    [[ ${USE_LISTINGS} = true ]] && COMMAND_LISTINGS="--listings -M listings=true"

    ## Better solution would be to convert to tex and check
    if [[ ! -z $(grep "\chapter{.*}\|\part{.*}" "$FILENAME_TEMP") ]] ; then 
        COMMAND_BOOK="-V book"
    fi

    ## change division level for content files if set
    [[ -n ${DIVISION_LEVEL} && ${BOOK} = true ]] && COMMAND_TOP_LEVEL_DIVISION="--top-level-division=${DIVISION_LEVEL}"

    TEMPLATE="--template=${PANDOC_PDF_TEMPLATE}"
fi

if [[ $OUTPUT_DIR = "." && $OUTPUT_FORMAT = "pdf" ]] ; then
    OUTPUT_DIR="$ORIGIN_DIR/${OUTPUT_DIR}/${OUTPUT_FORMAT}/$WORKING_DIR"
    ##OUTPUT_DIR="$ORIGIN_DIR/$WORKING_DIR"
    BASENAME=$(basename $WORKING_DIR)  
    echo Basename is now $BASENAME
else
    OUTPUT_DIR="$ORIGIN_DIR/${OUTPUT_DIR}/${OUTPUT_FORMAT}/$WORKING_DIR"
fi

mkdir -p "$OUTPUT_DIR"

if [[ $OUTPUT_FORMAT = "pdf" ]] ; then
    PANDOC_COMMAND="${PANDOC_COMMAND} --pdf-engine=xelatex -s"
fi

echo OUTPUT_FILE "$OUTPUT_DIR/$BASENAME.${OUTPUT_FORMAT}"

## define pandoc command
echo ${PANDOC_COMMAND} $FILENAME_TEMP -o \""$OUTPUT_DIR/$BASENAME.${OUTPUT_FORMAT}"\" \
    ${FILTER_DEMOTE_HEADER} \
    ${COMMAND_CROSSREF} \
    ${COMMAND_CITEPROC} \
    ${COMMAND_YOUTUBE_FILTER} \
    ${COMMAND_AWESOME_FILTER} \
    ${TEMPLATE} \
    ${COMMAND_BOOK} \
    ${COMMAND_LISTINGS} \
    ${COMMAND_TOP_LEVEL_DIVISION} \
    ${CUSTOM} \
    ${CUSTOM_APPEND} \
    -V logo-jku=$BASE_DIR/.pandoc/templates/jku_de.pdf \
    -V logo-k=$BASE_DIR/.pandoc/templates/arr.pdf \
    -V img-cc=$BASE_DIR/.pandoc/templates/cc.png > start.sh 
    
bash start.sh
echo Finish $BASENAME

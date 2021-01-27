#!/bin/bash

ORIGIN_DIR=$PWD

echo TEMPLATECHECK
echo $PANDOC_PDF_TEMPLATE

# Set source file and basename
SOURCE_FILE="$2" # relative file path
printf "%100s\n" |tr " " "="
printf "%-40s%s\n" "Source file:" ${SOURCE_FILE} 
printf "%100s\n" |tr " " "="

CHG_DIR=$(dirname "${SOURCE_FILE}")
cd "${CHG_DIR}"
# Set directory variables
BASE_DIR="$(git rev-parse --show-toplevel)" # working directory of the docker image (/usr/share/blog)
BIN_DIR=${BASE_DIR}/bin # relative path to the scripts directory (./bin)
WORKING_DIR=$(dirname "${SOURCE_FILE}") # relative direcrory of the current source file
cd -

[[ ${DEBUG} = true ]] && printf "%-40s%s\n" "[BASE_DIR]:" ${BASE_DIR}
[[ ${DEBUG} = true ]] && printf "%-40s%s\n" "[BIN_DIR]:" ${BIN_DIR}
[[ ${DEBUG} = true ]] && printf "%-40s%s\n" "[WORKING_DIR]:" ${WORKING_DIR}
[[ ${DEBUG} = true ]] && printf "%100s\n" |tr " " "="

# Read minimum base enviroment variables
if [[ -e ${BIN_DIR}/base.env ]]
then
    [[ ${DEBUG} = true ]] && printf "%-40s%s\n" "Read base enviroment file:" ${BIN_DIR}/base.env
    source ${BIN_DIR}/base.env
    [[ ${DEBUG} = true ]] && printf "%100s\n" |tr " " "="
else
    [[ ${DEBUG} = true ]] && echo Cannot find base environment file ${BIN_DIR}/base.env
    [[ ${DEBUG} = true ]] && printf "%100s\n" |tr " " "="
fi


# Read project environment variables
if [[ "-e ${BASE_DIR}/settings.env" ]]
then
    [[ ${DEBUG} = true ]] && printf "%-40s%s\n" "Read project enviroment file:" ${BASE_DIR}/settings.env
    source "${BASE_DIR}/settings.env"
    [[ ${DEBUG} = true ]] && printf "%100s\n" |tr " " "="
else
    [[ ${DEBUG} = true ]] && printf "%-40s%s\n" "No base environment file:" ${BASE_DIR}/settings.env
    [[ ${DEBUG} = true ]] && printf "%100s\n" |tr " " "="
fi

# Read working directory environment variables
if [[ -e "${WORKING_DIR}/settings.env" ]]
then
    [[ ${DEBUG} = true ]] && printf "%-40s%s\n" "Read working directory enviroment file:" ${WORKING_DIR}/settings.env
    source "${WORKING_DIR}/settings.env"
    [[ ${DEBUG} = true ]] && printf "%100s\n" |tr " " "="
else
    [[ ${DEBUG} = true ]] && printf "%-40s%s\n" "No working dir environment file:" ${WORKING_DIR}/settings.env
    [[ ${DEBUG} = true ]] && printf "%100s\n" |tr " " "="
fi

# Check the file typ of the source file
if [[ $2 =~ .sh || $2 =~ .txt ]] ; then
    if [[ $2 =~ .sh ]] ; then
        BASENAME=$(basename "${SOURCE_FILE}" .sh)
        BOOK_FILETYPE=BASH
    else
        BASENAME=$(basename "${SOURCE_FILE}" .txt)
        BOOK_FILETYPE=TEXT
    fi
    BOOK=true
else
    BASENAME=$(basename "${SOURCE_FILE}" ${MARKDOWN_EXTENSION})
    BOOK=false
fi

[[ ${DEBUG} = true ]] && printf "%-40s%s\n" "Basename:" ${BASENAME}
[[ ${DEBUG} = true ]] && printf "%100s\n" |tr " " "="

# Override with CI Parameters

if [[ -n ${GENERATE_QR_CODES} ]] ; then
    PANDOC_YOUTUBE_VIDEO_LINKS=${GENERATE_QR_CODES}
fi

if [[ ${GENERATE_QR_CODES} = true && ! ${CI_COMMIT_REF_NAME} = master ]] ; then
    PANDOC_YOUTUBE_VIDEO_LINKS=${GENERATE_QR_CODES_FOR_BRANCHES}
fi

# Temporary Filename
FILENAME_TEMP=TEMP_${BASENAME}${MARKDOWN_EXTENSION}
[[ ${DEBUG} = true ]] && printf "%-40s%s\n" "Temporary file:" ${FILENAME_TEMP}
[[ ${DEBUG} = true ]] && printf "%100s\n" |tr " " "="

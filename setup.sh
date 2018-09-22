#!/bin/bash

# Set source file and basename
SOURCE_FILE="$2"
printf "%100s\n" |tr " " "="
printf "%-40s%s\n" "Source file:" ${SOURCE_FILE} 
printf "%100s\n" |tr " " "="

# Set directory variables
BASE_DIR="$1"
BIN_DIR=$(dirname "$0")
WORKING_DIR=$(dirname "$2")

printf "%-40s%s\n" "[BASE_DIR]:" ${BASE_DIR}
printf "%-40s%s\n" "[BIN_DIR]:" ${BIN_DIR}
printf "%-40s%s\n" "[WORKING_DIR]:" ${WORKING_DIR}
printf "%100s\n" |tr " " "="

# Read minimum base enviroment variables
if [[ -e ${BIN_DIR}/base.env ]]
then
    printf "%-40s%s\n" "Read base enviroment file:" ${BIN_DIR}/base.env
    source ${BIN_DIR}/base.env
    printf "%100s\n" |tr " " "="
else
    echo Cannot find base environment file ${BIN_DIR}/base.env
    printf "%100s\n" |tr " " "="
fi

BOOK_FILETYPE=

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

printf "%-40s%s\n" "Basename:" ${BASENAME}
printf "%100s\n" |tr " " "="

# Read project environment variables
if [[ -e ${BASE_DIR}/.env ]]
then
    printf "%-40s%s\n" "Read project enviroment file:" ${BASE_DIR}/.env
    source ${BASE_DIR}/.env
    printf "%100s\n" |tr " " "="
else
    printf "%-40s%s\n" "No base environment file:" ${BASE_DIR}/.env
    printf "%100s\n" |tr " " "="
fi

# Read working directory environment variables
if [[ -e ${WORKING_DIR}/.env ]]
then
    printf "%-40s%s\n" "Read working directory enviroment file:" ${WORKING_DIR}/.env
    source ${WORKING_DIR}/.env
    printf "%100s\n" |tr " " "="
else
    printf "%-40s%s\n" "No working dir environment file:" ${WORKING_DIR}/.env
    printf "%100s\n" |tr " " "="
fi

# Temporary Filename
FILENAME_TEMP=TEMP_${BASENAME}${MARKDOWN_EXTENSION}
printf "%-40s%s\n" "Temporary file:" ${FILENAME_TEMP}
printf "%100s\n" |tr " " "="
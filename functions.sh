SED_YAML_HEADER='/---[[:space:]]*$/{x;s/^/x/;/x\{2\}/{x;q;};x;}'

sleep_one_second() {
    sleep `printf "0.%04d\n" $(( RANDOM % 10000 ))`
}

print_empty_lines() {
        echo testInFunctionClass
        echo $1
        cat $1
        echo testInFunctionClassEnd
      echo >> $1
      echo >> $1
}

copy_yaml() {
    SOURCE="$1"
    TARGET="$2"
    echo "---" >> ${TARGET}
    sed ${SED_YAML_HEADER} ${SOURCE} | sed  '1d;$d' >> ${TARGET}
    echo "---" >> ${TARGET}
}

create_frontmatter() {
    if [[ $1 = "book" ]] ; then
        copy_yaml "_index${MARKDOWN_EXTENSION}" ${FILENAME_TEMP}
    else
        copy_yaml "${BASENAME}${MARKDOWN_EXTENSION}" ${FILENAME_TEMP}
    fi
    # second the base settings for books
    if [[ -e $BASE_DIR/settings-book.yml ]] ; then
        copy_yaml "${BASE_DIR}/settings-${1}.yml" ${FILENAME_TEMP}
    fi
    # third the general settings
    if [[ -e $BASE_DIR/settings-general.yml ]] ; then
        copy_yaml "${BASE_DIR}/settings-general.yml" ${FILENAME_TEMP}
    fi
    
    print_empty_lines ${FILENAME_TEMP}
}

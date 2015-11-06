#!/usr/bin/env bash
#
# Defines transfer alias and provides easy command line file and folder sharing.


# modules
msu_require "console"
msu_require "core_utils"


function transfer() {
  # ensure we have `curl` installed
  has_command "curl" || {
    error "\`curl' could not be found"
    return 1
  }

  # check arguments
  if [ $# -eq 0 ]
  then
    echo " No arguments specified."
    echo -e " Usage:\n\techo transfer /tmp/test.md\n\tcat /tmp/test.md | transfer test.md"
    return 1
  fi

  # get temporarily filename, output is written to this file show progress can be showed
  tmpfile=$( mktemp -t transferXXX )

  # upload stdin or file
  file=$1

  if tty -s;
  then
    basefile=$(basename "$file" | sed -e 's/[^a-zA-Z0-9._-]/-/g')

    if [ ! -e $file ];
    then
      echo "File $file doesn't exists."
      return 1
    fi

    if [ -d $file ];
    then
      # zip directory and transfer
      zipfile=$( mktemp -t transferXXX.zip )
      cd $(dirname $file) && zip -r -q - $(basename $file) >> $zipfile
      curl --progress-bar --upload-file "$zipfile" "https://transfer.sh/$basefile.zip" >> $tmpfile
      rm -f $zipfile
    else
      # transfer file
      curl --progress-bar --upload-file "$file" "https://transfer.sh/$basefile" >> $tmpfile
    fi
  else
    # transfer pipe
    curl --progress-bar --upload-file "-" "https://transfer.sh/$file" >> $tmpfile
  fi

  # cat output link
  cat $tmpfile

  # cleanup
  rm -f $tmpfile
}


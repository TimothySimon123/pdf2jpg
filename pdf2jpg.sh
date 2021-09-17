#!/bin/bash

export TITLE="pdf2jpg"
export PDF2JPG_VERSION="alpha 1"

HERE="$(dirname "$(readlink -f "${0}")")"

if ! which bash > /dev/null ; then
    echo "Please install bash"
    exit 1
fi

if ! which yad > /dev/null ; then
    echo "Please install yad with the command"
    echo "sudo apt update && sudo apt install yad"
    exit 1
fi

if ! which pdftoppm > /dev/null ; then
    yad --image "info" --title "$TITLE" --text="Please install poppler-utils with the command\nsudo apt update && sudo apt install poppler-utils"
    exit 1
fi

# Remove the "file://" in front (Credit: http://smokey01.com/yad/)
# TODO: Support mtp:// , smb:// etc.,
filelist=$(yad --title="$TITLE" \
    --width=600 --height=400 \
    --text "Welcome to pdf2jpg version $PDF2JPG_VERSION\nPlease drag and drop the PDF files to convert" \
    --button=gtk-ok:0 \
    --dnd --cmd echo "$1" | sed 's/^file\:\/\///' )

# Accept only absolute paths
if [ -n "$(echo "$filelist" | sed '/^\//d')" ] ; then
    yad --image "info" --title "$TITLE" --text="Please select only valid files."
    exit 1
fi

if [ -z "$filelist" ] ; then
    yad --image "info" --title "$TITLE" --text="You have not selected any files.\nPlease run again."
    exit 1
fi

# If all files don't end with .pdf (case-insensitive)
if [ -n "$(echo "$filelist" | tr A-Z a-z | sed '/\.pdf$/d')" ] ; then
    yad --image "info" --title "$TITLE" --text="Please select only valid PDF files."
    exit 1
fi

dest_dir=$(yad --title="$TITLE" \
    --text="\nPlease select the destination folder\n" \
    --width=600 --height=400 \
    --file --directory)

dest_dir="$dest_dir"/pdf2jpg-converted-on-$(date +%F)-at-$(date +%I-%M-%S-%p)

if ! mkdir "$dest_dir" ; then
    yad --image "info" --title "$TITLE" --text="Please select a valid, writable folder."
    exit 1
fi

#TODO: script should close on pressing the cancel button on the progress bar
env filelist="$filelist" dest_dir="$dest_dir" "$HERE"/pdf2jpg-helper.sh | \
yad --title "$TITLE" --progress --width 360 \
    --text="Converting..... Please wait" \
    --percentage=0 \
    --auto-close --no-button

# Show message for success / failure
if [ -z "$PDFTOPPM_ERROR" ] ; then
    yad --image "info" --title "$TITLE" --text=$"Success - all the files have been converted.\n\n\
    Press OK to see them." && xdg-open "$dest_dir"
else
    yad --image "info" --title "$TITLE" --text="Error. Could not convert files"
    xdg-open "$dest_dir"
fi

exit 0

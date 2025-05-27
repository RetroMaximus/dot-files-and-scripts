# Function to recursively delete a directory and move it to a temporary RESTOREDIR location.
recursive_dir_del () {
    # Constants
    RESTOREDIR="$HOME/RESTOREDIR"
    RESTORELOCATION="$RESTOREDIR/RESTORELOCATION"

    # Ensure RESTOREDIR and RESTORELOCATION exist
    mkdir -p "$RESTOREDIR"
    touch "$RESTORELOCATION"

    # Parse flags and directory argument
    local PURGE=0
    local CONFIRM=0
    local DIR_PATH=""
    
    while getopts ":cp" opt; do
        case ${opt} in
            c ) CONFIRM=1
                ;;
            p ) PURGE=1
                ;;
            \? ) echo "Invalid option: -$OPTARG" 1>&2
                 return 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    DIR_PATH="$1"
    if [ -z "$DIR_PATH" ]; then
        echo "No directory specified."
        return 1
    fi
    
    
    # Build the full path
    if [[ "$1" != /* ]]; then
        DIR_PATH="$(pwd)/$1"
    else
        DIR_PATH="$1"
    fi

    # Function to recursively move files/directories to RESTOREDIR
    move_to_restore_dir() {
        local src="$1"
        local dest="$RESTOREDIR/$(basename "$src")"
        local skip=0

        if [ "$CONFIRM" -eq 1 ]; then
            for file in $(find "$src" -type f); do
                read -p "Are you sure you want to delete this file? ($file) [Y/S]: " response
                case "$response" in
                    [sS])
                        skip=1
                        echo "Skipped: $file"
                        ;;
                    [yY])
                        ;;
                    *)
                        echo "Invalid response. Skipping."
                        skip=1
                        ;;
                esac
            done
        fi

        if [ "$skip" -eq 0 ]; then
            mv "$src" "$RESTOREDIR/"
            echo "$DIR_PATH" > "$RESTORELOCATION"
            echo "Directory $src moved to $RESTOREDIR."
        else
            echo "Directory $src was not moved due to skipped files."
        fi
    }

    if [ ! -d "$DIR_PATH" ]; then
        echo "Specified directory does not exist."
        return 1
    fi

    # Purge RESTOREDIR contents if -p flag is set
    if [ "$PURGE" -eq 1 ]; then
        read -p "Are you sure you want to delete this directory and then purge RESTOREDIR? [y/N]: " response
        case "$response" in
            [yY])
		move_to_restore_dir "$DIR_PATH"
                find "$RESTOREDIR" -mindepth 1 -not -name "RESTORELOCATION" -exec rm -rf {} +
                echo "RESTOREDIR has been purged."
                ;;
            *) 
                echo "Purge cancelled."
                ;;
        esac
        return 0
    fi

    

    # Prompt the user if no flags are provided
    if [ "$CONFIRM" -eq 0 ]; then
        read -p "Are you sure you want to delete this directory? This will remove all of its sub-directories and contents. [Y/A]: " response
        case "$response" in
            [yY])
                move_to_restore_dir "$DIR_PATH"
                ;;
            [aA])
                echo "Operation aborted."
                return 0
                ;;
            *)
                echo "Invalid response. Operation aborted."
                return 1
                ;;
        esac
    else
        move_to_restore_dir "$DIR_PATH"
    fi
}

# Alias the function
alias redir=recursive_dir_del

# Function to undo the last directory deletion
redir_undo() {
    if [ ! -f "$RESTORELOCATION" ]; then
        echo "No directory to restore."
        return 1
    fi

    local restore_path=$(cat "$RESTORELOCATION")
    if [ -d "$RESTOREDIR/$(basename "$restore_path")" ]; then
        mv "$RESTOREDIR/$(basename "$restore_path")" "$restore_path"
        echo "Directory restored to $restore_path."
        > "$RESTORELOCATION"
    else
        echo "No directory found in RESTOREDIR to restore."
    fi
}

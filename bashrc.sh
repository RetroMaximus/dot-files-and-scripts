# There are a few files details in this document They should be placed where the dirctory is located inorder for term_type to work 
# These few scripts will prompt if the terminal should be a local terminal or should it try to connect via ssh based on the config settings



# ~/.config/terminal_type/tt_config.sh

#!/bin/bash
# Terminal Type Configuration

# SSH Connection Settings
SSH_USER=""
SSH_ADDRESS=""
SSH_AUTH_TYPE=""  # "password" or "key"
SSH_KEY_PATH=""

# Default selection (1: Local, 2: SSH)
DEFAULT_SELECTION="1"


# Sreamer Mode Config
STREAMER_MODE=true
STREAMER_MASK="dA"
IP_MASK="cAVe"

# set variable identifying the choort you work in (used in prompt below)
if [-z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set fancy prompt (non-color, unless we know we want color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for color prompt, if the terminal has capability; turned off by default
# force_color_prompt=yes

if [ -n "$force_color_prompt" ]: then
    if [ -x /usr/bn/tput ] && tput setaf 1 >&/dev/null: then
        color_prompt=yes
    else
        color_prompt=no
    fi
fi

if ["$color_prompt" = yes]; then
    if [ "$STREAMER_MODE" = true ]; then
        PS1='\[\033[01;32m\]${STREAMER_MASK}@${IP_MASK}:\[\033[01;34m\]\w[\033[00m\]\$ '
    else
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w[\033[00m\]\$ '
    fi
else
    if [ "$STREAMER_MODE" = true ]: then
        PS1='${STREAMER_MASK@$IP_MASK}:\w\$ '
    else
        PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
    fi
fi
unset color_prompt force_color_prompt

# if this is a xterm set the title to user@host:dir
case "$TERM" in 
    xterm*|rxvt*)
        if[ "STREAMER_MODE" = true ]; then
            PS1="\[\e]0;"$STREAMER_MASK"@"$IP_MASK": \w\a\]$PS1"
        else
            PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h:\w\a]$PS1"
        fi
        ;;
*)
        ;;
esac

alias set-streamer-mask='/usr/local/bin/assign-streamer-mask.sh'
alias set-ip-mask='/usr/local/bin/assign-ip-mask.sh'
alias set-streamer-mode='/usr/local/bin/assign-stramer-mode.sh'
alias show-streamer-status='usr/local/bin/show-streamer-mode-status.sh'


# ~/.config/terminal_type/tt_functions.sh

#!/bin/bash
# Terminal Type Functions – with multi‑profile support

# ----------------------------------------------------------------------
# 1. Profile management
# ----------------------------------------------------------------------

PROFILES_DIR="$HOME/.config/terminal_type/profiles"
DEFAULT_PROFILE_FILE="$HOME/.config/terminal_type/default_profile"
mkdir -p "$PROFILES_DIR"

# Migrate old config if it exists and has data
migrate_old_config() {
    local old_config="$HOME/.config/terminal_type/tt_config.sh"
    if [[ -f "$old_config" ]]; then
        # shellcheck source=/dev/null
        source "$old_config"
        if [[ -n "$SSH_USER" && -n "$SSH_ADDRESS" ]]; then
            local profile_name="default"
            if [[ ! -f "$PROFILES_DIR/$profile_name" ]]; then
                echo "Migrating old SSH configuration to profile '$profile_name'..."
                cat > "$PROFILES_DIR/$profile_name" << EOF
SSH_USER="$SSH_USER"
SSH_ADDRESS="$SSH_ADDRESS"
SSH_AUTH_TYPE="$SSH_AUTH_TYPE"
SSH_KEY_PATH="$SSH_KEY_PATH"
EOF
                echo "$profile_name" > "$DEFAULT_PROFILE_FILE"
                # Remove old config so it doesn't trigger again
                mv "$old_config" "$old_config.migrated"
                echo "Migration complete. Old config backed up as tt_config.sh.migrated"
            fi
        fi
    fi
}
migrate_old_config

# List available profiles
list_profiles() {
    local profiles=()
    local default=""
    if [[ -f "$DEFAULT_PROFILE_FILE" ]]; then
        default=$(cat "$DEFAULT_PROFILE_FILE")
    fi
    for f in "$PROFILES_DIR"/*; do
        if [[ -f "$f" ]]; then
            local name=$(basename "$f")
            profiles+=("$name")
        fi
    done
    if [[ ${#profiles[@]} -eq 0 ]]; then
        echo "No profiles found."
        return 1
    fi
    echo "Available SSH profiles:"
    local i=1
    for p in "${profiles[@]}"; do
        if [[ "$p" == "$default" ]]; then
            echo "  $i) $p (default)"
        else
            echo "  $i) $p"
        fi
        ((i++))
    done
    return 0
}

# Load a profile by name (sets SSH_USER, SSH_ADDRESS, etc.)
load_profile() {
    local profile_name="$1"
    if [[ -z "$profile_name" ]]; then
        echo "Error: no profile name provided."
        return 1
    fi
    local profile_file="$PROFILES_DIR/$profile_name"
    if [[ ! -f "$profile_file" ]]; then
        echo "Error: profile '$profile_name' not found."
        return 1
    fi
    # shellcheck source=/dev/null
    source "$profile_file"
    return 0
}

# Get the default profile name (if any)
get_default_profile() {
    if [[ -f "$DEFAULT_PROFILE_FILE" ]]; then
        cat "$DEFAULT_PROFILE_FILE"
    else
        echo ""
    fi
}

# Set default profile
set_default_profile() {
    local profile_name="$1"
    if [[ -z "$profile_name" ]]; then
        echo "Error: profile name required."
        return 1
    fi
    if [[ ! -f "$PROFILES_DIR/$profile_name" ]]; then
        echo "Error: profile '$profile_name' does not exist."
        return 1
    fi
    echo "$profile_name" > "$DEFAULT_PROFILE_FILE"
    echo "Default profile set to '$profile_name'."
}

# Add or edit a profile (interactive)
add_edit_profile() {
    local profile_name="$1"
    local is_edit=0
    if [[ -n "$profile_name" ]]; then
        if [[ ! -f "$PROFILES_DIR/$profile_name" ]]; then
            echo "Profile '$profile_name' does not exist. Creating new."
        else
            is_edit=1
            # Load existing values for editing
            # shellcheck source=/dev/null
            source "$PROFILES_DIR/$profile_name"
        fi
    else
        read -p "Enter profile name: " profile_name
        if [[ -z "$profile_name" ]]; then
            echo "Profile name cannot be empty."
            return 1
        fi
        if [[ -f "$PROFILES_DIR/$profile_name" ]]; then
            echo "Profile '$profile_name' already exists. Use edit to modify."
            return 1
        fi
    fi

    # Prompt for settings (with existing values as defaults)
    local user="${SSH_USER:-}"
    local addr="${SSH_ADDRESS:-}"
    local auth="${SSH_AUTH_TYPE:-password}"
    local keypath="${SSH_KEY_PATH:-}"

    read -p "SSH Username [${user}]: " input
    user="${input:-$user}"

    read -p "SSH Address (hostname/IP) [${addr}]: " input
    addr="${input:-$addr}"

    echo "Authentication method:"
    echo "1. Password"
    echo "2. SSH Key"
    local auth_choice
    read -p "Choice (default: ${auth}): " auth_choice
    if [[ -z "$auth_choice" ]]; then
        if [[ "$auth" == "key" ]]; then
            auth_choice=2
        else
            auth_choice=1
        fi
    fi
    case $auth_choice in
        1) auth="password"; keypath="" ;;
        2) auth="key"
            read -p "SSH Key path [${keypath:-~/.ssh/id_rsa}]: " input
            keypath="${input:-${keypath:-~/.ssh/id_rsa}}"
            ;;
        *) echo "Invalid choice"; return 1 ;;
    esac

    # Write profile
    cat > "$PROFILES_DIR/$profile_name" << EOF
SSH_USER="$user"
SSH_ADDRESS="$addr"
SSH_AUTH_TYPE="$auth"
SSH_KEY_PATH="$keypath"
EOF
    echo "Profile '$profile_name' saved."
}

# Delete a profile
delete_profile() {
    local profile_name="$1"
    if [[ -z "$profile_name" ]]; then
        read -p "Enter profile name to delete: " profile_name
        if [[ -z "$profile_name" ]]; then
            echo "Profile name required."
            return 1
        fi
    fi
    if [[ ! -f "$PROFILES_DIR/$profile_name" ]]; then
        echo "Profile '$profile_name' does not exist."
        return 1
    fi
    read -p "Are you sure you want to delete profile '$profile_name'? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm "$PROFILES_DIR/$profile_name"
        echo "Profile '$profile_name' deleted."
        # If it was default, clear default
        if [[ "$(get_default_profile)" == "$profile_name" ]]; then
            rm -f "$DEFAULT_PROFILE_FILE"
            echo "Default profile cleared."
        fi
    else
        echo "Deletion cancelled."
    fi
}

# ----------------------------------------------------------------------
# 2. Profile management menu
# ----------------------------------------------------------------------

configure_profiles() {
    while true; do
        echo
        echo "=== SSH Profile Management ==="
        echo "1. List profiles"
        echo "2. Add new profile"
        echo "3. Edit existing profile"
        echo "4. Delete profile"
        echo "5. Set default profile"
        echo "6. Back to main menu"
        read -p "Choice [1-6]: " choice

        case $choice in
            1)
                list_profiles
                ;;
            2)
                add_edit_profile ""
                ;;
            3)
                list_profiles
                read -p "Enter profile name to edit: " name
                if [[ -n "$name" ]]; then
                    add_edit_profile "$name"
                fi
                ;;
            4)
                list_profiles
                read -p "Enter profile name to delete: " name
                if [[ -n "$name" ]]; then
                    delete_profile "$name"
                fi
                ;;
            5)
                list_profiles
                read -p "Enter profile name to set as default: " name
                if [[ -n "$name" ]]; then
                    set_default_profile "$name"
                fi
                ;;
            6)
                return
                ;;
            *)
                echo "Invalid choice."
                ;;
        esac
    done
}
#
# SSH Key Manager
#

manage_ssh_keys() {
    # If an extended version is defined (from ssh_keys.sh), use it
    if declare -F ssh_key_management >/dev/null; then
        ssh_key_management
        return
    fi
    # Otherwise, use the built‑in menu
    while true; do
        echo
        echo "=== SSH Key Management ====================="
        echo "1. Generate new SSH key"
        echo "2. List existing keys"
        echo "3. Copy public key to clipboard"
        echo "4. Back to main menu"
        read -p "Choice [1-4]: " key_choice

        case $key_choice in
            1) generate_ssh_key ;;
            2) list_ssh_keys ;;
            3) copy_ssh_key ;;
            4) return ;;
            *) echo "Invalid choice" ;;
        esac
    done
}

# ----------------------------------------------------------------------
# 3. SSH connection (uses profile selection)
# ----------------------------------------------------------------------

# Select a profile interactively (returns the name, or empty if none)
select_profile_interactive() {
    local profiles_dir="${PROFILES_DIR:-$HOME/.config/terminal_type/profiles}"
    mkdir -p "$profiles_dir"

    # Collect all profile files (use ls, safe for filenames with spaces)
    local profiles=()
    while IFS= read -r file; do
        [[ -f "$profiles_dir/$file" ]] && profiles+=("$file")
    done < <(ls -1 "$profiles_dir" 2>/dev/null)

    if [[ ${#profiles[@]} -eq 0 ]]; then
        echo "No profiles available. Please create one via option 3." >&2
        return 1
    fi

    local default="$(get_default_profile)"

    # Everything that is just for display goes to stderr
    echo "Select a profile:" >&2
    local i=1
    for p in "${profiles[@]}"; do
        if [[ "$p" == "$default" ]]; then
            echo "  $i) $p (default)" >&2
        else
            echo "  $i) $p" >&2
        fi
        ((i++))
    done
    echo "  q) Cancel (return to main menu)" >&2

    read -p "Enter number or 'q': " sel
    if [[ "$sel" == "q" ]]; then
        return 1
    fi
    if [[ "$sel" =~ ^[0-9]+$ ]] && (( sel >= 1 && sel <= ${#profiles[@]} )); then
        # Only this line goes to stdout (so it can be captured)
        echo "${profiles[$((sel-1))]}"
        return 0
    else
        echo "Invalid selection." >&2
        return 1
    fi
}
# Connect to SSH using a profile.
# Usage: connect_ssh [profile_name]
#   - If profile_name is given, use that profile (no prompt).
#   - If no profile_name, always show interactive selection (even if default exists).
connect_ssh() {
    local profile_name="$1"
    if [[ -z "$profile_name" ]]; then
        # Always show the list when no profile is explicitly provided
        profile_name="$(select_profile_interactive)" || return 1
    fi
    # Load the profile
    if ! load_profile "$profile_name"; then
        return 1
    fi
    # Check credentials
    if [[ -z "$SSH_USER" || -z "$SSH_ADDRESS" ]]; then
        echo "Profile '$profile_name' is incomplete. Please edit it."
        return 1
    fi
    local ssh_command="ssh"
    if [[ "$SSH_AUTH_TYPE" == "key" && -n "$SSH_KEY_PATH" && -f "$SSH_KEY_PATH" ]]; then
        ssh_command+=" -i $SSH_KEY_PATH"
    elif [[ "$SSH_AUTH_TYPE" == "key" ]]; then
        echo "Warning: SSH_KEY_PATH not found or invalid. Trying without key."
    fi
    echo "Connecting to $SSH_USER@$SSH_ADDRESS using profile '$profile_name'..."
    $ssh_command "$SSH_USER@$SSH_ADDRESS"
}


# ----------------------------------------------------------------------
# 4. Main menu and handlers
# ----------------------------------------------------------------------

show_menu() {
    echo "=== Terminal Type Selection ================="
    echo "1. Local Terminal"
    echo "2. SSH Terminal (select profile)"
    echo "3. Configure SSH Profiles"
    echo "4. Manage SSH Keys"
    echo "============================================="
}

handle_menu_selection() {
    read -p "Select option [1-4] (default: $DEFAULT_SELECTION): " choice
    choice=${choice:-$DEFAULT_SELECTION}

    case $choice in
        1)
            echo "Local terminal selected."
            ;;
        2)
            connect_ssh
            if [[ $? -eq 0 ]]; then
                exit 0
            fi
            ;;
        3)
            configure_profiles
            show_menu
            handle_menu_selection
            ;;
        4)
            manage_ssh_keys
            show_menu
            handle_menu_selection
            ;;
        *)
            echo "Invalid selection."
            show_menu
            handle_menu_selection
            ;;
    esac
}

# ----------------------------------------------------------------------
# 5. Legacy compatibility (auto-connect modes)
# ----------------------------------------------------------------------

# For "auto-ssh" mode: use the default profile if set, otherwise fall back to interactive selection.
handle_auto_ssh() {
    local default="$(get_default_profile)"
    if [[ -n "$default" ]]; then
        connect_ssh "$default"
    else
        echo "No default profile set. Please choose one:"
        connect_ssh  # will show interactive list
    fi
    if [[ $? -eq 0 ]]; then
        exit 0
    fi
}


# ~/.config/terminal_type/ssh_keys.sh -----------------------------------------------------------

#!/bin/bash
# SSH Key Management Functions for Terminal Type Launcher

# Generate a new SSH key
generate_ssh_key() {
    read -p "Key name (default: id_rsa): " key_name
    key_name=${key_name:-id_rsa}
    read -p "Key directory (default: ~/.ssh/): " key_dir
    key_dir=${key_dir:-$HOME/.ssh}
    
    mkdir -p "$key_dir"
    ssh-keygen -t rsa -b 4096 -f "$key_dir/$key_name"
    echo "SSH key generated at: $key_dir/$key_name"
}

# List all SSH keys with fingerprints and permissions
list_ssh_keys() {
    echo "Available SSH keys:"
    local found=0
    for pubkey in ~/.ssh/*.pub; do
        [[ -f "$pubkey" ]] || continue
        found=1
        local privkey="${pubkey%.pub}"
        echo "Key: $(basename "$privkey")"
        echo "  Public: $pubkey"
        echo "  Private: $privkey"
        if [[ -f "$privkey" ]]; then
            echo "  Permissions: $(stat -c %a "$privkey" 2>/dev/null || stat -f %Lp "$privkey" 2>/dev/null)"
        fi
        echo "  Fingerprint: $(ssh-keygen -lf "$pubkey" | cut -d' ' -f2)"
        echo "---"
    done
    if [[ $found -eq 0 ]]; then
        echo "No SSH keys found in ~/.ssh/"
    fi
}

# Copy a public key to clipboard
copy_ssh_key() {
    read -p "Enter public key file path (or leave empty to list and choose): " key_file
    if [[ -z "$key_file" ]]; then
        echo "Available public keys:"
        select pub in ~/.ssh/*.pub; do
            if [[ -n "$pub" ]]; then
                key_file="$pub"
                break
            else
                echo "Invalid selection."
            fi
        done
    fi
    if [[ -n "$key_file" && -f "$key_file" ]]; then
        if command -v xclip >/dev/null 2>&1; then
            cat "$key_file" | xclip -selection clipboard
            echo "Key copied to clipboard (xclip)!"
        elif command -v pbcopy >/dev/null 2>&1; then
            cat "$key_file" | pbcopy
            echo "Key copied to clipboard (pbcopy)!"
        elif command -v clip.exe >/dev/null 2>&1; then
            cat "$key_file" | clip.exe
            echo "Key copied to clipboard (clip.exe)!"
        else
            echo "Clipboard utilities not found. Here's your key:"
            cat "$key_file"
        fi
    else
        echo "File not found: $key_file"
    fi
}

# View known_hosts entries
view_known_hosts() {
    local known_hosts="$HOME/.ssh/known_hosts"
    if [[ ! -f "$known_hosts" ]]; then
        echo "No known_hosts file found."
        return
    fi
    echo "Known hosts entries (hashed or plain):"
    nl -w2 -s'. ' "$known_hosts" | head -20
    local total=$(wc -l < "$known_hosts")
    if [[ $total -gt 20 ]]; then
        echo "... (total $total entries; use 'ssh-keygen -F hostname' to search)"
    fi
}

# Remove an entry from known_hosts
remove_known_host() {
    read -p "Enter hostname or IP to remove: " host
    if [[ -z "$host" ]]; then
        echo "Host required."
        return
    fi
    ssh-keygen -R "$host" 2>/dev/null
    echo "Removed entries for $host from known_hosts."
}

# This is the advanced menu – renamed to avoid conflict with the basic version in tt_functions.sh
ssh_key_management() {
    while true; do
        echo
        echo "=== SSH Key Management (Extended) ==="
        echo "1. Generate new SSH key"
        echo "2. List existing keys (with fingerprints)"
        echo "3. Copy public key to clipboard"
        echo "4. View known_hosts"
        echo "5. Remove host from known_hosts"
        echo "6. Back to main menu"
        read -rp "Choice [1-6]: " key_choice
        
        case $key_choice in
            1) generate_ssh_key ;;
            2) list_ssh_keys ;;
            3) copy_ssh_key ;;
            4) view_known_hosts ;;
            5) remove_known_host ;;
            6) return ;;
            *) echo "Invalid choice" ;;
        esac
    done
}

# Add to the bottom on ~/.bashrc ----------------------------------------------


# To the extent possible under law, the author(s) have dedicated all 
# copyright and related and neighboring rights to this software to the 
# public domain worldwide. This software is distributed without any warranty. 
# You should have received a copy of the CC0 Public Domain Dedication along 
# with this software. 
# If not, see <https://creativecommons.org/publicdomain/zero/1.0/>. 

# ~/.bashrc: executed by bash(1) for interactive shells.

# The copy in your home directory (~/.bashrc) is yours, please
# feel free to customise it to create a shell
# environment to your liking.  If you feel a change
# would be benifitial to all, please feel free to send
# a patch to the msys2 mailing list.

# User dependent .bashrc file

# If not running interactively, don't do anything
[[ "$-" != *i* ]] && return

# ===================================================
# STREAMER MODE CUSTOMISATIONS (kept as‑is)
# ===================================================
STREAMER_MODE=true
STREAMER_MASK="dA"
IP_MASK="cAVe"

# set variable identifying the chroot you work in (used in prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set fancy prompt (non-color, unless we know we want color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for color prompt, if the terminal has capability; turned off by default
# force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=no
    fi
fi

if [ "$color_prompt" = yes ]; then
    if [ "$STREAMER_MODE" = true ]; then
        PS1='\[\033[01;32m\]${STREAMER_MASK}@${IP_MASK}:\[\033[01;34m\]\w\[\033[00m\]\$ '
    else
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    fi
else
    if [ "$STREAMER_MODE" = true ]; then
        # FIXED: was ${STREAMER_MASK@$IP_MASK} - removed '@' which is a bash operator
        PS1='${STREAMER_MASK}@${IP_MASK}:\w\$ '
    else
        PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
    fi
fi
unset color_prompt force_color_prompt

# if this is a xterm set the title to user@host:dir
case "$TERM" in 
xterm*|rxvt*)
    if [ "$STREAMER_MODE" = true ]; then   # FIXED: missing $ before STREAMER_MODE
        PS1="\[\e]0;${STREAMER_MASK}@${IP_MASK}: \w\a\]$PS1"
    else
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h:\w\a\]$PS1"
    fi
    ;;
*)
    ;;
esac

alias dir='ls --color=auto --format=vertical'
alias vdir='ls --color=auto --format=long'

# ===================================================
# HELPER SCRIPTS PATH (new, but kept)
# ===================================================
export PATH="$HOME/.config/terminal_type/helpers:$PATH"

# ===================================================
# STREAMER ALIASES (fixed missing slash)
# ===================================================
alias set-streamer-mask='/usr/local/bin/assign-streamer-mask.sh'
alias set-ip-mask='/usr/local/bin/assign-ip-mask.sh'
alias set-streamer-mode='/usr/local/bin/assign-streamer-mode.sh'
alias show-streamer-status='/usr/local/bin/show-streamer-mode-status.sh'   # FIXED: added leading slash

# ===================================================
# TERMINAL TYPE LAUNCHER (now sourced from external file)
# ===================================================
if [ -f "$HOME/.config/terminal_type/term_type.sh" ]; then
    source "$HOME/.config/terminal_type/term_type.sh"
else
    echo "Warning: term_type.sh not found at ~/.config/terminal_type/term_type.sh"
fi

# Auto‑run term_type if not in an SSH session and interactive
if [[ -z "$SSH_CONNECTION" && $- == *i* ]]; then
    term_type "$@"
fi

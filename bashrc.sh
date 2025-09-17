# There are a few files details in this document They should be placed where the dirctory is located inorder for term_type to work 
# These few scripts will prompt if the terminal should be a local terminal or should it try to connect via ssh based on the config settings



# ~/.config/terminal_type/tt_config.sh

#!/bin/bash
# Terminal Type Configuration

# SSH Connection Settings
SSH_USER=""
SSH_ADDRESS=""
SSH_AUTH_TYPE="password"
SSH_KEY_PATH=""

# Default selection
DEFAULT_SELECTION="1"





# ~/.config/terminal_type/tt_functions.sh

#!/bin/bash
# Terminal Type Functions

show_menu() {
    echo "=== Terminal Type Selection ================="
    echo "1. Local Terminal"
    echo "2. SSH Terminal"
    echo "3. Configure SSH"
    echo "4. Manage SSH Keys"
    echo "============================================="
}

configure_ssh() {
    
    echo "=== SSH Configuration ======================="
    read -p "SSH Username: " SSH_USER
    read -p "SSH Address (hostname/IP): " SSH_ADDRESS
    
    echo "Select authentication method:"
    echo "1. Password (prompt on connection)"
    echo "2. SSH Key"
    read -p "Choice [1-2]: " auth_choice
    
    case $auth_choice in
        1) SSH_AUTH_TYPE="password" ;;
        2) 
            SSH_AUTH_TYPE="key"
            read -p "SSH Key path (leave empty for default): " key_path
            if [[ -z "$key_path" ]]; then
                SSH_KEY_PATH="$HOME/.ssh/id_rsa"
            else
                SSH_KEY_PATH="$key_path"
            fi
            ;;
        *) echo "Invalid choice"; return 1 ;;
    esac
    
    # Save configuration
    save_config
    echo "Configuration saved!"
}

save_config() {
    cat > "$HOME/.config/terminal_type/tt_config.sh" << EOL
#!/bin/bash
# Terminal Type Configuration

# SSH Connection Settings
SSH_USER="$SSH_USER"
SSH_ADDRESS="$SSH_ADDRESS"
SSH_AUTH_TYPE="$SSH_AUTH_TYPE"
SSH_KEY_PATH="$SSH_KEY_PATH"

# Default selection
DEFAULT_SELECTION="$DEFAULT_SELECTION"
EOL
}

manage_ssh_keys() {
    
    echo "=== SSH Key Management ======================"
    echo "1. Generate new SSH key"
    echo "2. List existing keys"
    echo "3. Copy key to clipboard"
    echo "4. Back to main menu"
    
    read -p "Choice [1-4]: " key_choice
    
    case $key_choice in
        1) generate_ssh_key ;;
        2) list_ssh_keys ;;
        3) copy_ssh_key ;;
        4) return ;;
        *) echo "Invalid choice" ;;
    esac
}

generate_ssh_key() {
    read -p "Key name (default: id_rsa): " key_name
    key_name=${key_name:-id_rsa}
    read -p "Key directory (default: ~/.ssh/): " key_dir
    key_dir=${key_dir:-$HOME/.ssh}
    
    mkdir -p "$key_dir"
    ssh-keygen -t rsa -b 4096 -f "$key_dir/$key_name"
    echo "SSH key generated at: $key_dir/$key_name"
}

list_ssh_keys() {
    echo "Available SSH keys:"
    find ~/.ssh -name "*.pub" 2>/dev/null | while read pubkey; do
        local privkey="${pubkey%.pub}"
        echo "Key: $(basename $privkey)"
        echo "  Public: $pubkey"
        echo "  Private: $privkey"
        if [[ -f "$privkey" ]]; then
            echo "  Fingerprint: $(ssh-keygen -lf "$pubkey" | cut -d' ' -f2)"
        fi
        echo "---"
    done
}

copy_ssh_key() {
    read -p "Enter public key file path: " key_file
    if [[ -f "$key_file" ]]; then
        if command -v xclip >/dev/null 2>&1; then
            cat "$key_file" | xclip -selection clipboard
            echo "Key copied to clipboard!"
        elif command -v pbcopy >/dev/null 2>&1; then
            cat "$key_file" | pbcopy
            echo "Key copied to clipboard!"
        else
            echo "Clipboard utilities not found. Here's your key:"
            cat "$key_file"
        fi
    else
        echo "File not found: $key_file"
    fi
}

connect_ssh() {
    if [[ -z "$SSH_USER" || -z "$SSH_ADDRESS" ]]; then
        echo "SSH configuration incomplete. Please run configuration first."
        configure_ssh
        # If user completed configuration, try connecting again
        if [[ -n "$SSH_USER" && -n "$SSH_ADDRESS" ]]; then
            connect_ssh
        fi
        return
    fi
    
    local ssh_command="ssh"
    
    if [[ "$SSH_AUTH_TYPE" == "key" && -n "$SSH_KEY_PATH" && -f "$SSH_KEY_PATH" ]]; then
        ssh_command+=" -i $SSH_KEY_PATH"
    fi
    
    echo "Connecting to $SSH_USER@$SSH_ADDRESS..."
    $ssh_command "$SSH_USER@$SSH_ADDRESS"
}

handle_auto_mode() {
    local mode="$1"
    
    case "$mode" in
        "auto-local")
            echo "Auto mode: Local Terminal"
            # Just continue with normal shell operation
            ;;
        "auto-ssh")
            echo "Auto mode: SSH Terminal"
            connect_ssh
            # Exit after SSH connection attempt if successful
            if [[ $? -eq 0 ]]; then
                exit 0
            fi
            ;;
        *)
            echo "Unknown auto mode: $mode"
            show_menu
            handle_menu_selection
            ;;
    esac
}


handle_menu_selection() {
    read -p "Select option [1-4] (default: $DEFAULT_SELECTION): " choice
    choice=${choice:-$DEFAULT_SELECTION}
    
    case $choice in
        1)
            echo "Local terminal selected."
            # Continue with normal operation
            ;;
        2)
            connect_ssh
            # Exit after SSH connection attempt if successful
            if [[ $? -eq 0 ]]; then
                exit 0
            fi
            ;;
        3)
            configure_ssh
            # Show menu again after configuration
            show_menu
            handle_menu_selection
            ;;
        4)
            manage_ssh_keys
            # Show menu again after key management
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




# Add to the bottom on ~/.bashrc



term_type() {
    # Source configuration and functions first
    local config_dir="$HOME/.config/terminal_type"
    local config_file="$config_dir/tt_config.sh"
    local functions_file="$config_dir/tt_functions.sh"
    
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    else
        echo "Configuration file not found. Running first-time setup..."
        mkdir -p "$config_dir"
        cat > "$config_file" << 'EOF'
#!/bin/bash
# Terminal Type Configuration

# SSH Connection Settings
SSH_USER=""
SSH_ADDRESS=""
SSH_AUTH_TYPE=""  # "password" or "key"
SSH_KEY_PATH=""

# Default selection (1: Local, 2: SSH)
DEFAULT_SELECTION="1"
EOF
        echo "Default configuration created at $config_file"
    fi
    
    if [[ -f "$functions_file" ]]; then
        source "$functions_file"
    else
        echo "Functions file not found. Creating default functions..."
        mkdir -p "$config_dir"
        cat > "$functions_file" << 'EOF'
#!/bin/bash
# Terminal Type Functions

show_menu() {
    echo "=== Terminal Type Selection ==="
    echo "1. Local Terminal"
    echo "2. SSH Terminal"
    echo "3. Configure SSH"
    echo "4. Manage SSH Keys"
    echo "================================"
}

configure_ssh() {
    echo "=== SSH Configuration ==="
    read -p "SSH Username: " SSH_USER
    read -p "SSH Address (hostname/IP): " SSH_ADDRESS
    
    echo "Select authentication method:"
    echo "1. Password (prompt on connection)"
    echo "2. SSH Key"
    read -p "Choice [1-2]: " auth_choice
    
    case $auth_choice in
        1) SSH_AUTH_TYPE="password" ;;
        2) 
            SSH_AUTH_TYPE="key"
            read -p "SSH Key path (leave empty for default): " key_path
            if [[ -z "$key_path" ]]; then
                SSH_KEY_PATH="$HOME/.ssh/id_rsa"
            else
                SSH_KEY_PATH="$key_path"
            fi
            ;;
        *) echo "Invalid choice"; return 1 ;;
    esac
    
    # Save configuration
    save_config
    echo "Configuration saved!"
}

save_config() {
    cat > "$HOME/.config/terminal_type/tt_config.sh" << EOL
#!/bin/bash
# Terminal Type Configuration

# SSH Connection Settings
SSH_USER="$SSH_USER"
SSH_ADDRESS="$SSH_ADDRESS"
SSH_AUTH_TYPE="$SSH_AUTH_TYPE"
SSH_KEY_PATH="$SSH_KEY_PATH"

# Default selection
DEFAULT_SELECTION="$DEFAULT_SELECTION"
EOL
}

manage_ssh_keys() {
    echo "=== SSH Key Management ==="
    echo "1. Generate new SSH key"
    echo "2. List existing keys"
    echo "3. Copy key to clipboard"
    echo "4. Back to main menu"
    
    read -p "Choice [1-4]: " key_choice
    
    case $key_choice in
        1) generate_ssh_key ;;
        2) list_ssh_keys ;;
        3) copy_ssh_key ;;
        4) return ;;
        *) echo "Invalid choice" ;;
    esac
}

generate_ssh_key() {
    read -p "Key name (default: id_rsa): " key_name
    key_name=${key_name:-id_rsa}
    read -p "Key directory (default: ~/.ssh/): " key_dir
    key_dir=${key_dir:-$HOME/.ssh}
    
    mkdir -p "$key_dir"
    ssh-keygen -t rsa -b 4096 -f "$key_dir/$key_name"
    echo "SSH key generated at: $key_dir/$key_name"
}

list_ssh_keys() {
    echo "Available SSH keys:"
    find ~/.ssh -name "*.pub" 2>/dev/null | while read pubkey; do
        local privkey="${pubkey%.pub}"
        echo "Key: $(basename $privkey)"
        echo "  Public: $pubkey"
        echo "  Private: $privkey"
        if [[ -f "$privkey" ]]; then
            echo "  Fingerprint: $(ssh-keygen -lf "$pubkey" | cut -d' ' -f2)"
        fi
        echo "---"
    done
}

copy_ssh_key() {
    read -p "Enter public key file path: " key_file
    if [[ -f "$key_file" ]]; then
        if command -v xclip >/dev/null 2>&1; then
            cat "$key_file" | xclip -selection clipboard
            echo "Key copied to clipboard!"
        elif command -v pbcopy >/dev/null 2>&1; then
            cat "$key_file" | pbcopy
            echo "Key copied to clipboard!"
        else
            echo "Clipboard utilities not found. Here's your key:"
            cat "$key_file"
        fi
    else
        echo "File not found: $key_file"
    fi
}

connect_ssh() {
    if [[ -z "$SSH_USER" || -z "$SSH_ADDRESS" ]]; then
        echo "SSH configuration incomplete. Please run configuration first."
        configure_ssh
        # If user completed configuration, try connecting again
        if [[ -n "$SSH_USER" && -n "$SSH_ADDRESS" ]]; then
            connect_ssh
        fi
        return
    fi
    
    local ssh_command="ssh"
    
    if [[ "$SSH_AUTH_TYPE" == "key" && -n "$SSH_KEY_PATH" && -f "$SSH_KEY_PATH" ]]; then
        ssh_command+=" -i $SSH_KEY_PATH"
    fi
    
    echo "Connecting to $SSH_USER@$SSH_ADDRESS..."
    $ssh_command "$SSH_USER@$SSH_ADDRESS"
}

handle_auto_mode() {
    local mode="$1"
    
    case "$mode" in
        "auto-local")
            echo "Auto mode: Local Terminal"
            # Just continue with normal shell operation
            ;;
        "auto-ssh")
            echo "Auto mode: SSH Terminal"
            connect_ssh
            # Exit after SSH connection attempt if successful
            if [[ $? -eq 0 ]]; then
                exit 0
            fi
            ;;
        *)
            echo "Unknown auto mode: $mode"
            show_menu
            handle_menu_selection
            ;;
    esac
}

handle_menu_selection() {
    read -p "Select option [1-4] (default: $DEFAULT_SELECTION): " choice
    choice=${choice:-$DEFAULT_SELECTION}
    
    case $choice in
        1)
            echo "Local terminal selected."
            # Continue with normal operation
            ;;
        2)
            connect_ssh
            # Exit after SSH connection attempt if successful
            if [[ $? -eq 0 ]]; then
                exit 0
            fi
            ;;
        3)
            configure_ssh
            # Show menu again after configuration
            show_menu
            handle_menu_selection
            ;;
        4)
            manage_ssh_keys
            # Show menu again after key management
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
EOF
        source "$functions_file"
    fi
    
    # Now handle arguments (after functions are sourced)
    case "$1" in
        "auto-local")
            # Just source functions but don't show menu, continue normally
            return 0
            ;;
        "auto-ssh")
            connect_ssh
            # If SSH connection is successful, exit the shell
            if [[ $? -eq 0 ]]; then
                exit 0
            fi
            # If connection fails, continue with local terminal
            return 0
            ;;
        "")
            # No arguments - show interactive menu
            show_menu
            handle_menu_selection
            ;;
        *)
            echo "Usage: term_type [auto-local|auto-ssh]"
            echo "  auto-local: Continue with local terminal (no menu)"
            echo "  auto-ssh:  Auto-connect via SSH if configured"
            echo "  no args:   Show interactive menu"
            return 1
            ;;
    esac
}

# Only run automatically if not already in an SSH session and not in a non-interactive shell
if [[ -z "$SSH_CONNECTION" && $- == *i* ]]; then
    # For automatic execution on shell startup, use the default behavior
    term_type
fi

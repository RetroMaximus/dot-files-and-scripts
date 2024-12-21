CrudePyBuild v0.0.1

CrudePyBuild is a simple and flexible Bash script for building Python applications into standalone binaries using PyInstaller. Designed with ease of use in mind, this script automates the process of setting up a virtual environment, installing dependencies, and building the binary. It also provides users with options to move or copy the built binary for global execution or leave it in the project directory.

Features

Automatic Virtual Environment Setup: Creates and activates a Python virtual environment if one does not already exist.

Dependency Management: Installs PyInstaller and other required modules automatically.

Cross-Platform Support: Detects the operating system and builds binaries for both Linux and Windows.

Output Handling: Provides options to move, copy, or skip the built binary’s relocation.

Simplicity: Handles complex tasks with minimal user input.

- How It Works

-- Initialization:

Automatically captures the project directory, entry point, and desired output name from the provided arguments.

Logs the build start time for easy tracking.

-- Setup:

Creates a .venv directory for virtual environment isolation.

Installs PyInstaller and all dependencies specified in requirements.txt.

-- Build Process:

Generates a standalone binary using PyInstaller with OS-specific configurations.

Supports hidden imports for Windows (e.g., win32security, win32gui).

-- Post-Build Options:

Prompts the user to move, copy, or skip the relocation of the binary.

Sets executable permissions for easy execution.

- Basic Usage

-- Running the Script

bash crudepybuild.sh <entry_point_name> <path_to_entry_point.py>

-- Example

bash crudepybuild.sh myapp.py /home/user/myproject/myapp.py

Output

Move: Moves the binary to /usr/local/bin for global execution.

Copy: Copies the binary to /usr/local/bin for global execution.

Skip: Leaves the binary in the dist directory within the project.


- Installing the Script for a Single User

To make the script available for the current user only:

Move the script to ~/bin:

mkdir -p ~/bin
mv crudepybuild.sh ~/bin/crudepybuild
chmod +x ~/bin/crudepybuild

Add ~/bin to your PATH if it is not already included:

echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

You can now call the script from any directory:

crudepybuild <path_to_entry_point.py> <entry_point_name>


- Installing the Script Globally

To allow the script to be called from anywhere on the system:

Move the script to /usr/local/bin:

sudo mv crudepybuild.sh /usr/local/bin/crudepybuild
sudo chmod +x /usr/local/bin/crudepybuild

Now you can call the script from any directory:

crudepybuild <path_to_entry_point.py> <entry_point_name>

- Notes

Ensure Python 3.6+ is installed and accessible on your system.

Linux Mint users may need to enable and use the venv module to install required packages.

The script assumes requirements.txt is present in the project directory for dependency management.

- License

CrudePyBuild is released under the MIT License. Feel free to use and modify it to suit your needs.

Contributions

Contributions are welcome! If you have ideas to improve CrudePyBuild, please create a pull request or open an issue.

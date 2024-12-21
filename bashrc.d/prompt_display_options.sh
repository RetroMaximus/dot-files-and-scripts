#!/bin/bash

# Define prompts
DEFAULTPS1='\[\e]0;\w\a\]\[\e[32m\]\u@\h \[\e[35m\]$MSYSTEM\[\e[0m\] \[\e[33m\]\w\[\e[0m\]\n'"${_ps1_symbol}"'\[\e[35m\]>\[\e[0m\] '
USRHOME='\[\e]0;\w\a\]\[\e[32m\]\u@\h\[\e[35m\]:\[\e[0m\] \[\e[33m\]\w\[\e[0m\]\n'"${_ps1_symbol}"'\[\e[35m\]>\[\e[0m\] '
MINIMUM='\[\e]0;\w\a\]\[\e[32m\]Current Directory\[\e[35m\]:\[\e[0m\] \[\e[33m\]\w\[\e[0m\]\n'"${_ps1_symbol}"'\[\e[35m\]>\[\e[0m\] '
BAREMIN='\[\e[35m\]\[\e[33m\]\w/\n\[\e[35m\]>\[\e[0m\] '

# Function to find the current Git branch
function find_git_branch {
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    echo '\[\e[35m\]Git\[\e[32m\]: \[\e[33m\]'"$branch"'\[\e[0m\]\n'
  else
    echo '\[\e[35m\]Git\[\e[32m\]: \[\e[33m\]No branch found.\[\e[0m\]\n'
    #echo '\[\e[0m\]'
  fi
}

# Set DISPLAY_PROMPT based on DISPLAY_TYPE
case $DISPLAY_TYPE in
  0) DISPLAY_PROMPT=$DEFAULTPS1 ;;
  1) DISPLAY_PROMPT=$USRHOME ;;
  2) DISPLAY_PROMPT=$MINIMUM ;;
  3) DISPLAY_PROMPT=$BAREMIN ;;
  *) DISPLAY_PROMPT=$DEFAULTPS1 ;; # Default case if DISPLAY_TYPE is invalid
esac

# Update the prompt based on the selection and timestamp option
function update_prompt {
  local git_branch=$(find_git_branch)
  if [ $USETIMESTAMP -eq 1 ]; then
    if [ $SHOWGITBRANCH -eq 1 ]; then
      PS1="\n\[\e[34m\]$(date '+%Y-%m-%d %H:%M:%S')\n\[\e[0m\]$git_branch$DISPLAY_PROMPT"
    else
      PS1="\n\[\e[34m\]$(date '+%Y-%m-%d %H:%M:%S')\n\[\e[0m\]$DISPLAY_PROMPT"
    fi
  else
    if [ $SHOWGITBRANCH -eq 1 ]; then
      PS1="$git_branch$DISPLAY_PROMPT"
    else
      PS1="$DISPLAY_PROMPT"
    fi
  fi
}

PROMPT_COMMAND=update_prompt
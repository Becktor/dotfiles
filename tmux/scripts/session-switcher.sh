#!/bin/bash

# Tmux session switcher using fzf
# Usage: ./session-switcher.sh

# Get the list of tmux sessions
sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)

if [ -z "$sessions" ]; then
    echo "No tmux sessions found."
    echo "Create a new session? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Enter session name:"
        read -r session_name
        tmux new-session -s "$session_name"
    fi
    exit 0
fi

# Use fzf to select a session
selected_session=$(echo "$sessions" | fzf --height=10 --reverse --border --prompt="Select session: ")

if [ -n "$selected_session" ]; then
    # If we're in tmux, switch to the selected session
    if [ -n "$TMUX" ]; then
        tmux switch-client -t "$selected_session"
    else
        # If we're not in tmux, attach to the selected session
        tmux attach-session -t "$selected_session"
    fi
fi
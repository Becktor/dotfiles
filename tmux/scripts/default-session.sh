#!/bin/bash

# Exit immediately if a command fails
set -e

# Session name
SESSION_NAME="default_session"

# Check if the session already exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Session '$SESSION_NAME' already exists. Attaching..."
    tmux attach-session -t "$SESSION_NAME"
    exit 0
fi

echo "Creating new tmux session: $SESSION_NAME"

# Start a new detached tmux session with Neovim in the first window
tmux new-session -d -s "$SESSION_NAME" -n nvim
tmux send-keys -t "$SESSION_NAME:1" 'nvim' C-m

# Create a second window named "shell"
tmux new-window -t "$SESSION_NAME":2 -n zsh

# Create a third window named "music" and run ncspot
tmux new-window -t "$SESSION_NAME":3 -n spotify 
tmux send-keys -t "$SESSION_NAME:3" 'ncspot' C-m

# Ensure the first window (Neovim) is active at start
tmux select-window -t "$SESSION_NAME:1"

# Attach to the session
tmux attach-session -t "$SESSION_NAME"


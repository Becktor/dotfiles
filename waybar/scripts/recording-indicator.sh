#!/bin/bash

# Check if wf-recorder is running
if pgrep -x wf-recorder > /dev/null; then
    echo '{"text": "⏺", "tooltip": "Recording in progress - Alt+Shift+R to stop", "class": "recording"}'
else
    echo '{"text": "", "tooltip": "", "class": ""}'
fi

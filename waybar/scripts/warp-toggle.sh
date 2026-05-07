#!/bin/bash

case "$1" in
    toggle)
        if pgrep -x warp-svc > /dev/null; then
            # Stop warp-svc (mask to prevent auto-restart)
            sudo systemctl mask warp-svc.service
            sudo systemctl stop warp-svc.service
            # Stop warp-taskbar (user service)
            systemctl --user mask warp-taskbar.service
            systemctl --user stop warp-taskbar.service
        else
            # Start warp-svc
            sudo systemctl unmask warp-svc.service
            sudo systemctl start warp-svc.service
            # Start warp-taskbar
            systemctl --user unmask warp-taskbar.service
            systemctl --user start warp-taskbar.service
        fi
        ;;
    *)
        # Output JSON for waybar
        if pgrep -x warp-svc > /dev/null; then
            echo '{"text": "󱥸", "tooltip": "WARP Connected - Click to disconnect", "class": "connected"}'
        else
            echo '{"text": "󱥸", "tooltip": "WARP Disconnected - Click to connect", "class": "disconnected"}'
        fi
        ;;
esac

apply_workspaces() {
    mapfile -t monitors < <(hyprctl monitors -j | jq -r 'sort_by([.x, .y]) | .[].name')
    ((${#monitors[@]})) || return

    local left=${monitors[0]}
    local right=${monitors[-1]}
    local right_default=false
    [[ $left != "$right" ]] && right_default=true

    hyprctl keyword workspace "1,monitor:$left,default:true" >/dev/null
    hyprctl keyword workspace "2,monitor:$left,default:false" >/dev/null
    hyprctl keyword workspace "3,monitor:$left,default:false" >/dev/null
    hyprctl keyword workspace "r[4-999999999],monitor:$right,default:false" >/dev/null
    hyprctl keyword workspace "4,monitor:$right,default:$right_default" >/dev/null
}

watch_monitors() {
    exec 9>"$XDG_RUNTIME_DIR/hypr-workspace-monitors.lock"
    flock -n 9 || return
    apply_workspaces

    local socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
    while true; do
        socat -u "UNIX-CONNECT:$socket" - | while IFS= read -r event; do
            case "$event" in
                monitoradded*|monitorremoved*)
                    sleep 0.5
                    apply_workspaces
                    ;;
            esac
        done
        sleep 1
    done
}

case ${1:-apply} in
    apply) apply_workspaces ;;
    watch) watch_monitors ;;
esac

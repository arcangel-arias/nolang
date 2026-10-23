#!/bin/bash
# proyecto.sh on|off|status
# Activa o desactiva el proyecto de clips con mpv en esta Raspberry Pi.
# Sirve para las dos Pi: detecta solo qué servicios tiene instalados
#   - reproductora -> mpv-socat
#   - controladora -> controlador
# Ejecútalo con tu usuario normal (SIN sudo); pedirá sudo cuando lo necesite.

AUTOSTART="$HOME/.config/autostart"
DESKTOP="$AUTOSTART/mpv-clips.desktop"
OFF="$DESKTOP.off"
PATRON="input-ipc-server=/tmp/mpvsocket"   # identifica SOLO el mpv de este proyecto

if [ "$EUID" -eq 0 ]; then
    echo "No lo ejecutes con sudo: usa tu usuario normal (el script llama a sudo cuando hace falta)."
    exit 1
fi

# Servicios de este proyecto instalados en esta Pi
SERVICIOS=()
[ -f /etc/systemd/system/mpv-socat.service ]   && SERVICIOS+=(mpv-socat)
[ -f /etc/systemd/system/controlador.service ] && SERVICIOS+=(controlador)

mpv_activo() { pgrep -f -- "$PATRON" >/dev/null; }

lanzar_mpv() {
    mpv_activo && return 0
    if [ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
        echo "  (no hay sesión gráfica en esta terminal: mpv arrancará en el próximo inicio de sesión)"
        return 0
    fi
    local cmd
    cmd=$(grep -m1 '^Exec=' "$DESKTOP" | cut -d= -f2-)
    nohup setsid bash -c "$cmd" >/dev/null 2>&1 &
    echo "  mpv lanzado"
}

activar() {
    echo "Activando proyecto..."
    [ -f "$OFF" ] && mv "$OFF" "$DESKTOP"
    if [ ! -f "$DESKTOP" ]; then
        echo "ERROR: no existe $DESKTOP. Crea primero el archivo de autostart de mpv."
        exit 1
    fi
    lanzar_mpv
    for s in "${SERVICIOS[@]}"; do
        sudo systemctl enable --now "$s" && echo "  servicio $s activado"
    done
    [ ${#SERVICIOS[@]} -eq 0 ] && echo "  AVISO: no se encontró mpv-socat ni controlador en esta Pi."
    echo "Hecho. Se mantendrá activo en cada arranque."
}

desactivar() {
    echo "Desactivando proyecto..."
    for s in "${SERVICIOS[@]}"; do
        sudo systemctl disable --now "$s" && echo "  servicio $s desactivado"
    done
    [ -f "$DESKTOP" ] && mv "$DESKTOP" "$OFF" && echo "  autostart de mpv desactivado"
    pkill -f -- "$PATRON" && echo "  mpv cerrado"
    echo "Hecho. No arrancará en los próximos encendidos."
}

estado() {
    echo "Estado del proyecto:"
    for s in "${SERVICIOS[@]}"; do
        printf "  %-12s arranque: %-9s ahora: %s\n" "$s" \
            "$(systemctl is-enabled "$s" 2>/dev/null)" "$(systemctl is-active "$s" 2>/dev/null)"
    done
    if   [ -f "$DESKTOP" ]; then echo "  autostart mpv: activado"
    elif [ -f "$OFF" ];     then echo "  autostart mpv: desactivado"
    else                         echo "  autostart mpv: no existe"
    fi
    if mpv_activo; then echo "  mpv: en ejecución"; else echo "  mpv: parado"; fi
}

case "${1:-}" in
    on)     activar ;;
    off)    desactivar ;;
    status) estado ;;
    *)      echo "Uso: $0 on|off|status"; exit 1 ;;
esac

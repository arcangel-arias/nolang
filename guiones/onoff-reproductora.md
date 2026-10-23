# DESACTIVAR
sudo systemctl disable --now mpv-socat      # para el puente y evita que arranque
mv ~/.config/autostart/mpv-clips.desktop ~/.config/autostart/mpv-clips.desktop.off
pkill mpv                                   # cierra mpv ahora mismo

# REACTIVAR
mv ~/.config/autostart/mpv-clips.desktop.off ~/.config/autostart/mpv-clips.desktop
sudo systemctl enable --now mpv-socat
sudo reboot                                 # o cierra sesión y vuelve a entrar


explicación:

Hay que tocar tres piezas, y cada una se desactiva de forma distinta. Para cada una hay dos casos: parar ahora mismo y que no vuelva a arrancar en los próximos encendidos.

## Pi reproductora

```bash
# DESACTIVAR
sudo systemctl disable --now mpv-socat      # para el puente y evita que arranque
mv ~/.config/autostart/mpv-clips.desktop ~/.config/autostart/mpv-clips.desktop.off
pkill mpv                                   # cierra mpv ahora mismo

# REACTIVAR
mv ~/.config/autostart/mpv-clips.desktop.off ~/.config/autostart/mpv-clips.desktop
sudo systemctl enable --now mpv-socat
sudo reboot                                 # o cierra sesión y vuelve a entrar
```

## Pi controladora

```bash
# DESACTIVAR
sudo systemctl disable --now controlador
mv ~/.config/autostart/mpv-clips.desktop ~/.config/autostart/mpv-clips.desktop.off
pkill mpv

# REACTIVAR
mv ~/.config/autostart/mpv-clips.desktop.off ~/.config/autostart/mpv-clips.desktop
sudo systemctl enable --now controlador
sudo reboot
```

## Por qué así

- **`disable --now`** hace dos cosas: para el servicio en este momento (`--now`) y quita el enlace de arranque, así que no vuelve en el siguiente encendido. `enable --now` hace lo contrario.
- **Renombrar el `.desktop`** funciona porque el escritorio solo ejecuta los archivos que acaban en `.desktop`. Con `.off` al final los ignora, pero conservas el contenido para recuperarlo.
- **`pkill mpv`** es necesario porque mpv no es un servicio de systemd. Se lanza con el escritorio, así que `systemctl` no lo controla.

## Variantes útiles

- **Pausa temporal sin tocar el arranque:** `sudo systemctl stop controlador` (o `mpv-socat`) lo detiene hasta el próximo reinicio. Con `start` lo vuelves a lanzar.
- **Solo quitar el caos aleatorio** y dejar los clips en reproducción: desactiva únicamente `controlador`. Los clips seguirán sonando en modo shuffle sin que nadie los altere.
- **Comprobar el estado:** `systemctl is-enabled controlador` te dice si arrancará en el próximo encendido, y `systemctl is-active controlador` si está funcionando ahora.

Si lo vas a hacer a menudo, puedo prepararte un script `proyecto.sh on|off` para cada Pi, de modo que sean un solo comando en lugar de varios.

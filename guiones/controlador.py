#!/usr/bin/env python3
import socket, json, random, time

class MPV:
    def __init__(self, nombre, familia, direccion):
        self.nombre, self.familia, self.direccion = nombre, familia, direccion

    def cmd(self, *args):
        rid = random.randint(1, 10**6)
        try:
            with socket.socket(self.familia, socket.SOCK_STREAM) as s:
                s.settimeout(2)
                s.connect(self.direccion)
                s.sendall((json.dumps({"command": list(args), "request_id": rid}) + "\n").encode())
                buf = b""
                while True:
                    chunk = s.recv(4096)
                    if not chunk:
                        return None
                    buf += chunk
                    for linea in buf.split(b"\n"):
                        try:
                            msg = json.loads(linea)
                        except ValueError:
                            continue
                        if msg.get("request_id") == rid:
                            return msg
        except OSError:
            return None   # el reproductor aún no está listo: se reintenta luego

REPRODUCTORES = [
    MPV("local",  socket.AF_UNIX, "/tmp/mpvsocket"),
    MPV("remota", socket.AF_INET, ("192.168.1.2", 5000)),
]

def saltar_a_clip(p):
    r = p.cmd("get_property", "playlist-count")
    if r and r.get("data"):
        p.cmd("playlist-play-index", random.randrange(r["data"]))

def saltar_en_clip(p):
    p.cmd("seek", random.randint(0, 95), "absolute-percent")

def cambiar_velocidad(p):
    p.cmd("set_property", "speed", random.choice([0.5, 0.75, 1, 1, 1, 1.5, 2]))

def pausa_breve(p):
    p.cmd("set_property", "pause", True)
    time.sleep(random.uniform(0.5, 3))
    p.cmd("set_property", "pause", False)

# (acción, peso): las más altas ocurren más a menudo
ACCIONES = [(saltar_a_clip, 4), (saltar_en_clip, 3), (cambiar_velocidad, 2), (pausa_breve, 1)]

def main():
    time.sleep(10)  # deja arrancar el escritorio y mpv
    while True:
        for p in random.sample(REPRODUCTORES, random.randint(1, 2)):
            accion = random.choices([a for a, _ in ACCIONES], [w for _, w in ACCIONES])[0]
            accion(p)
        time.sleep(random.uniform(3, 15))   # intervalo entre cambios

if __name__ == "__main__":
    main()

"""Show a PNG fitted to the terminal with the kitty graphics protocol, and redraw on resize."""
import base64, fcntl, os, signal, struct, sys, termios

path = sys.argv[1]
data = base64.standard_b64encode(open(path, "rb").read())
try:
    from PIL import Image
    iw, ih = Image.open(path).size
except Exception:
    iw, ih = 16, 10


def draw(*_):
    rows, cols, xpx, ypx = struct.unpack("HHHH", fcntl.ioctl(sys.stdout.fileno(), termios.TIOCGWINSZ, b"\0" * 8))
    cw = xpx / cols if xpx else 8
    ch = ypx / rows if ypx else 16
    avail_c, avail_r = cols, max(rows - 1, 1)
    scale = min(avail_c * cw / iw, avail_r * ch / ih)
    c = max(1, int(iw * scale / cw))
    r = max(1, int(ih * scale / ch))
    out = sys.stdout
    out.write("\x1b_Ga=d,d=A\x1b\\\x1b[2J\x1b[H")
    chunks = [data[i:i + 4096] for i in range(0, len(data), 4096)]
    for i, chunk in enumerate(chunks):
        more = 1 if i < len(chunks) - 1 else 0
        head = f"a=T,f=100,q=2,c={c},r={r},C=1," if i == 0 else ""
        out.write(f"\x1b_G{head}m={more};{chunk.decode()}\x1b\\")
    out.flush()


signal.signal(signal.SIGWINCH, draw)
draw()
sys.stdout.write("\x1b[?25l")
sys.stdout.flush()
while True:
    signal.pause()

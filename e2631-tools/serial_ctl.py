"""Direct COM5 serial driver for E2631 U-Boot bring-up."""
import serial, sys, time

PORT = 'COM5'
BAUD = 115200

def open_port():
    return serial.Serial(PORT, BAUD, timeout=1)

def drain(s, secs=1.0):
    out = b''
    t0 = time.time()
    while time.time() - t0 < secs:
        chunk = s.read(4096)
        if chunk:
            out += chunk
    return out

def send(s, cmd, wait=1.0):
    s.write(cmd.encode() + b'\n')
    time.sleep(0.2)
    return drain(s, wait)

def read_until_idle(s, total=30.0, quiet=2.0):
    """Read until no data for `quiet` seconds or `total` elapsed."""
    out = b''
    t0 = time.time()
    last = time.time()
    while time.time() - t0 < total:
        chunk = s.read(8192)
        if chunk:
            out += chunk
            last = time.time()
        elif time.time() - last > quiet:
            break
    return out

if __name__ == '__main__':
    action = sys.argv[1] if len(sys.argv) > 1 else 'probe'
    s = open_port()
    try:
        if action == 'probe':
            out = drain(s, 1.0)
            out += send(s, '', 1.0)
            print(out.decode(errors='replace')[-500:])
            print('--- probe end ---')
        elif action == 'cmd':
            cmd = sys.argv[2]
            wait = float(sys.argv[3]) if len(sys.argv) > 3 else 3.0
            out = send(s, cmd, wait)
            out += read_until_idle(s, total=wait + 5, quiet=1.5)
            print(out.decode(errors='replace'))
        elif action == 'capture':
            secs = float(sys.argv[2]) if len(sys.argv) > 2 else 30.0
            out = read_until_idle(s, total=secs, quiet=3.0)
            print(out.decode(errors='replace'))
    finally:
        s.close()

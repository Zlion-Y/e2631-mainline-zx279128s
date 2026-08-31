import socket, os, threading
ROOT = r'D:\Work\e2631-kernel\OUT'
BLOCK = 512
RRQ = bytes([0, 1])
ACK = bytes([0, 4])
ERR = bytes([0, 5, 0, 1]) + b"File not found"

def pack_block(n, data):
    return bytes([0, 3, (n >> 8) & 0xFF, n & 0xFF]) + data

def session(data, addr):
    fname = data[2:].split(bytes([0]))[0].decode(errors="replace")
    path = os.path.realpath(os.path.join(ROOT, fname))
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(1.0)
    print("RRQ", fname, "from", addr[0], flush=True)
    if not path.startswith(os.path.realpath(ROOT)) or not os.path.isfile(path):
        s.sendto(ERR, addr)
        return
    payload = open(path, "rb").read()
    block, pos, retries = 1, 0, 0
    while pos < len(payload):
        s.sendto(pack_block(block, payload[pos:pos+BLOCK]), addr)
        try:
            ack, _ = s.recvfrom(128)
            n = int.from_bytes(ack[2:4], "big") if len(ack) >= 4 else -1
            if ack[:2] == ACK and n == block:
                pos += BLOCK; block = (block % 65535) + 1; retries = 0
            else:
                retries += 1
        except socket.timeout:
            retries += 1
        if retries > 20:
            print("TIMEOUT", fname, flush=True); return
    print("DONE", fname, flush=True)

def main():
    srv = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    srv.bind(("0.0.0.0", 69))
    print("tftpd2 up", flush=True)
    while True:
        data, addr = srv.recvfrom(600)
        if data[:2] == RRQ:
            threading.Thread(target=session, args=(data, addr), daemon=True).start()

main()

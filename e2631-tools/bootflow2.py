import serial, time
s = serial.Serial('COM5', 115200, timeout=0.05)
log = open('boot-final.log', 'wb')

def pump():
    got = b''
    while True:
        ch = s.read(8192)
        if not ch: break
        got += ch; log.write(ch); log.flush()
    return got

def wait_for(substr, timeout=90.0):
    t0 = time.time()
    while time.time() - t0 < timeout:
        g = pump()
        if substr.encode() in g: return True
        time.sleep(0.1)
    return False

def cmd(c, done_substr, timeout=90.0):
    pump()
    s.write(c.encode() + b'\n')
    ok = wait_for(done_substr, timeout)
    print(('OK  ' if ok else 'FAIL ') + c, flush=True)
    return ok

time.sleep(0.5); pump()
cmd('setenv ipaddr 192.168.10.66; setenv serverip 192.168.10.1', '=>')
if not cmd('tftp 0x40008000 uImage-e2631.img', 'Bytes transferred', 120):
    cmd('tftp 0x40008000 uImage-e2631.img', 'Bytes transferred', 120)
if not cmd('tftp 0x41800000 uInitrd-e2631.img', 'Bytes transferred', 120):
    cmd('tftp 0x41800000 uInitrd-e2631.img', 'Bytes transferred', 120)
print('BOOTM: capturing 120s...', flush=True)
s.write(b'bootm 0x40008000 0x41800000' + b'\n')
t0 = time.time(); last = t0
while time.time() - t0 < 180:
    g = pump()
    if g: last = time.time()
    elif time.time() - last > 25: break
print('CAPTURE DONE', flush=True)
log.close(); s.close()

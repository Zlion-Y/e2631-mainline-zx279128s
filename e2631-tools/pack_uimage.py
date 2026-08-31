#!/usr/bin/env python3
"""Wrap a payload (zImage, optionally with appended DTB) into a legacy
uImage with load/entry 0x40008000, matching the E2631 vendor layout."""
import struct, sys, zlib, time

def uimage(payload, load=0x40008000, ep=0x40008000, name="E2631-mainline-6.18",
           os_=5, arch=2, type_=2, comp=0):  # linux/arm/kernel/none
    hdr = struct.pack(">IIIIIIIBBBB32s",
                      0x27051956, 0, int(time.time()), len(payload),
                      load, ep, zlib.crc32(payload) & 0xFFFFFFFF,
                      os_, arch, type_, comp, name.encode())
    hcrc = zlib.crc32(hdr) & 0xFFFFFFFF
    hdr = hdr[:4] + struct.pack(">I", hcrc) + hdr[8:]
    return hdr + payload

if __name__ == "__main__":
    payload = open(sys.argv[1], "rb").read()
    out = sys.argv[2]
    open(out, "wb").write(uimage(payload))
    print("uImage written:", out, len(payload) + 64, "bytes")

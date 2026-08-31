"""Recursively pack a staging directory as newc cpio + gzip.

Handles: regular files, directories, symlinks (as cpio symlinks),
/dev/console special node."""
import gzip, io, os, stat, sys

def cpio_entry(name, data=b"", mode=0o100644, nlink=1, rmajor=0, rminor=0):
    nameb = name.encode()
    hdr = b"070701" + b"".join(
        b"%08X" % v for v in (0, mode & 0xFFFFFFFF, 0, 0, nlink, 0,
                              len(data), 0, 0, rmajor, rminor,
                              len(nameb) + 1, 0))
    e = hdr + nameb + b"\0"
    e += b"\0" * ((4 - len(e) % 4) % 4)
    e += data
    e += b"\0" * ((4 - len(e) % 4) % 4)
    return e

def main(srcdir, outfile):
    out = io.BytesIO()
    srcdir = os.path.abspath(srcdir)
    out.write(cpio_entry(".", mode=0o040755, nlink=3))
    for root, dirs, files in os.walk(srcdir):
        rel = os.path.relpath(root, srcdir)
        if rel != ".":
            out.write(cpio_entry(rel.replace(os.sep, "/"), mode=0o040755))
        for f in sorted(files):
            p = os.path.join(root, f)
            name = os.path.relpath(p, srcdir).replace(os.sep, "/")
            if os.path.islink(p):
                target = os.readlink(p).replace(os.sep, "/")
                out.write(cpio_entry(name, data=target.encode(),
                                     mode=0o120777))
            else:
                data = open(p, "rb").read()
                out.write(cpio_entry(name, data=data, mode=0o100755))
    # device nodes not representable via filesystem walk
    out.write(cpio_entry("dev/console", mode=0o020600, rmajor=5, rminor=1))
    out.write(cpio_entry("dev/null", mode=0o020666, rmajor=1, rminor=3))
    out.write(cpio_entry("dev/tty", mode=0o020666, rmajor=5, rminor=0))
    out.write(cpio_entry("dev/ttyAMA0", mode=0o020600, rmajor=204, rminor=64))
    out.write(cpio_entry("dev/zero", mode=0o020666, rmajor=1, rminor=5))
    out.write(cpio_entry("dev/random", mode=0o020666, rmajor=1, rminor=8))
    out.write(cpio_entry("dev/urandom", mode=0o020666, rmajor=1, rminor=9))
    out.write(cpio_entry("TRAILER!!!"))
    out.write(b"\0" * ((4096 - out.tell() % 4096) % 4096))
    raw = out.getvalue()
    with open(outfile, "wb") as f:
        with gzip.GzipFile(fileobj=f, mode="wb", mtime=0) as g:
            g.write(raw)
    print("packed %d raw -> %s" % (len(raw), outfile))

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])

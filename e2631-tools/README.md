# Tools

- `tftpd2.py`     - read-only TFTP server (UDP 69), serves parent dir; run on the PC
- `pack_uimage.py`- wrap zImage+DTB into a legacy uImage (load/entry 0x40008000)
- `serial_ctl.py` - minimal COM-port driver for driving U-Boot over serial
- `bootflow2.py`  - scripted tftp+bootm sequence via serial
- `mkconfig.sh`, `cleanbuild3.sh`, `mihomobuild.sh` - build steps used on MSYS2

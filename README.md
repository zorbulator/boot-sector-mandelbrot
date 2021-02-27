# boot sector mandelbrot

mandelbrot set in a boot sector with no bios interrupts that I made to learn assembly

## how to run

First, you need to assemble with `yasm` or `nasm`:

```
yasm -f bin mandelbrot.asm
```

Then you can run the binary using QEMU:

```
qemu-system-x86_64 -drive "file=mandelbrot,format=raw"
```

It could probably also run on bare metal if you copied it to a USB drive but I haven't tried it.

/* Minimal interactive bring-up init for the ZTE ZX279128S (ZXHN E2631).
 * Prints diagnostics over /dev/console (incl. /proc/cpuinfo features and a
 * soft-float math probe), then hands the console to a busybox shell. */

#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mount.h>
#include <stdio.h>

static int cons;

static void say(const char *s)
{
    write(cons, s, strlen(s));
}

static double fp_probe(void)
{
    double a = 1234.5, b = 0.25;
    int i;
    for (i = 0; i < 4; i++)
        a = a * b + 1.0;   /* soft-float chain: expect 6.1504 */
    return a;
}

int main(void)
{
    double r;
    char *sh_argv[] = { (char *)"/bin/busybox", (char *)"sh", NULL };
    char *sh_envp[] = { (char *)"HOME=/", (char *)"PATH=/bin:/sbin",
                        (char *)"TERM=linux", NULL };

    cons = open("/dev/console", O_RDWR);
    if (cons < 0)
        cons = 1;

    say("\n=== E2631 mainline bring-up init reached userspace ===\n");
    say("[init] kernel booted, zteuart console OK\n");

    mount("proc", "/proc", "proc", 0, NULL);
    mount("sysfs", "/sys", "sysfs", 0, NULL);

    {
        FILE *f = fopen("/proc/cpuinfo", "r");
        if (f) {
            char line[512];
            while (fgets(line, sizeof(line), f)) {
                if (line[0] == 'F' && line[1] == 'e')
                    printf("[init] %s", line);  /* Features: ... */
            }
            fclose(f);
        } else {
            say("[init] cannot open /proc/cpuinfo\n");
        }
    }

    r = fp_probe();
    printf("[init] soft-float probe: 1234.5*0.25+1 x4 = %.4f (expect 6.1504)\n", r);

    say("[init] handing console to busybox shell\n");
    dup2(cons, 0);
    dup2(cons, 1);
    dup2(cons, 2);
    setsid();
    ioctl(0, TIOCSCTTY, 0);
    execve("/bin/busybox", sh_argv, sh_envp);
    say("[init] exec busybox failed - idling\n");
    for (;;)
        pause();
    return 0;
}

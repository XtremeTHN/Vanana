import subprocess
import sys

from os.path import join, exists

ARG_LIST = []

def get_arg_with_default(name, default=None, required=False):
    arg_type = type(default) if default is not None else bool
    ARG_LIST.append((name, arg_type, default))

    try:
        pos = sys.argv.index(name) + 1
        if arg_type is bool:
            return True
        
        if pos >= len(sys.argv):
            return default
        return arg_type(sys.argv[pos])
    except ValueError:
        if default is None:
            return False
        if required:
            print('Argument', name, "is required. See -h")
            sys.exit(3)
        return default

RECONFIGURE = get_arg_with_default("-r")
KEEP_TERMINAL = get_arg_with_default("--keep-term")
DRY_RUN = get_arg_with_default("--dry-run")
NO_TEST = get_arg_with_default("--no-test")
NO_COMPILE = get_arg_with_default("--no-compile")

VANANA_BUILD_DEST_DIR = get_arg_with_default("--dest-dir", default="", required=True)
PREFIX = get_arg_with_default("-p", "/clang64/")

BIN_DIR = join(VANANA_BUILD_DEST_DIR, "bin")
ETC_DIR = join(VANANA_BUILD_DEST_DIR, "etc")
LIB_DIR = join(VANANA_BUILD_DEST_DIR, "lib")
SHARE_DIR = join(VANANA_BUILD_DEST_DIR, "share")

def c(*args, wd=None, output=False, force_exec=False):
    color = "\033[32m"
    if args[0] == "sudo":
        color = "\033[33m"

    print(f"{color}+\033[0m", *args)
    if force_exec is False and DRY_RUN is True:
        return
    
    try:
        if output is False:
            subprocess.check_call(args, cwd=wd)
        else:
            return subprocess.check_output(args, text=True)
    except subprocess.CalledProcessError as e:
        print("\033[31m+\033[0m", *args)
        sys.exit(e.returncode)
    except (KeyboardInterrupt, EOFError, Exception) as e:
        print(f"\033[31m{e.__class__.__name__}\033[0m: {e.args}")
        sys.exit(2)

def mkdir(*dirs):
    c("mkdir", "-p", *dirs)

if get_arg_with_default("-h"):
    print("Available commands:")
    for arg in ARG_LIST:
        string = f"\t{arg[0]}: {arg[1].__name__}"
        if arg[2] is not None:
            string += f"        Default: {arg[2]}"
        print(string)
    sys.exit(0)

mkdir(BIN_DIR, ETC_DIR, LIB_DIR, SHARE_DIR)

if RECONFIGURE:
    c("rm", "-rf", "build")
    
c("meson", "setup", "build")

# fixes "libintl.h: No such file or directory" when compiling
c("cp", join(PREFIX, "include", "libintl.h"), "build")

if NO_COMPILE is False:
    c("meson", "compile", "-C", "build")

if NO_TEST is False:
    print("Test the app")
    c("./build/src/vanana.exe")

print("INFO: Building bin...")

COMPILED_PATH = join("build", "src", "vanana.exe")
if exists(COMPILED_PATH):
    out = c("ldd", "build/src/vanana.exe", output=True, force_exec=True)

    dlls = [x.split(" => ")[1].split(" ")[0] for x in out.splitlines()]
    for x in dlls:
        if x.startswith(PREFIX) is False:
            continue
        c("cp", x, BIN_DIR)

c('cp', join(PREFIX, "bin", "librsvg-2-2.dll"), BIN_DIR)
c('cp', join("/usr/bin/msys-2.0.dll"), BIN_DIR)
c("cp", join(PREFIX, "bin", "gdbus.exe"), BIN_DIR)

if KEEP_TERMINAL is False:
    c("objcopy", "--subsystem", "windows", COMPILED_PATH)

c("cp", join("build", "src", "vanana.exe"), BIN_DIR)

GTK4_CONF = join(ETC_DIR, "gtk-4.0")
print("INFO: Building etc...")
mkdir(GTK4_CONF)
c("echo", "[Settings]\ngtk-font-name=Segoe UI 9", ">", join(GTK4_CONF, "settings.ini"))

print("INFO: Building lib")
c("cp", "-r", join(PREFIX, "lib", "gio"), LIB_DIR)
c("cp", "-r", join(PREFIX, "lib", "gdk-pixbuf-2.0"), LIB_DIR)

SCHEMAS_DIR = ["glib-2.0", "schemas"]
mkdir(join(SHARE_DIR, *SCHEMAS_DIR))
print("INFO: Building share")
c("sudo", "glib-compile-schemas", join(PREFIX, "share", *SCHEMAS_DIR))
c("cp", join(PREFIX, "share", *SCHEMAS_DIR, "gschemas.compiled"), join(SHARE_DIR, *SCHEMAS_DIR))

mkdir(join(SHARE_DIR, "icons", "Adwaita"))
c("cp", "-r", join(PREFIX, "share", "icons", "Adwaita"), join(SHARE_DIR, "icons"))
c("cp", "-r", join(PREFIX, "share", "icons", "hicolor"), join(SHARE_DIR, "icons"))

print("Done")
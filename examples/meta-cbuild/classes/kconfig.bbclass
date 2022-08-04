inherit terminal

KCONFIG_CONFIG_COMMAND ??= "menuconfig"
KCONFIG_CONFIG_PATH ??= "${B}/.config"

python do_setrecompile () {
    if hasattr(bb.build, 'write_taint'):
        bb.build.write_taint('do_compile', d)
}

do_setrecompile[nostamp] = "1"
addtask setrecompile

python do_menuconfig() {
    config = d.getVar('KCONFIG_CONFIG_PATH')

    try:
        mtime = os.path.getmtime(config)
    except OSError:
        mtime = 0

    oe_terminal("sh -c \"make %s; if [ \\$? -ne 0 ]; then echo 'Command failed.'; printf 'Press any key to continue... '; read r; fi\"" % d.getVar('KCONFIG_CONFIG_COMMAND'),
        d.getVar('PN') + ' Configuration', d)

    if hasattr(bb.build, 'write_taint'):
        try:
            newmtime = os.path.getmtime(config)
        except OSError:
            newmtime = 0

        if newmtime != mtime:
            bb.build.write_taint('do_compile', d)
}

do_menuconfig[depends] += "kconfig-native:do_populate_sysroot"
do_menuconfig[nostamp] = "1"
do_menuconfig[dirs] = "${B}"
addtask menuconfig after do_configure


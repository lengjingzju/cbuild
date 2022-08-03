inherit terminal

KCONFIG_CONFIG_COMMAND ??= "menuconfig"

python do_setrecompile () {
    if hasattr(bb.build, 'write_taint'):
        bb.build.write_taint('do_compile', d)
}

do_setrecompile[nostamp] = "1"
addtask setrecompile

python do_menuconfig() {
    oe_terminal("sh -c \"make %s; if [ \\$? -ne 0 ]; then echo 'Command failed.'; printf 'Press any key to continue... '; read r; fi\"" % d.getVar('KCONFIG_CONFIG_COMMAND'),
                d.getVar('PN') + ' Configuration', d)
}

do_menuconfig[depends] += "kconfig-native:do_populate_sysroot"
do_menuconfig[nostamp] = "1"
do_menuconfig[dirs] = "${B}"
do_menuconfig[postfuncs] += "do_setrecompile"
addtask menuconfig after do_configure


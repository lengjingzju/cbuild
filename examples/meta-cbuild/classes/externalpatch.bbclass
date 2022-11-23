LICENSE ?= "CLOSED"
LIC_FILES_CHKSUM ?= ""
SRC_URI = ""
DEPENDS:append = "patch-native"

do_configure () {
    :
}

python do_compile () {
    import subprocess
    patch_opt = d.getVar('EXTERNALPATCH_OPT')
    patch_src = d.getVar('EXTERNALPATCH_SRC')
    patch_dst = d.getVar('EXTERNALPATCH_DST')

    if os.path.exists(patch_src) and os.path.exists(patch_dst):
        patch_state = subprocess.getstatusoutput('patch -p1 -R -s -f --dry-run -d %s < %s' % (patch_dst, patch_src))[0]
        if (patch_opt == 'patch' and patch_state != 0) or (patch_opt == 'unpatch' and patch_state == 0):
            patch_cmd = 'patch -p1 -%s -d %s < %s' % ('b' if patch_opt == 'patch' else 'R', patch_dst, patch_src)
            subprocess.getstatusoutput(patch_cmd)
}

do_install () {
    :
}

do_repatch () {
    :
}

ALLOW_EMPTY:${PN} = "1"

python () {
    import subprocess
    patch_opt = d.getVar('EXTERNALPATCH_OPT')
    patch_src = d.getVar('EXTERNALPATCH_SRC')
    patch_dst = d.getVar('EXTERNALPATCH_DST')

    if os.path.exists(patch_src) and os.path.exists(patch_dst):
        patch_state = subprocess.getstatusoutput('patch -p1 -R -s -f --dry-run -d %s < %s' % (patch_dst, patch_src))[0]
        if (patch_opt == 'patch' and patch_state != 0) or (patch_opt == 'unpatch' and patch_state == 0):
            bb.build.addtask('do_repatch', 'do_compile', None, d)
            d.setVarFlag('do_repatch', 'nostamp', '1')
}

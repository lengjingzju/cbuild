python () {
    tasks = ['configure', 'compile', 'install']

    for task in tasks:
        task_name = 'do_%s' % (task)
        src_name = 'EXTRASRC_%s' % (task.upper())
        src_str = d.getVar(src_name)

        if src_str:
            srcs = src_str.split()
            for src in srcs:
                if os.path.exists(src):
                    if os.path.isdir(src):
                        d.appendVarFlag(task_name, 'file-checksums', ' %s/*:True' % (src))
                    else:
                        d.appendVarFlag(task_name, 'file-checksums', ' %s:True' % (src))
                else:
                    bb.warn('%s is not existed in %s of %s\n' % (src, task_name, d.getVar('PN')))
}

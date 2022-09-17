python() {
    import re

    dotconfig = os.path.join(d.getVar('TOPDIR'), 'config', '.config')
    extradeps = d.getVar('EXTRADEPS').split()
    weakdeps = []
    weakrdeps = []
    appenddeps = []
    appendrdeps = []

    for dep in extradeps:
        if '||' in dep:
            subdeps = dep.split('||')
            weakdeps += subdeps
            weakrdeps += subdeps
        elif '|' in dep:
            subdeps = dep.split('|')
            weakdeps += subdeps
        elif dep[0] == '?':
            if dep[1] == '?':
                weakdeps.append(dep[2:])
            else:
                weakdeps.append(dep[1:])
                weakrdeps.append(dep[1:])

    if os.path.exists(dotconfig) and (weakdeps or weakrdeps):
        for dep in weakdeps + weakrdeps:
            depname = dep.replace('.', '__dot__').replace('+', '__plus__').replace('-', '_').upper()
            with open(dotconfig, 'r') as fp:
                for per_line in fp:
                    ret = re.match(r'CONFIG_%s=y' % (depname), per_line)
                    if ret:
                        appenddeps.append(dep)
                        if dep in weakrdeps:
                            appendrdeps.append(dep)
                        break

    if appenddeps:
        d.appendVar('DEPENDS', ' %s' % (' '.join(appenddeps)))
    if appenddeps:
        d.appendVar('RDEPENDS:%s' % (d.getVar('PN')), ' %s' % (' '.join(appendrdeps)))
}

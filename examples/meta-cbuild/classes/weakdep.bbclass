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
            if not subdeps[0]:
                subdeps[0] = 'prebuild-' + subdeps[1]
            weakdeps += subdeps
            weakrdeps += subdeps
        elif '|' in dep:
            subdeps = dep.split('|')
            if not subdeps[0]:
                subdeps[0] = 'prebuild-' + subdeps[1]
            weakdeps += subdeps
        elif dep[0] == '&' or dep[0] == '?':
            amp_num = 0
            que_num = 0
            for i in range(len(dep)):
                if dep[i] == '&':
                    amp_num += 1
                elif dep[i] == '?':
                    que_num += 1
                else:
                    break
            dep = dep[amp_num + que_num:]
            if que_num == 2:
                weakdeps.append(dep)
                weakrdeps.append(dep)
            elif que_num == 1:
                weakdeps.append(dep)
            else:
                pass

    if os.path.exists(dotconfig) and weakdeps:
        for dep in weakdeps:
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
    if appendrdeps:
        d.appendVar('RDEPENDS:%s' % (d.getVar('PN')), ' %s' % (' '.join(appendrdeps)))
}

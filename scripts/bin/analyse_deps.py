import sys, os, re
from argparse import ArgumentParser

class Deps:
    def __init__(self):
        self.PathList = []
        self.ItemList = []
        self.TargetList = []
        self.FinallyList = []
        self.VirtualDict = {}

        self.conf_name = ''
        self.conf_str = ''
        self.keywords = []
        self.prepend_flag = 0


    def __add_virtual_deps(self, vir_name, root, rootdir):
        vir_path = os.path.join(root, vir_name)
        with open(vir_path, 'r') as fp:
            for per_line in fp:
                ret = re.match(r'#VDEPS\s*\(\s*([\w\*]+)\s*\)\s*:\s*([\w\-]+)\s*([\w\-\./]*)\s*([\w\-\./]*)', per_line)
                if not ret:
                    continue

                item = {}
                item['vtype'] = ret.groups()[0]
                item['target'] = ret.groups()[1]
                item['path'] = root
                item['spath'] = root.replace(rootdir + '/', '', 1)
                item['member'] = []
                append_path = ''

                if item['target'] in self.VirtualDict.keys():
                    print('ERROR: Repeated virtual dep(%s) in %s and %s' % (item['target'], item['path'], self.VirtualDict[item['target']]['path']))
                    sys.exit(1)

                if item['vtype'] == 'choice':
                    item['default'] = ''
                    if ret.groups()[2]:
                        item['default'] = ret.groups()[2]

                elif item['vtype'] == '*choice':
                    item['default'] = ''
                    if ret.groups()[2]:
                        if ret.groups()[2][0] != '/':
                            item['default'] = ret.groups()[2]
                            if ret.groups()[3]:
                                append_path = ret.groups()[3]
                        else:
                            append_path = ret.groups()[2]

                elif item['vtype'] == '*depend':
                    item['default'] = True
                    if ret.groups()[2]:
                        if ret.groups()[2] == 'unselect':
                            item['default'] = False
                            if ret.groups()[3]:
                                append_path = ret.groups()[3]
                        else:
                            append_path = ret.groups()[2]

                elif item['vtype'] == 'depend' or item['vtype'] == 'select' or item['vtype'] == 'imply':
                    item['default'] = True
                    if ret.groups()[2]:
                        if ret.groups()[2] == 'unselect':
                            item['default'] = False
                else:
                    print('WARNING: Unrecognized virtual dep(%s) in %s, ignore it' % (item['target'], item['path']))
                    continue

                if append_path:
                    if append_path[0] != '/':
                        print('WARNING: Append path in virtual dep(%s) in %s should start with "/"' % (item['target'], item['path']))
                        sys.exit(1)
                    else:
                        item['spath'] += append_path

                self.VirtualDict[item['target']] = item
                self.PathList.append((item['path'], item['spath'], item['target']))


    def search_depends(self, dep_name, vir_name, search_dirs, ignore_dirs = []):
        for rootdir in search_dirs:
            if rootdir[-1] == '/':
                rootdir = rootdir[:-1]

            for root, dirs, files in os.walk(rootdir):
                if ignore_dirs and dirs:
                    for idir in ignore_dirs:
                        if idir in dirs:
                            dirs.remove(idir)

                if dirs:
                    dirs.sort()

                if vir_name and vir_name in files:
                    self.__add_virtual_deps(vir_name, root, rootdir)

                if dep_name in files:
                    self.PathList.append((root, root.replace(rootdir + '/', '', 1), ''))
                    dirs.clear() # don't continue to search sub dirs.


    def __set_virtual_params(self, item, target):
        if target in self.VirtualDict.keys():
            vitem = self.VirtualDict[target]

            if '*' in vitem['vtype']:
                print('WARNING: It is no nead to add virtual dep(%s) in %s, it is in directory dep %s' % (target, item['path'], vitem['path']))
            elif vitem['vtype'] == 'choice':
                vitem['member'].append(item)
                return False
            elif vitem['vtype'] == 'depend':
                item['vdeps'].append(target)
                vitem['member'].append(item['target'])
            elif vitem['vtype'] == 'select' or vitem['vtype'] == 'imply':
                vitem['member'].append(item['target'])
            else:
                pass
        else:
            print('WARNING: Invalid virtual dep(%s) in %s, ignore it' % (target, item['path']))

        return True


    def __add_item_to_list(self, item, refs):
        ipath = item['path']
        ilen = len(ipath)
        ispath = item['spath']
        islen = len(ispath)
        item_list = {}

        while refs:
            for ref in refs[-1]:
                rspath = ref['spath']
                rslen = len(rspath)
                if islen >= rslen and ispath[:rslen] == rspath and (islen == rslen or ispath[rslen] == '/'):
                    item_list = ref
                    break

            if item_list:
                break
            else:
                rpath = refs[-1][-1]['path']
                rlen = len(rpath)
                if ilen >= rlen and ipath[:rlen] == rpath and (ilen == rlen or ipath[rlen] == '/'):
                    if '*' in item['vtype']:
                        if ipath == rpath:
                            refs[-1].append(item)
                        else:
                            for ref in refs[-1]:
                                rspath = ref['spath']
                                rslen = len(rspath)
                                if islen >= rslen and ispath[:rslen] == rspath and (islen == rslen or ispath[rslen] == '/'):
                                    ref['member'].append(item)
                                    break
                            else:
                                refs.pop()
                                continue
                            break

                    if len(refs) == 1:
                        self.ItemList.append(item)
                    else:
                        for ref in refs[-2]:
                            rspath = ref['spath']
                            rslen = len(rspath)
                            if islen >= rslen and ispath[:rslen] == rspath and (islen == rslen or ispath[rslen] == '/'):
                                ref['member'].append(item)
                                break
                        else:
                            refs.pop()
                            continue
                    return
                else:
                    refs.pop()

        if item_list:
            item_list['member'].append(item)
        else:
            self.ItemList.append(item)

        if item['vtype']:
            if '*' in item['vtype']:
                refs.append([item])
        else:
            self.TargetList.append(item['target'])


    def add_item(self, pathpair, dep_name, refs):
        if pathpair[2]:
            item = self.VirtualDict[pathpair[2]]
            self.__add_item_to_list(item, refs)
            return

        dep_path = os.path.join(pathpair[0], dep_name)
        with open(dep_path, 'r') as fp:
            dep_flag = False
            ItemDict = {}

            for per_line in fp:
                # e.g. "#DEPS(mk.ext) a(clean install): b c"
                ret = re.match(r'#DEPS\s*\(\s*([\w\-\./]*)\s*\)\s*([\w\-\.]+)\s*\(([\s\w\-\.%]*)\)\s*:([\s\w\-\.\?\*&!=,]*)', per_line)
                if ret:
                    dep_flag = True
                    append_flag = True
                    item = {}

                    item['target'] = ret.groups()[1]
                    makestr = ret.groups()[0]
                    if makestr and '/' in makestr:
                        makes = os.path.split(makestr)
                        item['path'] = os.path.join(pathpair[0], makes[0])
                        item['spath'] = os.path.join(pathpair[1], makes[0])
                        item['make'] = makes[1]
                    else:
                        item['path'] = pathpair[0]
                        item['spath'] = pathpair[1]
                        item['make'] = makestr

                    targets = ret.groups()[2].strip()
                    if not targets:
                        item['targets'] = []
                    else:
                        item['targets'] = targets.split()

                    item['count'] = 0
                    item['vtype'] = ''
                    item['deps'] = []
                    item['wdeps'] = []
                    item['vdeps'] = []
                    item['edeps'] = []
                    item['select'] = []
                    item['imply'] = []
                    item['conflict'] = []
                    item['default'] = True
                    item['conf'] = item['path'] if self.conf_name in os.listdir(item['path']) else ''

                    deps = ret.groups()[3].strip().split()
                    if deps:
                        for dep in deps:
                            if dep == 'nokconfig':
                                item['conf'] = ''
                            elif dep == 'unselect':
                                item['default'] = False
                            elif dep[0] == '!':
                                item['conflict'].append(dep[1:])
                            elif dep[0] == '&':
                                if dep[1] == '&':
                                    item['select'].append(dep[2:])
                                else:
                                    item['imply'].append(dep[1:])
                            elif dep[0] == '?':
                                if dep[1] == '?':
                                    item['wdeps'].append(dep[2:])
                                else:
                                    item['wdeps'].append(dep[1:])
                            elif dep[0] == '*':
                                append_flag = self.__set_virtual_params(item, dep[1:])
                            elif '=' in dep:
                                item['edeps'].append(dep)
                            else:
                                item['deps'].append(dep)
                                if 'finally' in item['deps']:
                                    self.FinallyList.append(item['target'])

                    if append_flag:
                        if makestr and '/' in makestr:
                            ItemDict[makestr] = item
                        else:
                            self.__add_item_to_list(item, refs)
                    continue

                ret = re.match(r'#INCDEPS\s*:\s*([\s\w\-\./]+)', per_line)
                if ret:
                    dep_flag = True
                    sub_paths = ret.groups()[0].split()
                    sub_paths.sort()

                    for sub_path in sub_paths:
                        sub_pathpair = (os.path.join(pathpair[0], sub_path), os.path.join(pathpair[1], sub_path), '')
                        sub_dep_path = os.path.join(sub_pathpair[0], dep_name)
                        if os.path.exists(sub_dep_path):
                            self.add_item(sub_pathpair, dep_name, refs)
                        else:
                            print('WARNING: ignore: %s' % sub_pathpair[0])

            if ItemDict:
                keys = [i for i in ItemDict.keys()]
                keys.sort()
                for key in keys:
                    self.__add_item_to_list(ItemDict[key], refs)

            if not dep_flag:
                print('WARNING: ignore: %s' % pathpair[0])


    def sort_items(self):
        temp = self.ItemList
        self.ItemList = []
        finally_flag = True

        while temp:
            lista = []
            listb = []
            for item in temp:
                if item['count'] == 0:
                    lista.append(item)
                else:
                    listb.append(item)

            if lista:
                for itema in lista:
                    for itemb in listb:
                        if itemb['deps'] and itema['target'] in itemb['deps']:
                            itemb['count'] -= 1
                        if itemb['wdeps'] and itema['target'] in itemb['wdeps']:
                            itemb['count'] -= 1
                self.ItemList += lista
                temp = listb

            elif finally_flag:
                finally_flag = False
                for itemb in listb:
                    if itemb['deps'] and 'finally' in itemb['deps']:
                        itemb['count'] -= 1
                temp = listb

            else:
                remainder_deps = []
                print('--------remainder deps--------')
                for itemb in listb:
                    print('%s: %s: %s' % (itemb['path'], itemb['target'], ' '.join(itemb['deps'] + itemb['wdeps'])))
                    remainder_deps += [dep for dep in itemb['deps'] if dep != 'finally' and dep not in self.TargetList]
                print('------------------------------')
                if remainder_deps:
                    remainder_deps = list(set(remainder_deps))
                    print('ERROR: deps (%s) are not found!' % (' '.join(remainder_deps)))
                else:
                    print('ERROR: circular deps!')
                print('------------------------------')

                return -1

        return 0


    def __escape_toupper(self, var):
        return var.replace('-', '_').upper()


    def __write_one_kconfig(self, fp, choice_flag, item):
        config_prepend = ''
        if self.prepend_flag:
            config_prepend = 'CONFIG_'
        target = '%s%s' % (config_prepend, self.__escape_toupper(item['target']))

        if not choice_flag and item['conf']:
            fp.write('menuconfig %s\n' % (target))
        else:
            fp.write('config %s\n' % (target))

        if not choice_flag:
            fp.write('\tbool "%s (%s)"\n' % (item['target'], item['spath']))
            fp.write('\tdefault %s\n' % ('y' if item['default'] else 'n'))
        else:
            fp.write('\tbool "%s"\n' % (item['target']))

        deps = []
        if item['deps']:
            deps += ['%s%s' % (config_prepend, self.__escape_toupper(t)) for t in item['deps'] if t != 'finally']
        if item['conflict']:
            deps += ['!%s%s' % (config_prepend, self.__escape_toupper(t)) for t in item['conflict']]
        if item['vdeps']:
            deps += ['%s%s' % (config_prepend, self.__escape_toupper(t)) for t in item['vdeps']]
        if item['edeps']:
            for dep in item['edeps']:
                if '!=' in dep:
                    env_pair = dep.split('!=')
                    env_name = env_pair[0]
                    env_vals = env_pair[1].split(',')
                    deps += ['$(%s)!="%s"' % (env_name, t) for t in env_vals]
                else:
                    env_pair = dep.split('=')
                    env_name = env_pair[0]
                    env_vals = env_pair[1].split(',')
                    if deps:
                        deps.append('(%s)' % (' || '.join(['$(%s)="%s"' % (env_name, t) for t in env_vals])))
                    else:
                        deps.append('%s' % (' || '.join(['$(%s)="%s"' % (env_name, t) for t in env_vals])))
        if deps:
            fp.write('\tdepends on %s\n' % (' && '.join([t for t in deps])))

        if item['select']:
            for t in item['select']:
                fp.write('\tselect %s%s\n' % (config_prepend, self.__escape_toupper(t)))
        if item['imply']:
            for t in item['imply']:
                fp.write('\timply %s%s\n' % (config_prepend, self.__escape_toupper(t)))
        fp.write('\n')

        if item['conf']:
            if choice_flag:
                conf_str = 'if %s\nmenu "%s (%s)"\nsource "%s"\nendmenu\nendif\n\n' % (target,
                        item['target'], item['spath'], os.path.join(item['conf'], self.conf_name))
                self.conf_str += conf_str
            else:
                conf_str = 'if %s\nsource "%s"\nendif\n\n' % (target, os.path.join(item['conf'], self.conf_name))
                fp.write('%s' % (conf_str))


    def __write_one_vir_kconfig(self, fp, max_depth, item):
        config_prepend = ''
        if self.prepend_flag:
            config_prepend = 'CONFIG_'
        target = '%s%s' % (config_prepend, self.__escape_toupper(item['target']))

        if 'choice' in item['vtype']:
            fp.write('choice %s\n' % (target))
            fp.write('\tprompt "virtual %s (%s)"\n' % (item['target'], item['spath']))
            fp.write('\tdefault %s%s\n\n' % (config_prepend, self.__escape_toupper(item['default'])))
            self.gen_kconfig(fp, item['member'], max_depth, item['spath'], True)
            fp.write('endchoice\n\n')
            if self.conf_str:
                fp.write('%s\n' % (self.conf_str))
                self.conf_str = ''

        elif '*depend' == item['vtype']:
            fp.write('menuconfig %s\n' % (target))
            fp.write('\tbool "virtual %s (%s)"\n' % (item['target'], item['spath']))
            fp.write('\tdefault %s\n\n' % ('y' if item['default'] else 'n'))
            fp.write('if %s\n\n' % (target))
            self.gen_kconfig(fp, item['member'], max_depth, item['spath'], False)
            fp.write('endif\n\n')

        elif 'depend' == item['vtype'] or 'imply' == item['vtype'] or 'select' == item['vtype']:
                fp.write('config %s\n' % (target))
                fp.write('\tbool "virtual %s %s (%s)"\n' % (item['vtype'], item['target'], item['spath']))
                fp.write('\tdefault %s\n' % ('y' if item['default'] else 'n'))
                if 'depend' != item['vtype']:
                    for t in item['member']:
                        fp.write('\t%s %s%s\n' % (item['vtype'], config_prepend, self.__escape_toupper(t)))
                fp.write('\n')

        else:
            pass


    def gen_kconfig(self, fp, item_list, max_depth, prefix_str, choice_flag):
        if choice_flag:
            for item in item_list:
                self.__write_one_kconfig(fp, choice_flag, item)
            return

        cur_dirs = []
        cur_depth = -1

        for item in item_list:
            if item['vtype'] and not item['member']:
                continue

            depth = 0
            spath = ''
            dirs = []

            if item['vtype'] and '*' not in item['vtype']:
                spath = '%s/virtual-%s' % (item['spath'], item['target'])
            else:
                spath = item['spath']
            if prefix_str:
                spath = spath.replace(prefix_str + '/', '', 1)
            if self.keywords:
                dirs = [var for var in spath.split('/') if var not in self.keywords]
            else:
                dirs = spath.split('/')
            depth = len(dirs) - 1

            while cur_depth >= 0:
                back_flag = False
                if depth < cur_depth:
                    back_flag = True
                else:
                    for i in range(cur_depth, -1, -1):
                        if dirs[i] != cur_dirs[i]:
                            back_flag = True
                            break

                if back_flag:
                    cur_dirs.pop()
                    cur_depth -= 1
                    fp.write('endmenu\n\n')
                else:
                    break

            while depth > cur_depth + 1 and cur_depth < max_depth - 1:
                cur_depth += 1
                cur_dirs.append(dirs[cur_depth])
                fp.write('menu "%s"\n\n' % (dirs[cur_depth]))

            if item['vtype']:
                tmp_depth = max_depth - cur_depth
                if tmp_depth < 0:
                    tmp_depth = 0
                self.__write_one_vir_kconfig(fp, tmp_depth, item)
            else:
                self.__write_one_kconfig(fp, False, item)

        while cur_depth >= 0:
            cur_dirs.pop()
            cur_depth -= 1
            fp.write('endmenu\n\n')


    def gen_target(self, filename):
        with open(filename, 'w') as fp:
            for item in self.ItemList:
                if item['deps'] or item['wdeps']:
                    fp.write('%s:\t%s:\t%s\n' % (item['path'], item['target'],
                        ' '.join(item['deps'] + item['wdeps'])))
                else:
                    fp.write('%s:\t%s:\n' % (item['path'], item['target'],))


    def gen_make(self, filename):
        with open(filename, 'w') as fp:
            for item in self.ItemList:
                phony = []
                make = '@make'
                if item['targets'] and 'jobserver' in item['targets']:
                    make += ' $(BUILD_JOBS)'
                make += ' -s -C %s' % (item['path'])
                if item['make']:
                    make += ' -f %s' % (item['make'])

                fp.write('ifeq ($(CONFIG_%s), y)\n\n' % (self.__escape_toupper(item['target'])))

                if item['target'] in self.FinallyList:
                    ideps = self.FinallyList + item['deps'] + item['wdeps']
                    for dep in self.TargetList:
                        if dep not in ideps:
                            fp.write('ifeq ($(CONFIG_%s), y)\n' % (self.__escape_toupper(dep)))
                            fp.write('%s: %s\n' % (item['target'], dep))
                            fp.write('endif\n')
                    fp.write('\n')

                if item['wdeps']:
                    for dep in item['wdeps']:
                        fp.write('ifeq ($(CONFIG_%s), y)\n' % (self.__escape_toupper(dep)))
                        fp.write('%s: %s\n' % (item['target'], dep))
                        fp.write('endif\n')
                    fp.write('\n')

                deps = []
                if item['deps']:
                    if 'finally' in item['deps']:
                        deps = [i for i in item['deps'] if i != 'finally']
                    else:
                        deps = [i for i in item['deps']]
                if deps:
                    fp.write('%s: %s\n\n' % (item['target'], ' '.join(deps)))

                fp.write('ALL_TARGETS += %s\n' % (item['target']))
                fp.write('%s:\n' % (item['target']))
                if item['targets'] and 'prepare' in item['targets']:
                    fp.write('\t%s prepare\n' % (make))
                fp.write('\t%s\n' % (make))
                fp.write('\t%s install\n\n' % (make))
                phony.append(item['target'])

                fp.write('ALL_CLEAN_TARGETS += %s_clean\n' % (item['target']))
                fp.write('%s_clean:\n' % (item['target']))
                fp.write('\t%s clean\n\n' % (make))
                phony.append(item['target'] + '_clean')

                for t in item['targets']:
                    if t != 'all' and t != 'clean' and t != 'install' and t != 'prepare' and t != 'jobserver':
                        fp.write('%s_%s:\n' % (item['target'], t))
                        fp.write('\t%s $(patsubst %s_%%,%%,$@)\n\n' % (make, item['target']))
                        phony.append('%s_%s' % (item['target'], t))

                fp.write('.PHONY: %s\n\n' % (' '.join(phony)))
                fp.write('endif\n\n')

            fp.write('%s: %s\n' % ('all_targets', '$(ALL_TARGETS)'))


def parse_options():
    parser = ArgumentParser(
            description='Tool to generate Makefile with chain of dependence')

    parser.add_argument('-m', '--makefile',
            dest='makefile_out',
            help='Specify the output Makefile path.')

    parser.add_argument('-k', '--kconfig',
            dest='kconfig_out',
            help='Specify the output Kconfig path.')

    parser.add_argument('-d', '--dep',
            dest='dep_name',
            help='Specify the search dependence filename.')

    parser.add_argument('-c', '--conf',
            dest='conf_name',
            help='Specify the search config filename.')

    parser.add_argument('-v', '--virtual',
            dest='vir_name',
            help='Specify the virtual dependence filename.')

    parser.add_argument('-s', '--search',
            dest='search_dirs',
            help='Specify the search directorys.')

    parser.add_argument('-i', '--ignore',
            dest='ignore_dirs',
            help='Specify the ignore directorys.')

    parser.add_argument('-t', '--maxtier',
            dest='max_depth',
            help='Specify the max tier depth for menuconfig')

    parser.add_argument('-w', '--keyword',
            dest='keywords',
            help='Specify the filter keywords to decrease menuconfig depth')

    parser.add_argument('-p', '--prepend',
            dest='prepend_flag',
            help='Specify the prepend CONFIG_ in items of kconfig_out')

    args = parser.parse_args()
    if not args.makefile_out or not args.kconfig_out or \
            not args.dep_name or not args.conf_name or \
            not args.search_dirs:
        print('ERROR: Invalid parameters.\n')
        parser.print_help()
        sys.exit(1)

    return args


def do_analysis(args):
    makefile_out = args.makefile_out
    kconfig_out = args.kconfig_out
    target_out = os.path.join(os.path.dirname(kconfig_out), 'Target')

    dep_name = args.dep_name
    conf_name = args.conf_name
    vir_name = ''
    if args.vir_name:
        vir_name = args.vir_name

    search_dirs = [s.strip() for s in args.search_dirs.split(':')]
    ignore_dirs = []
    if args.ignore_dirs:
        ignore_dirs = [s.strip() for s in args.ignore_dirs.split(':')]

    max_depth = 0
    if args.max_depth:
        max_depth = int(args.max_depth)

    keywords = []
    if args.keywords:
        keywords = [s.strip() for s in args.keywords.split(':')]

    prepend_flag = 0
    if args.prepend_flag:
        prepend_flag = int(args.prepend_flag)

    deps = Deps()
    deps.conf_name = conf_name
    deps.keywords = keywords
    deps.prepend_flag = prepend_flag

    deps.search_depends(dep_name, vir_name, search_dirs, ignore_dirs)
    if not deps.PathList:
        print('ERROR: can not find any %s in %s.' % (dep_name, ':'.join(search_dirs)))
        sys.exit(1)

    refs = []
    for pathpair in deps.PathList:
        deps.add_item(pathpair, dep_name, refs)
    if not deps.ItemList:
        print('ERROR: can not find any targets in %s in %s.' % (dep_name, ':'.join(search_dirs)))
        sys.exit(1)

    item_list = []
    item_list += deps.ItemList
    for item in deps.VirtualDict.values():
        if 'choice' in item['vtype'] or '*' in item['vtype']:
            item_list += item['member']
        if 'choice' in item['vtype']:
            target_list = [v['target'] for v in item['member']]
            if (not item['default'] or item['default'] not in target_list) and target_list:
                item['default'] = target_list[0]
                print('WARNING: Invalid default value for virtual choice(%s) in %s, use the first member %s' %
                        (item['target'], item['path'], item['default']))

    for item in item_list:
        if item['vtype']:
            continue
        if item['wdeps']:
            wdeps = item['wdeps']
            item['wdeps'] = [dep for dep in wdeps if dep in deps.TargetList]
        item['count'] = len(item['deps']) + len(item['wdeps'])

    with open(kconfig_out, 'w') as fp:
        fp.write('mainmenu "Build Configuration"\n\n')
        deps.gen_kconfig(fp, deps.ItemList, max_depth, '', False)
    print('\033[32mGenerate %s OK.\033[0m' % kconfig_out)

    deps.ItemList = [item for item in item_list if not item['vtype']]
    deps.gen_target(target_out)
    if deps.sort_items() == -1:
        print('ERROR: sort_items() failed.')
        sys.exit(1)
    deps.gen_make(makefile_out)
    print('\033[32mGenerate %s OK.\033[0m' % makefile_out)


if __name__ == '__main__':
    args = parse_options()
    do_analysis(args)


import sys, os, re
from argparse import ArgumentParser

def escape_toupper(var):
    return var.replace('.', '__dot__').replace('+', '__plus__').replace('-', '_').upper()


def escape_tolower(var):
    return var.lower().replace('_', '-').replace('__dot__', '.').replace('__plus__', '+')


class Deps:
    def __init__(self):
        self.VarDict = {}
        self.PathList = []
        self.PokyList = []
        self.ItemList = []
        self.ActualList = []
        self.VirtualList = []
        self.FinallyList = []

        self.conf_name = ''
        self.conf_str = ''
        self.user_metas = []
        self.keywords = []
        self.prepend_flag = 0
        self.yocto_flag = False


    def __init_item(self, item):
        item['path'] = ''
        item['spath'] = ''
        item['make'] = ''
        item['vtype'] = ''
        item['member'] = []
        item['target'] = ''
        item['targets'] = []
        item['asdeps'] = []     # actual stong dependence
        item['vsdeps'] = []     # virtual strong dependences
        item['awdeps'] = []     # actual weak dependence
        item['vwdeps'] = []     # virtual weak dependence
        item['wrule'] = []      # weak dependence rules
        item['cdeps'] = []      # conflict dependences
        item['edeps'] = []      # env dependences
        item['acount'] = 0      # actual dependence items count
        item['select'] = []
        item['imply'] = []
        item['default'] = True
        item['conf'] = ''


    def get_env_vars(self, local_config):
        with open(local_config, 'r') as fp:
            for per_line in fp:
                ret = re.match(r'([\w\-\./]+)\s*=\s*"(.*)"', per_line)
                if ret:
                    self.VarDict[ret.groups()[0]] = ret.groups()[1]


    def get_search_dirs(self, layer_config):
        dirs = []
        flag = False
        with open(layer_config, 'r') as fp:
            for per_line in fp:
                if not flag:
                    if 'BBLAYERS ?=' in per_line:
                        flag = True
                else:
                    if '"' in per_line:
                        break
                    else:
                        print("\033[032mSearch Layer:\033[0m \033[44m%s\033[0m" % per_line[0:-2].strip())
                        dirs.append(per_line[0:-2].strip())
        return dirs


    def __get_kconfig_path(self, src_path):
        conf_path = src_path
        for key in self.VarDict.keys():
            var = '${%s}' % (key)
            if var in conf_path:
                conf_path = conf_path.replace(var, self.VarDict[key])

        if os.path.exists(conf_path) and self.conf_name in os.listdir(conf_path):
            return os.path.join(conf_path, self.conf_name)
        return ''


    def __get_append_flag(self, item, check_append):
        if not check_append:
            return True
        for vitem in self.VirtualList:
            if 'choice' == vitem['vtype'] and item['target'] in vitem['targets']:
                vitem['member'].append(item)
                return False
        return True


    def __set_item_deps(self, deps, item, check_append):
        if deps:
            for dep in deps:
                sdeps = 'asdeps'
                wdeps = 'awdeps'
                if dep[0] == '*':
                    dep = dep[1:]
                    sdeps = 'vsdeps'
                    wdeps = 'vwdeps'

                if dep == 'finally':
                    item['acount'] = 1
                    self.FinallyList.append(item['target'])
                elif dep == 'nokconfig':
                    item['conf'] = ''
                elif dep == 'unselect':
                    item['default'] = False
                elif dep[0] == '!':
                    item['cdeps'].append(dep[1:])
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
                    if amp_num == 2:
                        item['select'].append(dep)
                    elif amp_num == 1:
                        item['imply'].append(dep)
                    else:
                        pass
                    if que_num:
                        item[wdeps].append(dep)
                elif '=' in dep:
                    item['edeps'].append(dep)
                elif '|' in dep:
                    subdeps = dep.split('||') if '||' in dep else dep.split('|')
                    if not subdeps[0]:
                        subdeps[0] = 'prebuild-' + subdeps[1]
                    item[wdeps] += subdeps
                    item['wrule'].append(subdeps)
                else:
                    item[sdeps].append(dep)

        return self.__get_append_flag(item, check_append)


    def __add_virtual_deps(self, vir_name, root, rootdir):
        target_list = []
        vir_path = os.path.join(root, vir_name)
        with open(vir_path, 'r') as fp:
            for per_line in fp:
                ret = re.match(r'#VDEPS\s*\(\s*(\w+)\s*\)\s*([\w\-]+)\s*\(([\s\w\-\./]*)\)\s*:([\s\w\|\-\.\?\*&!=,]*)', per_line)
                if not ret:
                    continue

                item = {}
                self.__init_item(item)

                item['path'] = root
                if self.yocto_flag:
                    item['spath'] = root.replace(os.path.dirname(rootdir) + '/', '', 1)
                    item['make'] = vir_name
                else:
                    item['spath'] = root.replace(rootdir + '/', '', 1)

                item['vtype'] = ret.groups()[0]
                if item['vtype'] != 'menuconfig' and item['vtype'] != 'config' and \
                        item['vtype'] != 'menuchoice' and item['vtype'] != 'choice':
                    print('ERROR: Invalid virtual dep type (%s) in %s' % (item['vtype'], item['path']))
                    print('       Only support menuconfig config menuchoice choice')
                    sys.exit(1)

                item['target'] = ret.groups()[1]
                if item['target'] in target_list:
                    print('ERROR: Repeated virtual dep %s:%s' % (item['target'], item['path']))
                    sys.exit(1)

                targets = ret.groups()[2].strip().split()
                if targets:
                    for t in targets:
                        if t[0] == '/':
                            item['spath'] += t
                        elif 'choice' in item['vtype']:
                            item['targets'].append(t)
                        else:
                            print('WARNING: Only menuchoice and choice have groups[2] field in %s:%s' % (item['target'], item['path']))

                target_list.append(item['target'])
                self.__set_item_deps(ret.groups()[3].strip().split(), item, False)
                self.VirtualList.append(item)
                self.PathList.append((item['path'], item['spath'], item['target']))


    def search_normal_depends(self, dep_name, vir_name, search_dirs, ignore_dirs = [], go_on_dirs = []):
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
                    if not go_on_dirs or rootdir not in go_on_dirs:
                        dirs.clear() # don't continue to search sub dirs.


    def search_yocto_depends(self, vir_name, search_dirs, ignore_dirs = []):
        poky_targets = []
        for rootdir in search_dirs:
            if rootdir[-1] == '/':
                rootdir = rootdir[:-1]

            user_flag = False
            if self.user_metas and rootdir.split('/')[-1] in self.user_metas:
                user_flag = True

            for root, dirs, files in os.walk(rootdir):
                if ignore_dirs and dirs and user_flag:
                    for idir in ignore_dirs:
                        if idir in dirs:
                            dirs.remove(idir)

                if dirs:
                    dirs.sort()
                if files:
                    files.sort()

                if vir_name and vir_name in files:
                    self.__add_virtual_deps(vir_name, root, rootdir)

                for fname in files:
                    if fname.endswith('.bb') and '-native' not in fname:
                        item = {}
                        self.__init_item(item)

                        fullname = os.path.join(root, fname)
                        item['path'] = os.path.dirname(fullname)
                        item['spath'] = os.path.dirname(fullname.replace(os.path.dirname(rootdir) + '/', '', 1))
                        item['make'] = fname
                        item['target'] = fname[0:fname.rindex('_') if '_' in fname else fname.rindex('.')]

                        if not user_flag:
                            if item['target'] not in poky_targets:
                                item['default'] = False
                                self.PokyList.append(item)
                                poky_targets.append(item['target'])
                        else:
                            self.PathList.append((item['path'], item['spath'], '', item['make']))


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
                    if 'menu' in item['vtype']:
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

        if 'menu' in item['vtype']:
            refs.append([item])


    def add_normal_item(self, pathpair, dep_name, refs):
        if pathpair[2]:
            for item in self.VirtualList:
                if pathpair[2] == item['target']:
                    if self.__get_append_flag(item, True):
                        self.__add_item_to_list(item, refs)
                    break
            return

        dep_path = os.path.join(pathpair[0], dep_name)
        with open(dep_path, 'r') as fp:
            dep_flag = False
            ItemDict = {}

            for per_line in fp:
                # e.g. "#DEPS(mk.ext) a(clean install): b c"
                ret = re.match(r'#DEPS\s*\(\s*([\w\-\./]*)\s*\)\s*([\w\-\.]+)\s*\(([\s\w\-\.%]*)\)\s*:([\s\w\|\-\.\?\*&!=,]*)', per_line)
                if ret:
                    dep_flag = True
                    item = {}
                    self.__init_item(item)

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

                    item['conf'] = os.path.join(item['path'], self.conf_name) if self.conf_name in os.listdir(item['path']) else ''
                    if self.__set_item_deps(ret.groups()[3].strip().split(), item, True):
                        if makestr and '/' in makestr:
                            ItemDict[makestr] = item
                        else:
                            self.__add_item_to_list(item, refs)

                    self.ActualList.append(item)
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
                            self.add_normal_item(sub_pathpair, dep_name, refs)
                        else:
                            print('WARNING: ignore: %s' % sub_pathpair[0])

            if ItemDict:
                keys = [t for t in ItemDict.keys()]
                keys.sort()
                for key in keys:
                    self.__add_item_to_list(ItemDict[key], refs)

            if not dep_flag:
                print('WARNING: ignore: %s' % pathpair[0])


    def add_yocto_item(self, pathpair, refs):
        if pathpair[2]:
            for item in self.VirtualList:
                if pathpair[2] == item['target']:
                    if self.__get_append_flag(item, True):
                        self.__add_item_to_list(item, refs)
                    break
            return

        extra_deps = []
        item = {}
        self.__init_item(item)

        item['path'] = pathpair[0]
        item['spath'] = pathpair[1]
        item['make'] = pathpair[3]
        item['target'] = item['make'] [0:item['make'].rindex('_') if '_' in item['make'] else item['make'].rindex('.')]

        fullname = os.path.join(pathpair[0], pathpair[3])
        with open(fullname, 'r') as fp:
            for per_line in fp:
                ret = re.match(r'DEPENDS\s*\+?=\s*"(.*)"', per_line)
                if ret:
                    item['asdeps'] += [dep for dep in ret.groups()[0].strip().split() if '-native' not in dep]
                ret = re.match(r'EXTRADEPS\s*\+?=\s*"(.*)"', per_line)
                if ret:
                    extra_deps += [dep for dep in ret.groups()[0].strip().split() if '-native' not in dep]

        bbconfig_path = os.path.join(os.path.dirname(fullname), item['target'] + '.bbconfig')
        bbappend_path = '%sappend' % (fullname)
        if os.path.exists(bbconfig_path):
            item['conf'] = bbconfig_path
        elif os.path.exists(bbappend_path):
            with open(bbappend_path, 'r') as fp:
                for per_line in fp:
                    ret = re.match(r'EXTERNALSRC\s*=\s*"(.*)"', per_line)
                    if ret:
                        item['conf'] = self.__get_kconfig_path(ret.groups()[0])
                        break
        else:
            pass

        if self.__set_item_deps(extra_deps, item, True):
            self.__add_item_to_list(item, refs)

        self.ActualList.append(item)


    def check_item(self, item_list, target_list):
        for item in item_list[:]:
            if item['wrule']:
                for rule in item['wrule'][:]:
                    deps = []
                    for dep in rule[:]:
                        deps.append(dep)
                        if dep not in target_list:
                            rule.remove(dep)
                    if not rule:
                        item['wrule'].remove(rule)
                        if not item['vtype'] and deps[0] in item['awdeps']:
                            print('ERROR: All weak rule deps (%s) in %s:%s are not found' % ( \
                                ' '.join(deps), item['target'], item['path']))
                            sys.exit(1)

            for depid in ['asdeps', 'vsdeps', 'awdeps', 'vwdeps', 'cdeps', 'select', 'imply']:
                if item[depid]:
                    deps = item[depid]
                    item[depid] = [dep for dep in deps if dep in target_list]
                    if not self.yocto_flag and not item['vtype'] and 'asdeps' == depid:
                        rmdeps = [dep for dep in deps if dep not in item[depid]]
                        if rmdeps:
                            print('ERROR: deps (%s) in %s:%s are not found' % (' '.join(rmdeps), item['target'], item['path']))
                            sys.exit(1)
            item['acount'] += len(item['asdeps']) + len(item['awdeps'])

            if 'choice' in item['vtype']:
                depid = 'targets'
                if item[depid]:
                    deps = item[depid]
                    item[depid] = [dep for dep in deps if dep in target_list]
                if item['select']:
                    item['select'] = []
                    print('WARNING: choice item in %s:%s has "select" attr' % (item['target'], item['path']))
                if item['imply']:
                    item['imply'] = []
                    print('WARNING: choice item in %s:%s has "imply" attr' % (item['target'], item['path']))

            if item['member']:
                self.check_item(item['member'], target_list)
            else:
                if 'choice' in item['vtype'] or 'menu' in item['vtype']:
                    item_list.remove(item)
                    if item['target'] in target_list:
                        target_list.remove(item['target'])
                    self.VirtualList.remove(item)
                    print('WARNING: There is no members in virtual choice dep %s:%s' % (item['target'], item['path']))


    def sort_items(self, target_list):
        target_list = [item['target'] for item in self.ActualList]
        temp = self.ActualList
        self.ActualList = []
        finally_flag = True
        while temp:
            lista = []
            listb = []
            for item in temp:
                if item['acount'] == 0:
                    lista.append(item)
                else:
                    listb.append(item)

            if lista:
                for itema in lista:
                    for itemb in listb:
                        if itemb['asdeps'] and itema['target'] in itemb['asdeps']:
                            itemb['acount'] -= 1
                        if itemb['awdeps'] and itema['target'] in itemb['awdeps']:
                            itemb['acount'] -= 1
                self.ActualList += lista
                temp = listb
            elif finally_flag:
                finally_flag = False
                for itemb in listb:
                    if itemb['target'] in self.FinallyList:
                        itemb['acount'] -= 1
                temp = listb
            else:
                print('--------ERROR: circular deps--------')
                for itemb in listb:
                    print('%s: %s: %s' % (itemb['path'], itemb['target'], ' '.join(itemb['asdeps'] + itemb['awdeps'])))
                print('------------------------------------')
                return -1

        return 0


    def __write_one_kconfig(self, fp, item, choice_flag, max_depth):
        config_prepend = ''
        if self.prepend_flag:
            config_prepend = 'CONFIG_'
        target = '%s%s' % (config_prepend, escape_toupper(item['target']))

        if 'choice' in item['vtype']:
            fp.write('choice %s\n' % (target))
            fp.write('\tprompt "%s@virtual (%s)"\n' % (item['target'], item['spath']))
            if item['targets']:
                fp.write('\tdefault %s%s\n' % (config_prepend, escape_toupper(item['targets'][0])))
        elif 'menuconfig' == item['vtype']:
            fp.write('menuconfig %s\n' % (target))
            fp.write('\tbool "%s@virtual (%s)"\n' % (item['target'], item['spath']))
            fp.write('\tdefault %s\n' % ('y' if item['default'] else 'n'))
        elif 'config' == item['vtype']:
                fp.write('config %s\n' % (target))
                if not choice_flag:
                    fp.write('\tbool "%s@virtual (%s)"\n' % (item['target'], item['spath']))
                    fp.write('\tdefault %s\n' % ('y' if item['default'] else 'n'))
                else:
                    fp.write('\tbool "%s@virtual"\n' % (item['target']))
        else:
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
        if item['asdeps']:
            deps += ['%s%s' % (config_prepend, escape_toupper(t)) for t in item['asdeps']]
        if item['vsdeps']:
            deps += ['%s%s' % (config_prepend, escape_toupper(t)) for t in item['vsdeps']]
        if item['cdeps']:
            deps += ['!%s%s' % (config_prepend, escape_toupper(t)) for t in item['cdeps']]

        if item['wrule']:
            bracket_flag = True if deps or len(item['wrule']) > 1 or item['edeps'] else False
            for rule in item['wrule']:
                if len(rule) == 1:
                    deps.append('%s%s' % (config_prepend, escape_toupper(rule[0])))
                elif bracket_flag:
                    deps.append('(%s)' % (' || '.join(['%s%s' % (config_prepend, escape_toupper(t)) for t in rule])))
                else:
                    deps.append('%s' % (' || '.join(['%s%s' % (config_prepend, escape_toupper(t)) for t in rule])))

        if item['edeps']:
            bracket_flag = True if deps or len(item['edeps']) > 1 else False
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
                    if bracket_flag:
                        deps.append('(%s)' % (' || '.join(['$(%s)="%s"' % (env_name, t) for t in env_vals])))
                    else:
                        deps.append('%s' % (' || '.join(['$(%s)="%s"' % (env_name, t) for t in env_vals])))

        if deps:
            fp.write('\tdepends on %s\n' % (' && '.join(deps)))

        if item['select']:
            for t in item['select']:
                fp.write('\tselect %s%s\n' % (config_prepend, escape_toupper(t)))
        if item['imply']:
            for t in item['imply']:
                fp.write('\timply %s%s\n' % (config_prepend, escape_toupper(t)))
        fp.write('\n')

        if item['conf']:
            if choice_flag:
                conf_str = 'if %s\nmenu "%s (%s)"\nsource "%s"\nendmenu\nendif\n\n' % (target,
                        item['target'], item['spath'], item['conf'])
                self.conf_str += conf_str
            else:
                conf_str = 'if %s\nsource "%s"\nendif\n\n' % (target, item['conf'])
                fp.write('%s' % (conf_str))

        if 'choice' in item['vtype']:
            self.gen_kconfig(fp, item['member'], True, max_depth, item['spath'])
            fp.write('endchoice\n\n')
            if self.conf_str:
                fp.write('%s\n' % (self.conf_str))
                self.conf_str = ''
        elif 'menuconfig' == item['vtype']:
            fp.write('if %s\n\n' % (target))
            self.gen_kconfig(fp, item['member'], False, max_depth, item['spath'])
            fp.write('endif\n\n')
        else:
            pass


    def gen_kconfig(self, fp, item_list, choice_flag, max_depth, prefix_str):
        if choice_flag:
            for item in item_list:
                self.__write_one_kconfig(fp, item, choice_flag, max_depth)
            return

        cur_dirs = []
        cur_depth = -1

        for item in item_list:
            depth = 0
            spath = ''
            dirs = []

            if prefix_str:
                spath = spath.replace(prefix_str + '/', '', 1)
            else:
                spath = item['spath']
            if self.keywords:
                dirs = [t for t in spath.split('/') if t not in self.keywords]
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

            tmp_depth = 0
            if item['vtype']:
                tmp_depth = max_depth - cur_depth
                if tmp_depth < 0:
                    tmp_depth = 0
            self.__write_one_kconfig(fp, item, False, tmp_depth)

        while cur_depth >= 0:
            cur_dirs.pop()
            cur_depth -= 1
            fp.write('endmenu\n\n')


    def gen_normal_target(self, filename):
        with open(filename, 'w') as fp:
            for item in self.ActualList:
                if item['asdeps'] or item['awdeps']:
                    fp.write('%s:\t%s:\t%s\n' % (item['path'], item['target'],
                        ' '.join(item['asdeps'] + item['awdeps'])))
                else:
                    fp.write('%s:\t%s:\n' % (item['path'], item['target'],))


    def gen_yocto_target(self, filename):
        with open(filename, 'w') as fp:
            for item in self.PokyList + self.ActualList:
                fp.write('%s\n' % (item['target']))


    def gen_make(self, filename, target_list):
        with open(filename, 'w') as fp:
            for item in self.ActualList:
                phony = []
                make = '@make'
                if item['targets'] and 'jobserver' in item['targets']:
                    make += ' $(BUILD_JOBS)'
                make += ' -s -C %s' % (item['path'])
                if item['make']:
                    make += ' -f %s' % (item['make'])

                fp.write('ifeq ($(CONFIG_%s), y)\n\n' % (escape_toupper(item['target'])))

                if item['target'] in self.FinallyList:
                    ideps = self.FinallyList + item['asdeps'] + item['awdeps']
                    for dep in target_list:
                        if dep not in ideps:
                            fp.write('ifeq ($(CONFIG_%s), y)\n' % (escape_toupper(dep)))
                            fp.write('%s: %s\n' % (item['target'], dep))
                            fp.write('endif\n')
                    fp.write('\n')

                if item['awdeps']:
                    for dep in item['awdeps']:
                        fp.write('ifeq ($(CONFIG_%s), y)\n' % (escape_toupper(dep)))
                        fp.write('%s: %s\n' % (item['target'], dep))
                        fp.write('endif\n')
                    fp.write('\n')

                deps = []
                if item['asdeps']:
                    if 'finally' in item['asdeps']:
                        deps = [dep for dep in item['asdeps'] if dep != 'finally']
                    else:
                        deps = [dep for dep in item['asdeps']]
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
    parser = ArgumentParser( description='''
            Tool to generate build chain.
            do_normal_analysis must set options (-m -k -d -c -s) and can set options (-v -i -g -t -w -p).
            do_yocto_analysis must set options (-r -k -c) and can set options (-v -i -t -w -p).
            do_image_analysis must set options (-o -r -k) and can set options (-i).')).
            ''')

    parser.add_argument('-m', '--makefile',
            dest='makefile_out',
            help='Specify the output Makefile path.')

    parser.add_argument('-r', '--recipe',
            dest='recipe_out',
            help='Specify the path to store recipes.')

    parser.add_argument('-o', '--image',
            dest='image_out',
            help='Specify the output image recipe path.')

    parser.add_argument('-k', '--kconfig',
            dest='kconfig_out',
            help='Specify the path to store  Kconfig items.')

    parser.add_argument('-d', '--dep',
            dest='dep_name',
            help='Specify the search dependence filename.')

    parser.add_argument('-c', '--conf',
            dest='conf_name',
            help='Specify the search config filename or .config path.')

    parser.add_argument('-v', '--virtual',
            dest='vir_name',
            help='Specify the virtual dependence filename.')

    parser.add_argument('-s', '--search',
            dest='search_dirs',
            help='Specify the search directorys.')

    parser.add_argument('-i', '--ignore',
            dest='ignore_dirs',
            help='Specify the ignore directorys.')

    parser.add_argument('-g', '--go-on',
            dest='go_on_dirs',
            help='Specify the go on directorys.')

    parser.add_argument('-u', '--usermeta',
            dest='user_metas',
            help='Specify the user metas whose recipes will be selected by default')

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
    analysis_choice = ''
    success_flag = True

    if args.makefile_out:
        analysis_choice = 'normal'
        if not args.kconfig_out or not args.dep_name or not args.conf_name or not args.search_dirs:
            success_flag = False
    elif args.image_out:
        analysis_choice = 'image'
        if not args.recipe_out or not args.conf_name:
            success_flag = False
    elif args.recipe_out:
        analysis_choice = 'yocto'
        if not args.kconfig_out or not args.conf_name:
            success_flag = False
    else:
        success_flag = False

    if not success_flag:
        print('\033[31mERROR: Invalid parameters.\033[0m\n')
        parser.print_help()
        sys.exit(1)

    return (args, analysis_choice)


def do_normal_analysis(args):
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
    go_on_dirs = []
    if args.go_on_dirs:
        go_on_dirs = [s.strip() for s in args.go_on_dirs.split(':')]

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

    deps.search_normal_depends(dep_name, vir_name, search_dirs, ignore_dirs, go_on_dirs)
    if not deps.PathList:
        print('ERROR: can not find any %s in %s.' % (dep_name, ':'.join(search_dirs)))
        sys.exit(1)

    refs = []
    for pathpair in deps.PathList:
        deps.add_normal_item(pathpair, dep_name, refs)
    if not deps.ItemList:
        print('ERROR: can not find any targets in %s in %s.' % (dep_name, ':'.join(search_dirs)))
        sys.exit(1)

    target_list = [item['target'] for item in deps.ActualList] \
                + [item['target'] for item in deps.VirtualList if 'choice' not in item['vtype']]
    deps.check_item(deps.ItemList, target_list)
    with open(kconfig_out, 'w') as fp:
        fp.write('mainmenu "Build Configuration"\n\n')
        deps.gen_kconfig(fp, deps.ItemList, False, max_depth, '')
    print('\033[32mGenerate %s OK.\033[0m' % kconfig_out)

    target_list = [item['target'] for item in deps.ActualList]
    deps.gen_normal_target(target_out)
    if deps.sort_items(target_list) == -1:
        print('ERROR: sort_items() failed.')
        sys.exit(1)
    deps.gen_make(makefile_out, target_list)
    print('\033[32mGenerate %s OK.\033[0m' % makefile_out)


def do_yocto_analysis(args):
    recipe_out = args.recipe_out
    kconfig_out = args.kconfig_out

    conf_name = args.conf_name
    vir_name = ''
    if args.vir_name:
        vir_name = args.vir_name

    ignore_dirs = []
    if args.ignore_dirs:
        ignore_dirs = [s.strip() for s in args.ignore_dirs.split(':')]

    user_metas = []
    if args.user_metas:
        user_metas = [s.strip() for s in args.user_metas.split(':')]

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
    deps.user_metas = user_metas
    deps.keywords = keywords
    deps.prepend_flag = prepend_flag
    deps.yocto_flag = True

    deps.get_env_vars('conf/local.conf')
    search_dirs = deps.get_search_dirs('conf/bblayers.conf')
    if not search_dirs:
        print('ERROR: can not find any metas in %s.' % ('conf/bblayers.conf'))
        sys.exit(1)

    deps.search_yocto_depends(vir_name, search_dirs, ignore_dirs)
    if not deps.PathList and not deps.PokyList:
        print('ERROR: can not find any recipes in %s.' % (':'.join(search_dirs)))
        sys.exit(1)

    refs = []
    for pathpair in deps.PathList:
        deps.add_yocto_item(pathpair, refs)
    target_list = [item['target'] for item in deps.ActualList] \
                + [item['target'] for item in deps.VirtualList if 'choice' not in item['vtype']]
    deps.check_item(deps.ItemList, target_list)

    with open(kconfig_out, 'w') as fp:
        fp.write('mainmenu "Build Configuration"\n\n')
        if deps.PokyList:
            deps.gen_kconfig(fp, deps.PokyList, False, max_depth, '')
        if deps.ItemList:
            deps.gen_kconfig(fp, deps.ItemList, False, max_depth, '')
    deps.gen_yocto_target(recipe_out)
    print('\033[32mGenerate %s OK.\033[0m' % kconfig_out)


def do_image_analysis(args):
    recipe_out = args.recipe_out
    conf_name = args.conf_name
    image_out = args.image_out
    ignore_recipes = []
    if args.ignore_dirs:
        ignore_recipes = [s.strip() for s in args.ignore_dirs.split(':')]

    recipe_list = []
    with open(recipe_out, 'r') as rfp:
        for per_line in rfp:
            recipe_list.append(per_line[0:-1])

    with open(image_out, 'w') as wfp:
        wfp.write('IMAGE_INSTALL:append = " \\\n')
        with open(conf_name, 'r') as rfp:
            for per_line in rfp:
                ret = re.match(r'CONFIG_(.*)=y', per_line)
                if ret:
                    item = escape_tolower(ret.groups()[0])
                    if (not ignore_recipes or item not in ignore_recipes) and item in recipe_list:
                        wfp.write('\t\t\t%s \\\n' % item)
        wfp.write('\t\t\t"')
    print('\033[32mGenerate %s OK.\033[0m' % image_out)


if __name__ == '__main__':
    args, analysis_choice = parse_options()
    if 'normal' == analysis_choice:
        do_normal_analysis(args)
    elif 'yocto' == analysis_choice:
        do_yocto_analysis(args)
    else:
        do_image_analysis(args)


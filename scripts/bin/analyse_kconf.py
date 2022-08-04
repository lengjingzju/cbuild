import sys, os, re
from argparse import ArgumentParser

class Kconfs:
    def __init__(self):
        self.PathList = []
        self.ItemList = []

    def search_kconf(self, dep_name, kconf_name, search_dirs, ignore_dirs = []):
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

                if dep_name in files:
                    if kconf_name in files:
                        self.PathList.append((root, root.replace(rootdir + '/', '', 1)))
                    dirs.clear() # don't continue to search sub dirs.

    def add_item(self, pathpair, dep_name):
        dep_path = os.path.join(pathpair[0], dep_name)
        with open(dep_path, 'r') as fp:
            for per_line in fp:
                # e.g. "#DEPS(mk.ext) a(clean install): b c"
                ret = re.match(r'#DEPS\s*\(\s*([\w\-\.]*)\s*\)\s*([\w\-\.]+)\s*\(([\s\w\-\.%]*)\)\s*:([\s\w\-\.]*)', per_line)
                if ret:
                    item = {}
                    item['path'] = pathpair[0]
                    item['spath'] = pathpair[1]
                    item['target'] = ret.groups()[1]

                    self.ItemList.append(item)
                    return
            else:
                print('WARNING: ignore: %s' % pathpair[0])

    def __write_one_kconfig(self, fp, item, kconf_name):
        fp.write('menu "%s (%s)"\n' % (item['target'], item['spath']))
        fp.write('source "%s"\n' % (os.path.join(item['path'], kconf_name)))
        fp.write('endmenu\n\n')

    def gen_kconfig(self, filename, kconf_name, max_depth, keywords):
        with open(filename, 'w') as fp:
            cur_dirs = []
            cur_depth = -1
            fp.write('mainmenu "Package Configuration"\n\n')
            for item in self.ItemList:
                dirs = item['spath'].split('/')
                if keywords:
                    dirs = [ var for var in item['spath'].split('/') if var not in keywords]
                depth = len(dirs) - 1
                while cur_depth >= 0:
                    if depth < cur_depth or dirs[cur_depth] != cur_dirs[cur_depth]:
                        cur_dirs.pop()
                        cur_depth -= 1
                        fp.write('endmenu\n\n')
                    else:
                        break
                while depth > cur_depth + 1 and cur_depth < max_depth - 1:
                    cur_depth += 1
                    cur_dirs.append(dirs[cur_depth])
                    fp.write('menu "%s"\n\n' % (dirs[cur_depth]))
                    #print("%d %s %s" % (cur_depth, dirs[cur_depth], item['spath']))
                self.__write_one_kconfig(fp, item, kconf_name)

            while cur_depth >= 0:
                cur_dirs.pop()
                cur_depth -= 1
                fp.write('endmenu\n\n')


def parse_options():
    parser = ArgumentParser(
            description='Tool to generate Package Kconfig with chain of dependence')

    parser.add_argument('-k', '--kconfig',
            dest='kconfig_out',
            help='Specify the output Kconfig path.')

    parser.add_argument('-f', '--file',
            dest='dep_name',
            help='Specify the search dependence filename.')

    parser.add_argument('-m', '--menu',
            dest='kconf_name',
            help='Specify the search kconfig filename.')

    parser.add_argument('-d', '--dirs',
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

    args = parser.parse_args()
    if not args.kconfig_out or not args.kconf_name or \
            not args.dep_name or not args.search_dirs:
        print('ERROR: Invalid parameters.\n')
        parser.print_help()
        sys.exit(1)

    return args


def do_analysis(args):
    kconfig_out = args.kconfig_out
    dep_name = args.dep_name
    kconf_name = args.kconf_name
    search_dirs = [s.strip() for s in args.search_dirs.split(':')]
    ignore_dirs = []
    max_depth = 0
    keywords = []
    if args.ignore_dirs:
        ignore_dirs = [s.strip() for s in args.ignore_dirs.split(':')]
    if args.max_depth:
        max_depth = int(args.max_depth)
    if args.keywords:
        keywords = [s.strip() for s in args.keywords.split(':')]

    kconfs = Kconfs()
    kconfs.search_kconf(dep_name, kconf_name, search_dirs, ignore_dirs)
    if not kconfs.PathList:
        print('ERROR: can not find any %s in %s.' % (kconf_name, ':'.join(search_dirs)))
        sys.exit(1)

    for pathpair in kconfs.PathList:
        kconfs.add_item(pathpair, dep_name)
    if not kconfs.ItemList:
        print('ERROR: can not find any targets in %s in %s.' % (kconf_name, ':'.join(search_dirs)))
        sys.exit(1)

    kconfs.gen_kconfig(kconfig_out, kconf_name, max_depth, keywords)
    print('Analyse Kconfigs OK.')


if __name__ == '__main__':
    args = parse_options()
    do_analysis(args)


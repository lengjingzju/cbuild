import sys, os, re
from argparse import ArgumentParser

class Deps:
    def __init__(self):
        self.MakeList = []
        self.ItemList = []

    def search_make(self, search_file, search_dirs, ignore_dirs = []):
        for rootdir in search_dirs:
            if rootdir[-1] == '/':
                rootdir = rootdir[:-1]

            for root, dirs, files in os.walk(rootdir):
                if ignore_dirs and dirs:
                    for idir in ignore_dirs:
                        if idir in dirs:
                            dirs.remove(idir)

                if search_file in files:
                    fullname = os.path.join(root, search_file)
                    filename = os.path.dirname(fullname.replace(rootdir + '/', '', 1))
                    self.MakeList.append((fullname, filename))
                    dirs.clear() # don't continue to search sub dirs.

    def add_item(self, makefile):
        with open(makefile[0], 'r') as fp:
            for per_line in fp:
                # e.g. "#DEPS(mk.ext) a(clean install): b c"
                ret = re.match(r'#DEPS\s*\(\s*([\w\-\.]*)\s*\)\s*(\w+)\s*\(([\s\w%]*)\)\s*:([\s\w]*)', per_line)
                if ret:
                    item = {}
                    item['path'] = os.path.dirname(makefile[0])
                    item['spath'] = makefile[1]

                    item['make'] = ret.groups()[0]
                    item['target'] = ret.groups()[1]

                    targets = ret.groups()[2].strip()
                    if not targets:
                        item['targets'] = []
                    else:
                        item['targets'] = targets.split()

                    deps = ret.groups()[3].strip()
                    if not deps:
                        item['deps'] = []
                        item['count'] = 0
                    else:
                        item['deps'] = deps.split()
                        item['count'] = len(item['deps'])

                    #print('[Add] %s: %s: %s' % (item['path'], item['target'], ' '.join(item['deps'])))
                    self.ItemList.append(item)
                    return
            else:
                print('WARNING: ignore: %s' % makefile[0])

    def sort_items(self):
        temp = self.ItemList
        self.ItemList = []
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
                self.ItemList += lista
                temp = listb
            else:
                print('----ERROR: deps are wrong!----')
                for itemb in listb:
                    print('%s: %s: %s' % (itemb['path'], itemb['target'], ' '.join(itemb['deps'])))
                print('------------------------------')
                return -1

        return 0

    def gen_kconfig(self, filename):
        with open(filename, 'w') as fp:
            fp.write('mainmenu "Build Configuration"\n\n')

            for item in self.ItemList:
                fp.write('config %s\n' % (item['target'].upper()))
                fp.write('\tbool "%s (%s)"\n' % (item['target'], item['spath']))
                fp.write('\tdefault y\n')
                if item['deps']:
                    fp.write('\tdepends on %s\n' % (' && '.join([t.upper() for t in item['deps']])))
                fp.write('\n')


    def gen_make(self, filename):
        with open(filename, 'w') as fp:
            fp.write('ifeq ($(USING_DEPS_BUILD), y)\n')
            for item in self.ItemList:
                if item['deps']:
                    fp.write('ifeq ($(CONFIG_%s), y)\n' % (item['target'].upper()))
                    fp.write('%s: %s\n' % (item['target'], ' '.join(item['deps'])))
                    fp.write('endif\n\n')
            fp.write('endif\n\n')

            fp.write('########################################\n\n')
            for item in self.ItemList:
                phony = []
                make = ''
                if item['make']:
                    make = '@make -C %s -f %s' % (item['path'], item['make'])
                else:
                    make = '@make -C %s' % (item['path'])

                fp.write('ifeq ($(CONFIG_%s), y)\n\n' % (item['target'].upper()))
                fp.write('ALL_TARGETS += %s\n' % (item['target']))
                fp.write('%s:\n' % (item['target']))
                fp.write('\t%s\n\n' % (make))
                phony.append(item['target'])

                fp.write('ALL_CLEAN_TARGETS += %s_clean\n' % (item['target']))
                fp.write('%s_clean:\n' % (item['target']))
                fp.write('\t%s clean\n\n' % (make))
                phony.append(item['target'] + '_clean')

                for t in item['targets']:
                    if t != 'clean':
                        fp.write('%s_%s:\n' % (item['target'], t))
                        fp.write('\t%s $(patsubst %s_%%,%%,$@)\n\n' % (make, item['target']))
                        phony.append('%s_%s\n' % (item['target'], t))

                fp.write('.PHONY: %s\n\n' % (' '.join(phony)))
                fp.write('endif\n\n')


def parse_options():
    parser = ArgumentParser(
            description='Tool to generate Makefile with chain of dependence')

    parser.add_argument('-m', '--makefile',
            dest='makefile_out',
            help='Specify the output Makefile path.')

    parser.add_argument('-k', '--kconfig',
            dest='kconfig_out',
            help='Specify the output Kconfig path.')


    parser.add_argument('-f', '--file',
            dest='search_file',
            help='Specify the search filename.')

    parser.add_argument('-d', '--dirs',
            dest='search_dirs',
            help='Specify the search directorys.')

    parser.add_argument('-i', '--ignore',
            dest='ignore_dirs',
            help='Specify the ignore directorys.')

    args = parser.parse_args()
    if not args.makefile_out or not args.kconfig_out or \
            not args.search_file or not args.search_dirs:
        print('ERROR: Invalid parameters.\n')
        parser.print_help()
        sys.exit(1)

    return args


def do_analysis(args):
    makefile_out = args.makefile_out
    kconfig_out = args.kconfig_out
    search_file = args.search_file
    search_dirs = [s.strip() for s in args.search_dirs.split(':')]
    ignore_dirs = []
    if args.ignore_dirs:
        ignore_dirs = [s.strip() for s in args.ignore_dirs.split(':')]

    deps = Deps()
    deps.search_make(search_file, search_dirs, ignore_dirs)
    if not deps.MakeList:
        print('ERROR: can not find any %s in %s.' % (search_file, ':'.join(search_dirs)))
        sys.exit(1)

    for makefile in deps.MakeList:
        deps.add_item(makefile)
    if not deps.ItemList:
        print('ERROR: can not find any targets in %s in %s.' % (search_file, ':'.join(search_dirs)))
        sys.exit(1)

    deps.gen_kconfig(kconfig_out)
    if deps.sort_items() == -1:
        print('ERROR: sort_items() failed.')
        sys.exit(1)
    deps.gen_make(makefile_out)
    print('Analyse depends OK.')


if __name__ == '__main__':
    args = parse_options()
    do_analysis(args)

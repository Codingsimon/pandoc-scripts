import frontmatter
import fnmatch
import os
import io
from pprint import pprint
from shutil import copyfile, copytree, ignore_patterns
import subprocess
import distutils
from distutils import dir_util

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

class document_type:
    BOOK = 'BOOK'
    SINGLE = 'SINGLE'

basePath = os.path.abspath('.')

def print_header(text):
    print(bcolors.BOLD + bcolors.HEADER + text + bcolors.ENDC)

def print_info(text):
    print(bcolors.BOLD + bcolors.OKBLUE + text + bcolors.ENDC)

def print_underline(text):
    print(bcolors.BOLD + bcolors.UNDERLINE + text + bcolors.ENDC)

def find_markdown_files(path):
    '''
    Search for markdown files within inside a given path recursivly
    '''
    extensions = ['*.md', '*.pandoc']
    matches = []

    for root, dirnames, filenames in os.walk(path):
        dirnames[:] = [d for d in dirnames if d not in ['bin', '.pandoc', 'build']]
        for extension in extensions:
            for filename in fnmatch.filter(filenames, extension):
                matches.append(os.path.join(root, filename))
    return sorted(matches)

def get_documents_to_be_published(files):
    books = []
    singles = []

    for fname in sorted(files):
        with io.open(fname, mode='r', encoding='utf-8') as f:
            # Parse file's front matter
            post = frontmatter.load(f)

            # find documents which should be converted to pdf
            if 'create-pdf-document' in post.keys() and post['create-pdf-document']:
                # check for book
                if 'collection' in post.keys() and post['collection']:
                    books.append(fname)
                else:
                    singles.append(fname)

    return books, singles

def get_build_path(f):
    current_file_path = os.path.dirname(os.path.abspath(f))
    current_filename = os.path.basename(f)
    rel_path = os.path.relpath(current_file_path, basePath)
    output_dir = basePath + '/build/' + rel_path
    output_file = output_dir + '/' + current_filename
    return current_filename, output_dir, output_file

def create_document(file, type: document_type):
    print_info('Create PDF of type ' + type + ' for document ' + file)

    # get base directory for given file
    working_dir = os.path.dirname(os.path.abspath(file))
    print_underline('Working directory: ' + working_dir)

    # get target directory for building
    filename, build_dir, fullpath = get_build_path(file)
    print_underline('Build directory: ' + build_dir)
    print_underline('Target file: ' + fullpath)

    if type == document_type.BOOK:
        create_book(file, fullpath + '_build')
    elif type == document_type.SINGLE:
        create_single(file, fullpath)

def create_book(src, target):
    print_header('content files for ' + src)
    content_files = find_markdown_files(os.path.dirname(os.path.abspath(src)))
    pprint(content_files)

    main_content_file = True

    with open(target, 'w', encoding='utf-8') as outfile:
        for f in content_files:
            filename, dir, fullpath = get_build_path(f)
            if main_content_file:
                create_intermediate_file(f, fullpath)
                main_content_file = False
            else:
                create_intermediate_file(f, fullpath, include_frontmatter=False, add_header=True)
            with open(fullpath, encoding='utf-8') as infile:
                outfile.write(infile.read())
            outfile.write("\n")

def create_intermediate_file(source, target, include_frontmatter=True, add_header=False):
    print_underline('transform: ' + source + ' --> ' + target)

    apply_common_filters(source, target)

    if add_header:
        type = has_book_latex_type(target)
        if type is None:
            pandoc_add_header(target)
        else:
            if type == 'part':
                pandoc_add_part(target)
            elif type == 'chapter':
                pandoc_add_chapter(target)

    if has_subsection_latex_type(target):
        pandoc_promote_headers(target)

    if not include_frontmatter:
        remove_frontmatter(target)

def pandoc_promote_headers(file):
    command = ["pandoc", file, "--data-dir", basePath + "/.pandoc", "--atx-headers", "--filter", "promoteHeaders.hs", "-o", file, "-t", "markdown", "-s"]
    subprocess.run(command, cwd=os.path.dirname(os.path.abspath(file)))


def has_subsection_latex_type(file):
    with io.open(file, mode='r', encoding='utf-8') as f:
        # Parse file's front matter
        post = frontmatter.load(f, encoding='utf-8')

        # find documents which should be converted
        if 'latextype' in post.keys() and post['latextype'] in ['subsection']:
            return True
        else:
            return False

def apply_common_filters(source, target):
    pandoc_include_files(source, target)
    pandoc_replace_variables(target)
    pandoc_create_version_table(target)

def has_book_latex_type(file):
    with io.open(file, mode='r', encoding='utf-8') as f:
        # Parse file's front matter
        post = frontmatter.load(f, encoding='utf-8')

        # find documents which should be converted
        if 'latextype' in post.keys() and post['latextype'] in ['part', 'chapter']:
            return post['latextype']
        else:
            return None

def pandoc_add_part(file):
    command = ["pandoc", file, "--data-dir", basePath + "/.pandoc", "--atx-headers", "--filter", "pandoc-add-part.py", "-o", file, "-t", "markdown", "-s"]
    subprocess.run(command, cwd=os.path.dirname(os.path.abspath(file)))

def pandoc_add_chapter(file):
    command = ["pandoc", file, "--data-dir", basePath + "/.pandoc", "--atx-headers", "--filter", "pandoc-add-chapter.py", "-o", file, "-t", "markdown", "-s"]
    subprocess.run(command, cwd=os.path.dirname(os.path.abspath(file)))

def pandoc_include_files(src_file, target_file):
    command = ["pandoc", src_file, "--data-dir", basePath + "/.pandoc", "--atx-headers", "--filter", "pandoc_include.py", "-o", target_file, "-t", "markdown", "-s"]
    subprocess.run(command, cwd=os.path.dirname(os.path.abspath(src_file)))

def pandoc_replace_variables(file):
    command = ["pandoc", file, "--data-dir", basePath + "/.pandoc", "--atx-headers", "--lua-filter", "replace-variables.lua", "-o", file, "-t", "markdown", "-s"]
    subprocess.run(command, cwd=os.path.dirname(os.path.abspath(file)))

def pandoc_create_version_table(file):
    command = ["pandoc", file, "--data-dir", basePath + "/.pandoc", "--atx-headers", "--filter", "pandoc-add-version-table.py", "-o", file, "-t", "markdown", "-s"]
    subprocess.run(command, cwd=os.path.dirname(os.path.abspath(file)))

def remove_frontmatter(file):
    command = ["pandoc", file, "--data-dir", basePath + "/.pandoc", "--atx-headers", "-o", file, "-t", "markdown"]
    subprocess.run(command, cwd=os.path.dirname(os.path.abspath(file)))

def pandoc_add_header(file):
    command = ["pandoc", file, "--data-dir", basePath + "/.pandoc", "--atx-headers", "--filter", "pandoc-add-header.py", "-o", file, "-t", "markdown", "-s"]
    subprocess.run(command, cwd=os.path.dirname(os.path.abspath(file)))


def create_single(src, target):
    pass

def apply_global_filters(src, target):
    pass

def main():
    distutils.dir_util.remove_tree('./build')
    ignore = ignore_patterns('venv', 'build', '.pandoc', '.vscode', 'bin')
    copytree('.', './build', ignore=ignore)
    print_header('Basisverzeichnis: ' + basePath)

    # Search for all files within the base path recursivly
    markdown_files = find_markdown_files(basePath)

    # Search for books and single documents which should be published as pdf
    books, singles = get_documents_to_be_published(markdown_files)
    
    # create build and copy
    

    # create books
    print_header('Books:')
    pprint(books)
    [create_document(f, document_type.BOOK) for f in books]

    # create single documents
    print_header('Single documents:')
    pprint(singles)
    [create_document(f, document_type.SINGLE) for f in singles]

main()
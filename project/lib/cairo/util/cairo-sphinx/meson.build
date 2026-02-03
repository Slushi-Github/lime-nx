libcairo_sphinx_sources = [
  'fdr.c',
]

cairo_sphinx_sources = [
  'sphinx.c',
]

libcairosphinx = library('cairo-sphinx', libcairo_sphinx_sources,
  include_directories: [incbase, incsrc],
  dependencies: deps,
  install: true,
  install_dir: join_paths(get_option('prefix'), get_option('libdir'), 'cairo'),
)

libdir = join_paths(get_option('prefix'), get_option('libdir'))

cairosphinx_exe = executable('cairo-sphinx', cairo_sphinx_sources,
  include_directories: [incbase],
  c_args: ['-DLIBDIR="@0@"'.format(libdir)] + pthread_c_args,
  dependencies: deps + [glib_dep, rt_dep, libcairo_dep, cairoboilerplate_dep, libcairoscript_dep],
  link_with: [libcairosphinx],
  link_args: extra_link_args,
  install: true,
)

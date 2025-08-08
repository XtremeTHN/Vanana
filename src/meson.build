vanana_sources = [
  'main.vala',
  'application.vala',
  'api/gamebanana.vala',
  'api/submissions.vala'
]

vanana_deps = [
  config_dep,
  dependency('gtk4'),
  dependency('libsoup-3.0'),
  dependency('json-glib-1.0'),
  dependency('libadwaita-1', version: '>= 1.4'),
]

subdir('ui')

vanana_sources += gnome.compile_resources('vanana-resources',
  'vanana.gresource.xml',
  c_name: 'vanana',
  dependencies: blueprints
)



executable('vanana', vanana_sources,
  dependencies: vanana_deps,
  include_directories: config_inc,
       install: true,
)

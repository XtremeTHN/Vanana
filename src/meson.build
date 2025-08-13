vanana_sources = [
  'main.vala',
  'application.vala',
  'utils.vala',
  'api/gamebanana.vala',
  'api/submissions.vala',
  'sidebar.vala',
  'top_submission.vala',
  'cache.vala',
  'submission_item.vala',
  'home_page.vala',
  'mod_page.vala',
  'screenshot.vala',
  'window.vala'
]

vanana_deps = [
  config_dep,
  dependency('gio-2.0'),
  dependency('libsoup-3.0'),
  dependency('json-glib-1.0'),
  dependency('libadwaita-1', version: '>= 1.4'),
  dependency('gtk4'),

]


subdir('ui')

vanana_sources += gnome.compile_resources('vanana-resources',
  'vanana.gresource.xml',
  c_name: 'vanana',
  dependencies: blueprints
)

add_project_arguments('-g', '--save-temps', language: 'vala')

executable('vanana', vanana_sources,
  dependencies: vanana_deps,
  include_directories: config_inc,
       install: true,
)

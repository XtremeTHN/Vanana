vanana_sources = [
  'main.vala',
  'application.vala',
  'utils.vala',
  'api/gamebanana.vala',
  'api/submissions.vala',
  'api/manager.vala',
  'html.vala',
  'sidebar.vala',
  'download_row.vala',
  'sub_download_dialog.vala',
  'top_submission.vala',
  'cache.vala',
  'submission_item.vala',
  'pages/submission_page.vala',
  'pages/home_page.vala',
  'pages/mod_page.vala',
  'pages/wip_page.vala',
  'screenshot.vala',
  'window.vala',
]

vanana_deps = [
  config_dep,
  dependency('gio-2.0'),
  dependency('libsoup-3.0'),
  dependency('json-glib-1.0'),
  dependency('gee-0.8'),
  dependency('libxml-2.0'),
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

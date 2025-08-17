vanana_sources = [
  'main.vala',
  'application.vala',
  'utils.vala',
  'cache.vala',
  'api/gamebanana.vala',
  'api/submissions.vala',
  'api/manager.vala',
  'widgets/pages/submission_page.vala',
  'widgets/pages/home_page.vala',
  'widgets/pages/downloadable_page.vala',
  'widgets/pages/wip_page.vala',
  'widgets/pages/question_page.vala',
  'widgets/html.vala',
  'widgets/comment.vala',
  'widgets/sidebar.vala',
  'widgets/download_row.vala',
  'widgets/sub_download_dialog.vala',
  'widgets/top_submission.vala',
  'widgets/submission_item.vala',
  'widgets/screenshot.vala',
  'widgets/window.vala',
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

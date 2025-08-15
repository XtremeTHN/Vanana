blueprints = custom_target('blueprints',
  input: files(
    'home-page.blp',
    'sidebar.blp',
    'mod-page.blp',
    'screenshot.blp',
    'download-dialog.blp',
    'download-row.blp',
    'submission-item.blp',
    'top-submission.blp',
    'window.blp'
  ),
  output: '.',
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)
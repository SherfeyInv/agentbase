gulp = require 'gulp'
concat = require 'gulp-concat'
coffee = require 'gulp-coffee'
sourcemaps = require 'gulp-sourcemaps'
docco = require 'gulp-docco'
uglify = require 'gulp-uglify'
rename = require 'gulp-rename'
lazypipe = require 'lazypipe'
taskList = require 'gulp-task-listing'
fs = require 'fs'
path = require 'path'
optparse = require 'optparse'

readFilePaths = (sourceDir, firstFiles) ->
  fileNames = firstFiles.concat(fs.readdirSync(sourceDir)
  .filter (file) -> file not in firstFiles)
  fileNames.map (name) ->
    sourceDir + name

FilePaths = readFilePaths 'src/',
  'util util_array array util_shapes set breed_set'
    .split(' ').map (n) -> n + '.coffee'

SpecFilePaths = readFilePaths 'spec/', ['shared.coffee']
 
# Create "macro" pipes.  Note 'pipe(name,args)' not 'pipe(name(args))'
# https://github.com/OverZealous/lazypipe
jsTasks = lazypipe() # write .js and .min.js into lib/
  .pipe gulp.dest, 'lib/'
  .pipe rename, {suffix: '.min'}
  .pipe uglify
  .pipe gulp.dest, 'lib/'

coffeeTasks = lazypipe()
  .pipe gulp.dest, 'lib/' # .coffee files used by specs
#  .pipe sourcemaps.init # Currently not working, wait for sourcemaps update
  .pipe coffee
#  .pipe sourcemaps.write, '.'
  .pipe jsTasks

gulp.task 'all', ['build', 'docs']

# Build tasks:
gulp.task 'build-agentscript', ->
  return gulp.src(FilePaths)
  .pipe concat('agentscript.coffee')
  .pipe coffeeTasks()

gulp.task 'build-extras-cs', ->
  return gulp.src('extras/*.coffee')
  .pipe coffeeTasks()

gulp.task 'build-extras-js', ->
  return gulp.src('extras/*.js')
  .pipe jsTasks()

gulp.task 'build-specs', ->
  return gulp.src(SpecFilePaths)
  .pipe concat('spec.coffee')
  .pipe coffeeTasks()

gulp.task 'build-extras', ['build-extras-cs','build-extras-js']
gulp.task 'build', ['build-agentscript', 'build-extras', 'build-specs']

# Watch tasks
gulp.task 'watch', ->
  gulp.watch 'src/*.coffee',
    ['build-agentscript']

  gulp.watch 'extras/*.js', ->
    console.log event
    gulp.src event.path
    .pipe jsTasks()

  gulp.watch 'extras/*.coffee', ->
    console.log event
    gulp.src event.path
    .pipe coffeeTasks()

  gulp.watch 'spec/*.coffee',
    ['build-specs']

# Documentation tasks
gulp.task 'docs', ->
  return gulp.src ["src/*coffee", "extras/*.{coffee,js}", "models/template.coffee"]
  .pipe docco()
  .pipe gulp.dest('docs/')

# Git tasks: we mainly have these to avoid gh-pages conflicts
# gulp.task('git:prep', )

# Default: list out tasks
gulp.task 'default', taskList

###
option '-f', '--file [DIR]', 'Path to test file or test file name'
task 'test', 'Testing code', (options) ->
  file = 'spec/'
  if options.file
    name = options.file.replace /spec\//, ''
    name = name.replace /\.spec.coffee/, ''
    file += name + '.spec.coffee'

  shell.exec "./node_modules/jasmine-node/bin/jasmine-node --coffee " +
    "--verbose --captureExceptions " + file, async: true
###

###
Notes:
  - coffee: add sourcemaps?
    Doesn't have the Generated by CoffeeScript 1.7.1 comment
  - add jsHint?
  - node_modules/.bin/gulp
  - why-do-we-need-to-install-gulp-globally-and-locally http://goo.gl/OhdWvO
  - http://substack.net/task_automation_with_npm_run
  - agentscript watch can report event like so:
  var watcher = gulp.watch(FilePaths, ['build-agentscript']);
  watcher.on('change', function(event) {
    console.log(event);
  });
  -or-
###

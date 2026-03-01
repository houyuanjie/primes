# frozen_string_literal: true

require 'rake/clean'

desc 'Build libraries.'
task :build do
  sh 'zig build'
end

CLEAN << '.zig-cache/'
CLEAN << 'zig-out/'

task default: :build

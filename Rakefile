require 'fileutils'
require 'erb'
include ERB::Util
require 'rubygems'
require 'active_support'
require 'fspath'
require 'rake'
require 'highline/import'

class IndexHelpers
  class << self
    def get_binding
      binding
    end

    def rubies
      FSPath(PATHS[:rb]).glob('docs', 'ruby-*').map{ |path| path.basename.to_s[/^ruby\-(\d+\.\d+\.\d+\-p\d+).*$/, 1] }.compact
    end

    def rails
      FSPath(PATHS[:rb]).glob('docs', 'rails-*').map{ |path| path.basename.to_s[/^rails\-(\d+\.\d+\.\d+)$/, 1] }.compact
    end

    def gems
      FSPath(PATHS[:rb]).glob('docs', 'gems.*').map{ |path| path.basename.to_s[/^gems\.(.*)$/, 1] }.compact
    end

    def plugins
      FSPath(PATHS[:rb]).glob('docs', 'plugins.*').map{ |path| path.basename.to_s[/^plugins\.(.*)$/, 1] }.compact
    end
  end
end

PATHS = {}
YAML::load_file(FSPath('paths')).each do |name, path|
  PATHS[name.to_sym] = FSPath(path)
end

def write_index
  template = (FSPath(__FILE__).dirname + 'index.html.erb').read
  html = ERB.new(template, nil, '<>').result(IndexHelpers.get_binding)
  FSPath('index.html').write(html)
end

def run_with_branch_in(name, branch)
  Dir.chdir(name) do
    if File.basename(Dir.pwd) == name
      puts "In directory #{name.inspect} <<<"
      begin
        FSPath('.git/HEAD').write("ref: refs/heads/#{branch}\n")
        sh 'rm -r *' rescue nil
        yield
      rescue Exception => e
        puts e
      ensure
        sh 'rm -r *' rescue nil
        sh 'git checkout empty'
      end
      puts '>>>'
    end
  end
end

def cp_r_link(src, dst)
  Dir.chdir(src) do
    sh "pax -rw -l -L . #{dst}"
  end
end

task :default => :update

desc 'build index'
task :index do
  Dir.chdir 'root' do
    write_index
    system 'open', 'index.html'
  end
end

desc 'update'
task :update do
  commit_message = Time.now.strftime('%Y-%m-%d %H:%M:%S')
  tag_name = commit_message.gsub(':', '-').gsub(' ', '_')

  Dir.chdir 'root' do
    write_index
    sh 'git add -A'

    sh 'git', 'commit', '-m', commit_message rescue nil
    sh 'git push origin master'
  end

  PATHS.each do |name, src|
    run_with_branch_in name.to_s, 'gh-pages' do
      # # maybe I will need blank commit
      # sh 'git add -A'
      # sh 'git commit -m clean' rescue nil

      cp_r_link(src, FSPath.pwd)

      sh 'git add -A'
      sh 'git', 'commit', '-m', commit_message
      sh 'git', 'tag', tag_name
      sh 'git push --tags origin gh-pages'
    end
  end

  sh 'git gc-all'
end

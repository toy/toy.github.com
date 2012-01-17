require 'erb'
require 'yaml'
require 'fspath'
require 'raw_git_repo'

class IndexHelpers
  class << self
    def get_binding
      binding
    end

    def rubies
      FSPath(PATHS[:rb]).glob('docs', 'ruby-*').map{ |path| path.basename.to_s[/^ruby\-(\d+\.\d+\.\d+\-p\d+).*$/, 1] }.compact.uniq
    end

    def rails
      FSPath(PATHS[:rb]).glob('docs', 'rails-*').map{ |path| path.basename.to_s[/^rails\-(\d+\.\d+\.\d+)$/, 1] }.compact
    end

    def gems
      FSPath(PATHS[:rb]).glob('docs', 'gem.*').map{ |path| path.basename.to_s[/^gem\.(.*)$/, 1] }.compact
    end
  end
end

PATHS = {}
YAML::load_file(FSPath('paths')).each do |name, path|
  PATHS[name.to_sym] = FSPath(path)
end

file 'index.git' do
  sh 'git clone --bare git@github.com:toy/toy.github.com.git index.git'
end

PATHS.each do |name, path|
  file "#{name}.git" do
    sh "git clone --bare git@github.com:toy/#{name}.git #{name}.git"
  end
end

directory 'index'
task 'index/index.html' => 'index' do
  template = FSPath('index.html.erb').read
  html = ERB.new(template, nil, '<>').result(IndexHelpers.get_binding)
  FSPath('index/index.html').write(html)
end

commit_message = Time.now.strftime('%Y-%m-%d %H:%M:%S')
tag_name = commit_message.gsub(':', '-').gsub(' ', '_')

namespace :update do
  desc 'update index'
  task :index => %w[index.git index/index.html] do
    puts 'index.git'
    repo = RawGitRepo.new('index.git')
    tree = repo.tree_for('index')
    if tree != repo.head_tree
      commit = repo.commit(tree, commit_message, [])
      repo.update_ref('HEAD', commit)
      repo.gc
      repo.push
      repo.push_tags
    end
  end

  PATHS.each do |name, path|
    desc "update #{name} from #{path}"
    task name => "#{name}.git" do
      puts "#{name}.git"
      repo = RawGitRepo.new("#{name}.git")

      tree = repo.tree_for(path)
      if tree != repo.head_tree
        commit = repo.commit(tree, commit_message, [])
        repo.tag(commit, tag_name)
        repo.update_ref('HEAD', commit)
        repo.gc
        repo.push
        repo.push_tags
      end
    end
  end
end

desc 'update everything'
task :default => (PATHS.keys + %w[index]).map{ |name| "update:#{name}" }

require 'fileutils'
require 'pathname'
require 'erb'
include ERB::Util
require 'rubygems'
require 'activesupport'
require 'rake'
require 'highline/import'

class IndexHelpers
  class << self
    def get_binding
      binding
    end

    def ruby
      Pathname.glob("#{PATHES[:rb]}/docs/ruby-*").first.basename
    end

    def rails
      Pathname.glob("#{PATHES[:rb]}/docs/rails-*").first.basename
    end

    def gems
      Pathname.glob("#{PATHES[:rb]}/docs/gems.*").map{ |gem| gem.basename.to_s[/gems.(.*)/, 1] }
    end

    def plugins
      Pathname.glob("#{PATHES[:rb]}/docs/plugins.*").map{ |gem| gem.basename.to_s[/plugins.(.*)/, 1] }
    end

    def list(type, *items)
      %Q{<span class="list"><span class="parenthesis">[</span><span class="content #{type}">#{items.flatten.join(', ')}</span><span class="parenthesis">]</span></span>}
    end
  end
end

PATHES = {}
YAML::load_file(Pathname('pathes')).each do |name, path|
  PATHES[name.to_sym] = Pathname(path)
end

class Pathname
  def write(s)
    open('w'){ |f| f.write(s) }
  end
end

def write_index
  template = (Pathname(__FILE__).dirname + 'index.html.erb').read
  html = ERB.new(template, nil, '<>').result(IndexHelpers.get_binding)
  Pathname('index.html').write(html)
end

task :default => :update

desc 'build index'
task :index do
  Dir.chdir('master') do
    write_index
    system 'open', 'index.html'
  end
end

desc 'update'
task :update do
  commit_message = Time.now.strftime('%Y-%m-%d %H:%M:%S')
  tag_name = commit_message.gsub(':', '-').gsub(' ', '_')

  Dir.chdir('master') do
    begin
      exit unless File.basename(Dir.pwd) == 'master'
      sh 'git checkout master'
      sh 'rm -r *' rescue nil

      write_index
      sh 'git add -A'

      sh 'git', 'commit', '-m', commit_message
      sh 'git push origin master'
    rescue Exception
      sh 'rm -r *' rescue nil
      sh 'git checkout empty'
    end
  end

  PATHES.each do |name, path|
    Dir.chdir(name.to_s) do
      begin
        exit unless File.basename(Dir.pwd) == name.to_s
        sh 'git checkout gh-pages'
        sh 'rm -r *' rescue nil

        # # maybe I will need blank commit
        # sh 'git add -A'
        # sh 'git commit -m clean' rescue nil

        Pathname.glob("#{path}/*") do |src|
          cp_r src, '.'
        end

        sh 'git add -A'
        sh 'git', 'commit', '-m', commit_message
        sh 'git', 'tag', tag_name
        sh 'git push --tags origin gh-pages'
      rescue Exception
        sh 'rm -r *' rescue nil
        sh 'git checkout empty'
      end
    end
  end

end

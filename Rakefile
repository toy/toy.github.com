task :default => :update

desc 'update'
task :update do
  require 'fileutils'
  require 'pathname'
  require 'erb'
  include ERB::Util
  require 'rubygems'
  require 'activesupport'
  require 'rake'
  require 'highline/import'

  PATHES = {}
  YAML::load_file(Pathname('pathes')).each do |name, path|
    PATHES[name.to_sym] = Pathname(path)
  end

  class Pathname
    def write(s)
      open('w'){ |f| f.write(s) }
    end
  end

  class Helpers
    class << self
      def get_binding
        binding
      end

      def ruby
        Pathname.glob("#{PATHES[:r]}/docs/ruby-*").first.basename
      end

      def rails
        Pathname.glob("#{PATHES[:r]}/docs/rails-*").first.basename
      end

      def gems
        Pathname.glob("#{PATHES[:r]}/docs/gems.*").map{ |gem| gem.basename.to_s[/gems.(.*)/, 1] }
      end

      def plugins
        Pathname.glob("#{PATHES[:r]}/docs/plugins.*").map{ |gem| gem.basename.to_s[/plugins.(.*)/, 1] }
      end

      def list(type, *items)
        %Q{<span class="list"><span class="parenthesis">[</span><span class="content #{type}">#{items.flatten.join(', ')}</span><span class="parenthesis">]</span></span>}
      end
    end
  end

  template = Pathname('index.html.erb').read
  html = ERB.new(template, nil, '<>').result(Helpers.get_binding)

  Dir.chdir('master') do
    exit unless File.basename(Dir.pwd) == 'master'
    sh 'git checkout master'
    sh 'rm -r * || true'

    PATHES.each do |name, path|
      dst = Pathname(name.to_s)
      dst.mkpath
      Pathname.glob("#{path}/*") do |src|
        cp_r src, dst
      end
    end

    Pathname('index.html').write(html)

    sh 'git add -A'

    sdoc_all_version = Gem.searcher.find('sdoc_all').version.to_s
    sdoc_all_version = "sdoc_all-#{sdoc_all_version}"
    sh 'git', 'commit', '-e', '-m', sdoc_all_version

    tag_name = ask("tag:"){ |q| q.default = sdoc_all_version }
    sh 'git', 'tag', tag_name

    push = agree("push?")
    sh 'git push --tags' if push

    sh 'rm -r * || true'
  end

end

require 'rubygems'
require 'highline/import'
require 'rake'

task :default => :update

desc 'update'
task :update do
  require 'fileutils'
  require 'pathname'

  PATH = File.read('path')

  def all_entries
    Pathname.glob("#{PATH}/*") do |src|
      yield src, src.basename
    end
  end

  sh "git checkout master"
  begin
    all_entries do |src, dst|
      rm_r dst if dst.exist?
    end

    sh "git add -A"

    all_entries do |src, dst|
      if src.file?
        cp src, dst
      elsif src.directory?
        symlink src, dst
      end
    end

    all_entries do |src, dst|
      if src.file?
        sh "git add #{dst}"
      elsif src.directory?
        sh "git add -A #{dst}/*"
      end
    end

    sdoc_all_version = Gem.searcher.find('sdoc_all').version.to_s
    commit_message = ask("commit message:"){ |q| q.default = "sdoc_all-#{sdoc_all_version}" }
    tag_name = ask("tag:"){ |q| q.default = commit_message }
    push = agree("push?")

    sh 'git', 'commit', '-m', commit_message
    sh 'git', 'tag', tag_name
    sh "git push --tags" if push
  ensure
    all_entries do |src, dst|
      rm_r dst if dst.exist?
    end

    sh "git reset HEAD"
    sh "git checkout empty"
  end
end

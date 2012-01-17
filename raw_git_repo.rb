require 'shellwords'
require 'progress'

class RawGitRepo
  attr_reader :repo_path
  def initialize(repo_path)
    @repo_path = repo_path
  end

  def init(bare)
    system(git_command(%W[init -q --bare]))
  end

  def valid?
    system(git_command(%W[rev-parse]) + ' 2> /dev/null')
  end

  def empty?
    !system(git_command(%w[show-ref -q --head]))
  end

  def tree_for(path)
    treefier_pipe do |treefier|
      hasher_pipe do |hasher|
        tree_build(path.to_s, 0, hasher, treefier)
      end
    end
  end

  def commit(tree, message, parents)
    arguments = %W[commit-tree #{tree}]
    Array(parents).each do |parent|
      arguments += %W[-p #{parent}]
    end
    IO.popen(git_command(arguments), 'r+') do |f|
      f.puts message
      f.close_write
      f.read.strip
    end
  end

  def tag(commit, name)
    system(git_command(%W[tag #{name} #{commit}]))
  end

  def update_ref(ref, commit)
    system(git_command(%W[update-ref #{ref} #{commit}]))
  end

  def gc
    system(git_command(%W[gc]))
  end

  def push
    system(git_command(%W[push]))
  end

  def push_tags
    system(git_command(%W[push --tags]))
  end

  def commits
    IO.popen(git_command(%w[rev-list --all]), &:readlines).map(&:strip)
  end

  def head_tree
    head = {}
    IO.popen(git_command(%W[cat-file commit HEAD]), &:readlines).each do |line|
      name, value = line.strip.split(' ', 2)
      head[name] = value
    end
    head['tree']
  end

private

  def git_command(args)
    (%W[git --git-dir=#{repo_path}] + args).shelljoin
  end

  def hasher_pipe
    IO.popen(git_command(%W[hash-object -w --no-filters --stdin-paths]), 'r+') do |f|
      def f.hash(path)
        puts(path)
        gets.strip
      end
      yield f
    end
  end

  def treefier_pipe
    IO.popen(git_command(%w[mktree --batch]), 'r+') do |f|
      def f.hash(objects)
        puts objects
        puts
        gets.strip
      end
      yield f
    end
  end

  def tree_build(path, level, hasher, treefier)
    objects = []
    dir_children(path).send(level < 3 ? :with_progress : :each) do |child_name, child_path|
      case
      when File.file?(child_path)
        objects << "#{File.stat(child_path).mode.to_s(8)} blob #{hasher.hash(child_path)}\t#{child_name}"
      when File.directory?(child_path)
        objects << "040000 tree #{tree_build(child_path, level + 1, hasher, treefier)}\t#{child_name}"
      else
        warn "#{child_path} is not a file or directory"
      end
    end
    treefier.hash(objects)
  end

  def dir_children(path)
    Dir.foreach(path).map do |child_name|
      if child_name != '.' && child_name != '..'
        [child_name, File.join(path, child_name)]
      end
    end.compact
  end
end

require "tty-tree"

module Storage
  class Tree
    def initialize(name, children)
      @name = name
      @children = children
    end
    
    def name
      @name
    end
    
    def children
      @children
    end
    
    def toTTY
      tty_children = []
      @children.each do |child|
        if child.class == String
          tty_children << child
        else
          tty_children << child.toTTY
        end
      end
      return { @name => tty_children }
    end
    
    def show
      TTY::Tree[self.toTTY].render()
    end
    
    # Given the name of a directory in this tree, return a tree rooted at that directory
    def subtree(dir)
      @children.each do |tree|
        if tree.name == dir
          return tree
        end
      end
      raise "The directory '#{dir}' could not be found"
    end
    
    # Takes a path to a file and returns whether it exists in this tree
    def fileExists?(path)
      names = path.split("/").reject { |f| f.empty? }
      self.exists?(names[0..-2], names.last)
    end
    
    # Don't call this externally
    def exists?(dirs, file)
      if dirs.empty?
        return @children.filter{|c| c.class == String}.include? file
      else
        return self.subtree(dirs.first).exists?(dirs[1..-1], file)
      end
    end
  end
end

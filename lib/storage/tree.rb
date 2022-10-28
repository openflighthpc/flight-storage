require "tty-tree"

# All directories contain an array of their contents
module Storage
  class Tree
    def initialize(tree)
      @tree = tree
    end
    
    def tree
      @tree
    end
    
    def show
      TTY::Tree[@tree].render()
    end
    
    # Given the name of a directory in this tree, return a tree rooted at that directory
    def subtree(dir)
      @tree[@tree.keys[0]].filter{|item| item.class == Hash}.each do |hash|
        if hash.keys[0].to_s == dir
          return Tree.new(hash)
        end
      end
      raise "The directory '#{dir}' could not be found"
    end
    
    # Takes a path to a file and returns whether it exists in this tree
    def fileExists?(path)
      names = path.split("/").reject { |f| f.empty? }
      cur = self
      names[0..-2].each do |name|
        cur = cur.subtree(name)
      end
      cur.tree[cur.tree.keys[0]].filter{|item| item.class == String}.each do |file|
        if file == names[-1]
          return true
        end
      end
      return false
    end
  end
end

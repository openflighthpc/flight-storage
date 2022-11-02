#==============================================================================
# Copyright (C) 2022-present Alces Flight Ltd.
#
# This file is part of Flight Storage.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Storage is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Storage. If not, see:
#
# For more information on Flight Storage, please visit:
# https://github.com/openflighthpc/flight-storage
#==============================================================================
require "tty-tree"

module Storage
  class Tree
    attr_reader :name, :files, :subdirs
    
    def initialize(name, children)
      @name = name
      @files = []
      @subdirs = []
      children.each do |child|
        if child.is_a?(String)
          @files << child
        elsif child.is_a?(Hash)
          child.each do |k, v|
            @subdirs << Tree.new(k.to_s, v)
          end
        end
      end
      @files.sort!
      @subdirs.sort_by! { |d| d.name }
    end
    
    # Convert to a hash format that tty-tree can render properly
    def to_hash
      hash_children = []

      @files.each do |file|
        hash_children << file
      end

      @subdirs.each do |dir|
        hash_children << dir.to_hash
      end

      return { @name => hash_children }
    end
    
    def show
      TTY::Tree[self.to_hash].render
    end

    # Given the name of a directory in this tree, return a tree rooted at that directory
    # Accepts as many arguments as its given, squashed into a single array named *path
    # Recursively indexes children to find subdirectory at given path
    def dig(*path, iter: 0)
      # If path has length of zero, return top-level tree
      if path.length == 0
        return self
      end

      subdir = @subdirs.find { |c| c.name == path[iter] }

      if !subdir
        # No such subdirectory
        raise "The directory '#{File.join(*path)}' could not be found"
      elsif iter + 1 == path.length
        # Base case
        return subdir
      else
        # Continue with recursive indexing
        iter += 1
        subdir.dig(*path, iter: iter)
      end
    end
    
    # Given the name of a directory in this tree, return a tree rooted at that directory
    def subtree(dir)
      @subdirs.find { |c| c.name == dir }
    end
    
    # Takes a path to a file and returns whether it exists in this tree
    def file_exists?(path)
      names = path.split("/").reject(&:empty?)
      dir_arr = names[0..-2]
      file_name = names.last
      bottom_dir = dig(*dir_arr)

      bottom_dir.files.any? { |c| c == file_name }
    end
    
    protected
    
    def exists?(dirs, file)
      if dirs.empty?
        return @files.include?(file)
      else
        return self.subtree(dirs.first).exists?(dirs[1..], file)
      end
    end
  end
end

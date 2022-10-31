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
    attr_reader :name, :children
  
    def initialize(name, children)
      @name = name
      @children = children
    end
    
    # Convert to a format tty-tree can render properly
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
    
    # Don't call this externally, used alongside fileExists?
    def exists?(dirs, file)
      if dirs.empty?
        return @children.filter{|c| c.class == String}.include? file
      else
        return self.subtree(dirs.first).exists?(dirs[1..-1], file)
      end
    end
  end
end

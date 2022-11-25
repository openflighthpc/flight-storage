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
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Storage, please visit:
# https://github.com/openflighthpc/flight-storage
#==============================================================================
require 'dropbox_api'

require_relative '../client'
require_relative '../tree'

module Storage
  class DropboxClient < Client
    FRIENDLY_NAME = "Dropbox"
    
    TYPES = {
      file: DropboxApi::Metadata::File,
      directory: DropboxApi::Metadata::Folder
    }
  
    def self.creds_schema
      {
        access_token: String
      }
    end
    
    def list(path="/", tree: false)
      path = path.delete_prefix("/")
      subtree = dir_tree.dig(*path.split("/"))
      "".tap do |msg|
        if tree
          msg << subtree.show
        else
          subtree.subdirs.each do |child|
            msg << child.name + "/\n"
          end
          msg << subtree.files.join("\n")
        end
      end
    end
    
    def dir_tree
      @dir_tree ||= Tree.new("/", to_hash(""))
    end
    
    def pull(source, dest)
      if dir_tree.file_exists?(source)
        content = ""
        file = client.download(source) do |chunk|
          content << chunk
        end
        
        File.open(File.expand_path(dest), "w") do |f|
          f.write(content)
        end
        
      else
        raise ResourceNotFoundError, source
      end
      dest
    end
    
    def push(source, dest)
      if dir_tree.file_exists?(dest)
        raise ResourceExistsError, dest
      end
      if used_space + File.size(source) <= allocated_space
        File.open(source) do |file|
          client.upload_by_chunks(dest, file, {mute: true})
        end
      else
        raise InsufficientSpaceError.new(
                source, 
                pretty_filesize(File.size(source)),
                pretty_filesize(allocated_space - used_space)
                )
      end
    end
    
    def delete(path)
      if dir_tree.file_exists?(path)
        client.delete(path)
      else
        raise ResourceNotFoundError, path
      end
    end
    
    def mkdir(path, make_parents)
      begin
        if !make_parents
          dir_tree.dig(*path.split("/")[0..-2])
        end
        client.create_folder(path[0..-2])
      rescue DropboxApi::Errors::FolderConflictError
        raise ResourceExistsError, path
      end
    end
    
    def to_hash(prefix)

      children = client.list_folder(prefix).entries

      [].tap do |a|
        children.each do |child|
          if child.is_a?(TYPES[:file])
            a << child.name
          elsif child.is_a?(TYPES[:directory])
            a << {child.name => to_hash(prefix + "/" + child.name)}
          end
        end
      end
    end
    
    def client
      @client ||= DropboxApi::Client.new(@credentials[:access_token])
      # Attempt to access account
      begin
        @client.list_folder("", {limit: 1})
      rescue DropboxApi::Errors::ExpiredAccessTokenError
        raise ExpiredCredentialsError, FRIENDLY_NAME
      rescue DropboxApi::Errors::HttpError
        raise InvalidCredentialsError, FRIENDLY_NAME
      end
      @client
    end
    
    def allocated_space
      client.get_space_usage.to_hash["allocation"]["allocated"].to_i
    end
    
    def used_space
      client.get_space_usage.to_hash["used"].to_i
    end
    
    def filesize(src)
      pretty_filesize(client.get_metadata(src).size)
    end
  end
end

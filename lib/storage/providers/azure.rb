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
require 'azure/storage/file'

require_relative '../client'
require_relative '../tree'

module Storage
  class AzureClient < Client
    TYPES = {
      file: Azure::Storage::File::File,
      directory: Azure::Storage::File::Directory::Directory
    }

    def self.creds_schema
      {
        storage_account_name: String,
        storage_access_key: String,
        file_share_name: String
      }
    end

    def delete(file)
      delete_file(file)
    end

    def pull(src, dest)
      content = get_file(src)

      # Use File::WRONLY|File::CREAT|File::EXCL flags to
      # only write to file if it doesn't already exist.
      # We'll probably want to override this later if we add
      # a `--force` option
      File.open(
        File.expand_path(dest),
        File::WRONLY|File::CREAT|File::EXCL
      ) do |f|
        f.write(content)
      end

      return File.expand_path(dest)
    rescue Errno::EEXIST
      raise LocalResourceExistsError.new(dest)
    end

    def push(src, dest)
      content = File.open(src, 'rb') { |f| f.read }
      filename = File.basename(src)

      target_dir = File.dirname(dest)
      target_file = File.basename(dest)

      file = client.create_file(
        file_share_name,
        target_dir,
        target_file,
        content.size
      )

      client.put_file_range(
        file_share_name,
        target_dir,
        file.name,
        0,
        content.size - 1,
        content
      )
    end

    def list(path='', tree: false)
      contents = query_directory(path)

      dirs = contents.select { |c| c.is_a?(TYPES[:directory]) }
                     .map { |d| "#{d.name}/" }
                     .sort

      files = contents.select { |c| c.is_a?(TYPES[:file]) }
                      .map(&:name)
                      .sort

      (dirs + files).join("\n")
    end

    private

    def delete_file(src)
      path = src.split('/')
      dir = path.length == 1 ? '' : path[..-2].join('/')

      # ensure directory exists, as client doesn't tell you and
      # continues as normal if the directory doesn't exist
      query_directory(dir)

      client.delete_file(
        file_share_name,
        dir,
        path.last
      )

      src
    rescue Azure::Core::Http::HTTPError => e
      if e.message.include?("resource does not exist")
        raise ResourceNotFoundError.new(src)
      end
    end

    def get_file(src)
      path = src.split('/')
      dir = path.length == 1 ? '' : path[..-2].join('/')

      # ensure directory exists, as client doesn't tell you and
      # continues as normal if the directory doesn't exist
      query_directory(dir)

      file, content = client.get_file(
        file_share_name,
        dir,
        path.last
      )
      
      content
    rescue Azure::Core::Http::HTTPError => e
      if e.message.include?("resource does not exist")
        raise ResourceNotFoundError.new(src)
      end
    end

    def query_directory(directory='')
      client.list_directories_and_files(file_share_name, directory)
    rescue Azure::Core::Http::HTTPError => e
      if e.message.include?("resource does not exist")
        raise ResourceNotFoundError.new(directory)
      end
    end

    def file_share_name
      @credentials[:file_share_name]
    end

    def client
      @client ||= Azure::Storage::File::FileService.create(
        storage_account_name: @credentials[:storage_account_name],
        storage_access_key: @credentials[:storage_access_key]
      )
    end
  end
end

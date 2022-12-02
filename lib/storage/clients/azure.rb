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
require 'tempfile'

require_relative '../client'
require_relative '../tree'

module Storage
  class AzureClient < Client
    FRIENDLY_NAME = 'Azure Storage'
    MAX_FILESIZE = 52_428_800 # in bytes

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

    def filesize(src)
      pretty_filesize(get_file_properties(src)[:content_length])
    end

    def mkdir(path, parents: false)
      dig = path.split("/")[1..]
      target = dig.pop

      if parents
        dig.inject('') do |prev, par|
          create_directory(par)
          File.join(prev, par)
        end
      end

      if !query_directory(dig)
        raise ResourceNotFoundError.new("/#{dig.join('/')}")
      end

      create_directory(path)
    end

    def delete(file)
      delete_file(file)
    end

    def pull(src, dest)
      filesize = get_file_properties(src)[:content_length]

      # If file size is too big, we need to download in chunks
      # and concatenate the chunks later.

      if filesize > MAX_FILESIZE
        chunk_download(src, dest, filesize)
      else
        content = get_file(src)

        # Use File::WRONLY|File::CREAT|File::EXCL flags to
        # only write to file if it doesn't already exist.
        # We'll probably want to override this later if we add
        # a `--force` option
        File.open(
          File.expand_path(dest),
          'w+'
        ) do |f|
          f.write(content)
        end
      end

      return File.expand_path(dest)
    end

    def push(src, dest)
      filesize = File.size(src)

      target_dir = File.dirname(dest)
      target_file = File.basename(dest)

      file = client.create_file(
        file_share_name,
        target_dir,
        target_file,
        filesize
      )

      if filesize > MAX_FILESIZE
        chunk_upload(src, target_dir, target_file, filesize)
      else
        content = File.open(src, 'rb') { |f| f.read }
        filename = File.basename(src)

        client.put_file_range(
          file_share_name,
          target_dir,
          file.name,
          0,
          content.size - 1,
          content
        )
      end
    end

    def list(path='', tree: false)
      if tree
        dir_tree = query_tree(path)
        delve_path = path.split('/')

        # Create a nested hash for each directory we traverse
        # so they can all be printed properly by Tree#render
        full_tree = delve_path.reverse.inject(dir_tree) { |v, k| [{ k => v }] }
        Tree.new('/', full_tree).show
      else
        contents = query_directory(path)

        dirs = contents.select { |c| c.is_a?(TYPES[:directory]) }
                       .map { |d| "#{d.name}/" }
                       .sort

        files = contents.select { |c| c.is_a?(TYPES[:file]) }
                        .map(&:name)
                        .sort

        (dirs + files).join("\n")
      end
    end

    private

    def directory_exists?(directory)
      !!client.get_directory_properties(file_share_name, directory)
    rescue Azure::Core::Http::HTTPError => e
      false
    end

    def create_directory(path)
      return if directory_exists?(path)
      client.create_directory(file_share_name, path)
    end

    def split_path(src)
      path = src.split('/')
      dir = path.length == 1 ? '' : path[..-2].join('/')

      [dir, path.last]
    end

    def get_file_properties(src)
      dir, file = split_path(src)

      client.get_file_properties(
        file_share_name,
        dir,
        file
      ).properties
    end

    def delete_file(src)
      dir, file = split_path(src)

      # ensure directory exists, as client doesn't tell you and
      # continues as normal if the directory doesn't exist
      query_directory(dir)

      client.delete_file(
        file_share_name,
        dir,
        file
      )

      src
    rescue Azure::Core::Http::HTTPError => e
      if e.message.include?("resource does not exist")
        raise ResourceNotFoundError.new(src)
      end
    end

    def get_file(src)
      dir, file = split_path(src)

      # ensure directory exists, as client doesn't tell you and
      # continues as normal if the directory doesn't exist
      query_directory(dir)

      file, content = client.get_file(
        file_share_name,
        dir,
        file
      )
      
      content
    rescue Azure::Core::Http::HTTPError => e
      if e.message.include?("resource does not exist")
        raise ResourceNotFoundError.new(src)
      end
    end

    def chunk_upload(src, target_dir, target_file, filesize)
      max_upload = 4_000_000
      number_of_chunks = (filesize.to_f / max_upload).ceil

      File.open(src) do |f|
        number_of_chunks.times do |iter|
          to_read = max_upload
          buffer = f.read(to_read)

          start_range = iter * max_upload
          end_range = ((iter * max_upload) + buffer.bytesize) -1

          client.put_file_range(
            file_share_name,
            target_dir,
            target_file,
            start_range,
            end_range,
            buffer
          )
        end
      end
    end

    def chunk_download(src, dest, filesize)
      dir, file = split_path(src)

      number_of_chunks = (filesize.to_f / MAX_FILESIZE).ceil
      chunk_files = []

      number_of_chunks.times do |iter|
        start_range = iter * MAX_FILESIZE
        end_range = iter == number_of_chunks - 1 ?
          filesize :
          ((iter + 1) * MAX_FILESIZE) -1


        options = {
          start_range: start_range,
          end_range: end_range
        }

        _, content = client.get_file(
          file_share_name,
          dir,
          file,
          options
        )

        tempfile = Tempfile.new("#{file}-#{iter+1}.chunk")
        chunk_files << tempfile

        tempfile.write(content)
      end

      File.open(dest, 'w+') do |f|
        `cat #{chunk_files.map(&:path).join(' ')} > #{dest}`
      end
      chunk_files.map(&:unlink)
    end

    def query_tree(directory='')
      dir = client.list_directories_and_files(file_share_name, directory)

      [].tap do |a|
        dir.each do |child|
          if child.is_a?(TYPES[:file])
            a << child.name
          elsif child.is_a?(TYPES[:directory])
            a << { child.name => query_tree(File.join(directory, child.name)) }
          end
        end
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
    rescue Azure::Storage::Common::InvalidOptionsError => e
      raise InvalidCredentialsError.new(FRIENDLY_NAME)
    end
  end
end

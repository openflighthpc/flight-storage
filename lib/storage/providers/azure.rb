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
    def self.creds_schema
      {
        storage_account_name: String,
        storage_access_key: String,
        file_share_name: String
      }
    end

    def list(path='')
      contents = to_arr(query_directory(path))
      delve_path = path.split('/')
      delve_path.unshift('/') # Need a root dir denoter

      # Create a nested hash for each directory we traverse
      # so they can all be printed properly by Tree#render.
      full_tree = delve_path.reverse.inject(contents) do |v, k|
        [{ k => v }]
      end.first

      puts Tree.new(full_tree.first[0], full_tree.first[1]).show
    rescue Azure::Core::Http::HTTPError => e
      if e.message.include?("resource does not exist")
        raise ResourceNotFoundError.new(path)
      end
    end

    private

    def to_arr(array)
      [].tap do |a|
        array.each do |child|
          if child.is_a?(Azure::Storage::File::File)
            a << child.name
          elsif child.is_a?(Azure::Storage::File::Directory::Directory)
            a << { child.name => [] }
          end
        end
      end
    end

    def query_directory(directory='')
      client.list_directories_and_files(@credentials[:file_share_name], directory)
    end


    def client
      @client ||= Azure::Storage::File::FileService.create(
        storage_account_name: @credentials[:storage_account_name],
        storage_access_key: @credentials[:storage_access_key]
      )
    end
  end
end

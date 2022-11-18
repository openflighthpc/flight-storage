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
require_relative '../command'

module Storage
  module Commands
    class Push < Command
      def run
        # ARGS
        # [ source_file, destination ]

        valid_args = args.dup
        valid_args[1] = valid_args[1].dup&.prepend("/")
        valid_args = valid_args.map { |a| a&.gsub(%r{/+}, "/") }

        source = File.expand_path(valid_args[0])
        dest_file = File.basename(source)

        if valid_args[1] == nil
          # Push to root dir
          dest_dir = '/'
          destination = File.join(dest_dir, dest_file)
        else
          destination = File.join(valid_args[1], dest_file)
        end

        if !File.file?(source)
          raise LocalResourceNotFoundError.new(source)
        end

        filesize = client.pretty_filesize(File.size(source))
        puts "Uploading #{File.basename(source)} (#{filesize})"
        
        resource = client.push(source, destination)

        if resource
          puts "Resource '#{source}' uploaded to '#{destination}'"
        end
      end
    end
  end
end

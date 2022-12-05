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
    class Pull < Command
      def run
        # ARGS
        # [ source, destination ]
        # OPTS
        # [ recursive ]

        valid_args = args.dup
        valid_args[0] = valid_args[0].dup.prepend("/")
        valid_args = valid_args.map { |a| a&.gsub(%r{/+}, "/") }

        source = valid_args[0]
        dest_name = File.basename(source)

        if valid_args[1] == nil
          destination = File.join(Dir.pwd, dest_name)
        else
          destination = File.join(File.expand_path(valid_args[1]), dest_name)
        end

        if File.file?(destination) && !@options.recursive
          raise LocalResourceExistsError, destination
        elsif File.directory?(destination) && @options.recursive
          raise LocalResourceExistsError, destination
        end

        filesize = client.filesize(source)
        puts "Downloading #{dest_name} (#{filesize})..."

        resource = client.pull(source, destination, @options.recursive)

        if resource
          puts "Resource '#{source}' saved to '#{resource}'"
        end
      end
    end
  end
end

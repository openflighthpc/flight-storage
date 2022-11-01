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
require_relative 'commands'
require_relative 'errors'
require_relative 'version'

require 'tty/reader'
require 'commander'

module Storage
  module CLI
    PROGRAM_NAME = ENV.fetch('FLIGHT_PROGRAM_NAME','storage')

    extend Commander::Delegates
    program :application, "Flight Storage"
    program :name, PROGRAM_NAME
    program :version, "v#{Storage::VERSION}"
    program :description, '%DESCRIPTION%'
    program :help_paging, false
    default_command :help
    silent_trace!

    error_handler do |runner, e|
      case e
      when TTY::Reader::InputInterrupt
        $stderr.puts "\n#{Paint['WARNING', :underline, :yellow]}: Cancelled by user"
        exit(130)
      else
        Commander::Runner::DEFAULT_ERROR_HANDLER.call(runner, e)
      end
    end

    if ENV['TERM'] !~ /^xterm/ && ENV['TERM'] !~ /rxvt/
      Paint.mode = 0
    end

    class << self
      def cli_syntax(command, args_str = nil)
        command.syntax = [
          PROGRAM_NAME,
          command.name,
          args_str
        ].compact.join(' ')
      end
    end

    command :hello do |c|
      cli_syntax(c)
      c.summary = 'Say hello'
      c.action Commands, :hello
      c.description = <<EOF
Say hello.
EOF
    end
    alias_command :h, :hello

    command :configure do |c|
      cli_syntax(c)
      c.summary = 'Set cloud storage provider'
      c.action Commands, :configure
    end

    command :set do |c|
      cli_syntax(c)
      c.summary = 'Set credentials for chosen cloud storage provider'
      c.action Commands, :set
    end
  end
end

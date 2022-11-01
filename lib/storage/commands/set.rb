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
require 'tty-prompt'
require 'yaml'

require_relative '../client_factory'
require_relative '../command'

module Storage
  module Commands
    class Set < Command
      def run
        klass = ClientFactory::PROVIDERS[Config.provider][:klass]
        questions = to_questions(klass)
        answers = prompt.collect do
          questions.each do |question|
            key(question[:key]).ask(question[:text])
          end
        end

        if save_credentials(answers)
          puts "Credentials saved to #{Config.credentials_dir}/"
        end
      end

      private

      def save_credentials(credentials_hash)
        File.write(Config.credentials_file, YAML.dump(credentials_hash))
      end

      def to_questions(klass)
        klass.creds_schema.map do |k, v|
          friendly = k.to_s.gsub('_', ' ').capitalize
          text = "#{friendly}:"
          {
            key: k,
            text: text
          }
        end
      end

      def prompt
        @prompt ||= TTY::Prompt.new(help_color: :yellow)
      end
    end
  end
end

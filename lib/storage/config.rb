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
require 'xdg'
require 'tty-config'
require 'fileutils'
require 'yaml'

module Storage
  module Config
    class << self
      STORAGE_DIR_SUFFIX = File.join('flight','storage')

      def data
        @data ||= TTY::Config.new.tap do |cfg|
          cfg.append_path(File.join(root, 'etc'))
          begin
            cfg.read
          rescue TTY::Config::ReadError
            nil
          end
        end
      end

      def save_data
        FileUtils.mkdir_p(File.join(root, 'etc'))
        data.write(force: true)
      end

      def data_writable?
        File.writable?(File.join(root, 'etc'))
      end

      def user_data
        @user_data ||= TTY::Config.new.tap do |cfg|
          xdg_config.all.map do |p|
            File.join(p, STORAGE_DIR_SUFFIX)
          end.each(&cfg.method(:append_path))
          begin
            cfg.read
          rescue TTY::Config::ReadError
            nil
          end
        end
      end

      def save_user_data
        FileUtils.mkdir_p(
          File.join(
            xdg_config.home,
            STORAGE_DIR_SUFFIX
          )
        )
        user_data.write(force: true)
      end

      def path
        config_path_provider.path ||
          config_path_provider.paths.first
      end

      def root
        @root ||= File.expand_path(File.join(__dir__, '..', '..'))
      end

      def storage_path
        @storage_path ||= Pathname.new('flight/storage')
      end

      def provider
        provider = data.fetch(:provider)
        if provider.nil?
          raise "No provider set; please run `storage configure`"
        end
        provider.downcase.to_sym
      end

      def credentials
        FileUtils.touch(credentials_file)

        YAML.load_file(credentials_file)
      end

      def credentials_file
        file = File.join(credentials_dir, "#{provider.to_s}.yml")
        FileUtils.touch(file)

        @credentials_file ||= file
      end

      def credentials_dir
        # Expands to $HOME/.config/flight/credentials
        dir = storage_path.join('credentials').expand_path(xdg_config.home)
        FileUtils.mkdir_p(dir)

        @credentials_dir ||= dir
      end

      private

      def xdg_config
        @xdg_config ||= XDG::Config.new
      end

      def xdg_data
        @xdg_data ||= XDG::Data.new
      end

      def xdg_cache
        @xdg_cache ||= XDG::Cache.new
      end
    end
  end
end

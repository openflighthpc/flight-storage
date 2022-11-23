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

require_relative 'config'
require_relative 'clients/aws.rb'
require_relative 'clients/azure.rb'

module Storage
  class Provider
    PROVIDERS = {
      azure: {
        client: AzureClient,
        friendly_name: AzureClient::FRIENDLY_NAME
      },
      aws_s3: {
        client: AWSClient,
        friendly_name: AWSClient::FRIENDLY_NAME
      }
    }

    def client
      PROVIDERS[@name][:client].new(credentials)
    end

    def configured?
      client.validate_credentials
    end

    def credentials
      filepath = File.join(Config.credentials_dir, "#{@name.to_s}.yml")
      FileUtils.touch(filepath)

      YAML.load_file(filepath)
    end

    def friendly_name
      PROVIDERS[@name][:friendly_name]
    end

    def name
      @name.to_s
    end

    def initialize(name)
      raise "Invalid provider" unless PROVIDERS.keys.include?(name)
      @name = name
    end
  end
end

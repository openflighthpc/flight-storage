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
# For more information on Flight Storage, please visit:
# https://github.com/openflighthpc/flight-storage
#==============================================================================

require_relative 'clients/azure'
require_relative 'clients/aws'

module Storage
  class ClientFactory
    CLIENTS = {
      azure: {
        klass: AzureClient,
        friendly_name: AzureClient::FRIENDLY_NAME
      },
      aws_s3: {
        klass: AWSClient,
        friendly_name: AWSClient::FRIENDLY_NAME
      }
    }

    def self.for(client, credentials: {})
      raise "Invalid client type" unless valid_client?(client)
      (CLIENTS[client][:klass]).new(credentials)
    end

    private

    def self.valid_client?(client)
      CLIENTS.include?(client)
    end
  end
end

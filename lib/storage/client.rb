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

module Storage
  class Client
    ACTIONS = %w(list push pull delete)

    ACTIONS.each do |action|
      define_method(action) do |*args, **kwargs|
        raise AbstractMethodError.new "Action not defined for provider"
      end
    end

    def self.creds_schema
      Hash.new
    end

    def pretty_filesize(size)
      units = %w[B KiB MiB GiB]
      return '0.0 B' if size == 0

      exp = (Math.log(size) / Math.log(1024)).to_i
      exp += 1 if (size.to_f / 1024 ** exp >= 1024 - 0.05)
      exp = units.size - 1 if exp > units.size - 1

      '%.1f %s' % [size.to_f / 1024 ** exp, units[exp]]
    end

    attr_reader :credentials

    def initialize(credentials = {})
      raise "Invalid credentials" unless validate_credentials(credentials)
      @credentials = credentials
    end

    private

    def validate_credentials(creds)
      return false if !creds

      shape = self.class.creds_schema

      (shape.keys - creds.keys).empty? && creds.all? { |k, v| shape[k] === v }
    end
  end
end

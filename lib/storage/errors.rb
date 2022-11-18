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
  StorageError = Class.new(RuntimeError)
  AbstractMethodError = Class.new(StandardError)

  class InvalidCredentialsError < StandardError
    def initialize(provider)
      msg = "Invalid credentials given for provider '#{provider}'. Try 'storage configure' to set new credentials."
      super(msg)
    end
  end
  
  class ExpiredCredentialsError < StandardError
    def initialize(provider)
      msg = "Credentials for '#{provider}' have expired. Try 'storage configure' to set new credentials."
      super(msg)
    end
  end

  class ResourceNotFoundError < StandardError
    def initialize(path)
      msg = "Remote resource '#{path}' not found"
      super(msg)
    end
  end

  class LocalResourceNotFoundError < StandardError
    def initialize(path)
      msg = "Local resource '#{path}' not found"
      super(msg)
    end
  end

  class ResourceExistsError < StandardError
    def initialize(path)
      msg = "Remote resource already exists at '#{path}'"
      super(msg)
    end
  end

  class LocalResourceExistsError < StandardError
    def initialize(path)
      msg = "Resource already exists at local path '#{path}'"
      super(msg)
    end
  end
  
  class DirectoryNotEmptyError < StandardError
    def initialize(path)
      msg = "Directory '#{path}' is non-empty, use the '-r' option to delete it and all contents"
      super(msg)
    end
  end
end

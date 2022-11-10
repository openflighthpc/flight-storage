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
require 'aws-sdk-s3'

require_relative '../client'
require_relative '../tree'

module Storage
  class AWSClient < Client
    def self.creds_schema
      {
        access_key: String,
        secret_access_key: String,
        region: String,
        bucket_name: String
      }
    end
    
    def list(use_tree, path="/")
      subtree = tree.dig(*path.delete_prefix("/").split("/"))
      if use_tree
        puts subtree.show
      else
        subtree.subdirs.each do |child|
          puts child.name + "/"
        end
        puts subtree.files
      end
    end
    
    def tree
      @tree ||= Tree.new("/", self.to_hash("")[nil])
    end
    
    def pull(source, dest="./")
      if tree.file_exists?(source)
        path = File.expand_path(dest) + "/" + source.split("/").last
        
        source = source[1..-1] if source[0] == "/"
        File.open(path, 'w+b') do |file|
          resp = client.get_object(response_target: path, bucket: @credentials[:bucket_name], key: source)
        end
      else
        raise ResourceNotFoundError, source
      end
    end
    
    def push(source, dest="/")
      dest = dest.delete_prefix("/")
      tree.dig(*dest.split("/"))
      
      if File.file?(File.expand_path(source))
        obj = Aws::S3::Object.new(bucket_name: @credentials[:bucket_name], key: dest + source.split("/").last, :client => client)
        obj.upload_stream({part_size: 100 * 1024 * 1024, tempfile: true}) do |write_stream|
          IO.copy_stream(File.open(File.expand_path(source), "r"), write_stream)
        end
      else
        raise "File '#{source}' does not exist."
      end
    end
    
    def delete(path)
      path = path.delete_prefix("/")
      if tree.file_exists?(path)
        client.delete_object(bucket: @credentials[:bucket_name], key: path)
      else
        raise ResourceNotFoundError, path
      end
    end
    
    # Convert the bucket contents into a tree-like hash
    def to_hash(prefix)
      children = []
      resp = client.list_objects(bucket: @credentials[:bucket_name], delimiter: "/", prefix: prefix)
      dirs = resp.common_prefixes.map {|dir| dir = dir.prefix.split("/").last }
      while resp.is_truncated
        marker = resp.next_marker
        resp = client.list_objects(bucket: @credentials[:bucket_name], delimiter: "/", prefix: prefix, marker: marker)
        dirs += resp.common_prefixes.map {|dir| dir = dir.prefix.split("/").last }
      end
      dirs&.each do |dir|
        children << to_hash(prefix + dir + "/")
      end
      
      files = resource.bucket(@credentials[:bucket_name]).objects(delimiter: "/", prefix: prefix, start_after: prefix)
      files.collect(&:key)&.each do |file|
        children << file.split("/").last
      end
      return { prefix.split("/").last => children }
    end
    
    def client
      begin
        @client ||= Aws::S3::Client.new(
          access_key_id: @credentials[:access_key],
          secret_access_key: @credentials[:secret_access_key],
          region: @credentials[:region]
        )
        # Attempt to access the bucket
        @client.list_objects(bucket: @credentials[:bucket_name], max_keys: 0)
      rescue Aws::S3::Errors::InvalidAccessKeyId, Aws::S3::Errors::SignatureDoesNotMatch
        raise "Given AWS key ID and secret key do not match, try 'storage configure' to set valid credentials"
      rescue Aws::Errors::InvalidRegionError
        if @credentials[:region] == ""
          msg = "Region not set, try 'storage configure' to set a valid region"
        else
          msg = "Region '#{@credentials[:region]}' not valid, try 'storage configure' to set a valid region"
        end
        raise msg
      rescue Seahorse::Client::NetworkingError
        raise "Failed to connect to AWS. Check that your region is correctly configured and that you have a stable network connection."
      end
      @client
    end
    
    def resource
      @resource ||= Aws::S3::Resource.new(client: client)
    end
  end
end

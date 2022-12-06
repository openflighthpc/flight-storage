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
    FRIENDLY_NAME = "Amazon S3"
  
    def self.creds_schema
      {
        access_key: String,
        secret_access_key: String,
        region: String,
        bucket_name: String
      }
    end
    
    def list(path="/", tree: false)
      path = path.delete_prefix("/")
      if tree
        dir_tree.dig(*path.split("/")).show
      else
        directory_contents(path).join("\n")
      end
    end
    
    def dir_tree
      Tree.new("/", self.to_hash("")[nil])
    end
    
    def pull(source, dest, recursive)
      source = source.delete_prefix("/")
      raise ResourceNotFoundError, source unless exists?(source)
      if recursive
        Dir.mkdir(dest)
        source = source + "/" unless source[-1] == "/"
        directory_contents(source).each do |name|
          if name[-1] == "/"
            pull(source + name, dest + "/" + name, true)
          else
            pull_file(source + name, dest + "/" + name)
          end
        end
      else
        pull_file(source, dest)
      end
      dest
    end
    
    def pull_file(source, dest)
      if exists?(source)
        source = source.delete_prefix("/")
        
        resp = client.get_object(
                 response_target: dest, 
                 bucket: @credentials[:bucket_name], 
                 key: source
               )
      else
        raise ResourceNotFoundError, source
      end
      dest
    end
    
    def push(source, dest, recursive)
      if recursive
        mkdir(dest + "/", false)
        Dir.entries(source).each do |name|
          if name[0] != "."
            full_name = source + "/" + name
            if File.directory?(full_name)
              push(full_name, dest + "/" + name, true)
            elsif File.file?(full_name)
              push_file(full_name, dest + "/" + name)
            end
          end
        end
      else
        push_file(source, dest)
      end
    end
    
    def push_file(source, dest)
      dest = dest.delete_prefix("/")
      if exists?(dest)
        raise ResourceExistsError, dest
      end
      
      obj = Aws::S3::Object.new(
              bucket_name: @credentials[:bucket_name],
              key: dest,
              :client => client
            )
              
      obj.upload_stream({part_size: 100 * 1024 * 1024, tempfile: true}) do |write_stream|
        IO.copy_stream(File.open(source, "rb"), write_stream)
      end
    end
    
    def delete(path)
      path = path.delete_prefix("/")
      if exists?(path)
        client.delete_object(
          bucket: @credentials[:bucket_name],
          key: path
        )
      else
        raise ResourceNotFoundError, path
      end
    end
    
    def mkdir(path, make_parents)
      path = path.delete_prefix("/")
      if exists?(path)
        raise ResourceExistsError, path
      elsif make_parents
        dirs = path.split("/")
        index = 0
        while index < dirs.size
          client.put_object(
            bucket: @credentials[:bucket_name],
            key: (dirs[0..index].join("/") + "/")
          )
          index += 1
        end
        true
      else
        parent = path.split("/")[0..-2].join("/") + "/"
        if parent == "/" || exists?(parent)
          client.put_object(
            bucket: @credentials[:bucket_name],
            key: path
          )
        else
          raise ResourceNotFoundError, parent
        end
      end
    end
    
    def rmdir(path, recursive)
      path = path.delete_prefix("/")
      if exists?(path)
        objs = resource.bucket(@credentials[:bucket_name]).objects({prefix: path})
        dirs = path.split("/")
        if recursive || dir_tree.dig(*dirs).to_hash[dirs.last].empty?
          objs.batch_delete!
          true
        else
          raise DirectoryNotEmptyError, path
        end
      else
        raise ResourceNotFoundError, path
      end
    end
      
    
    # Convert the bucket contents into a tree-like hash
    def to_hash(prefix)
      children = []
      
      resp = client.list_objects_v2(
               bucket: @credentials[:bucket_name],
               delimiter: "/",
               prefix: prefix
             )
      
      dirs = resp.common_prefixes.map {|dir| dir = dir.prefix.split("/").last }
      while resp.is_truncated
        marker = resp.next_continuation_token
        
        resp = client.list_objects_v2(
                 bucket: @credentials[:bucket_name],
                 delimiter: "/",
                 prefix: prefix,
                 continuation_token: marker
               )
        
        dirs += resp.common_prefixes.map {|dir| dir = dir.prefix.split("/").last }
      end
      dirs&.each do |dir|
        children << to_hash(prefix + dir + "/")
      end
      
      files = resource.bucket(@credentials[:bucket_name]).objects(
                delimiter: "/",
                prefix: prefix,
                start_after: prefix
              )
      
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
        @client.list_objects_v2(
          bucket: @credentials[:bucket_name],
          max_keys: 0
        )
      rescue Aws::S3::Errors::InvalidAccessKeyId, Aws::S3::Errors::SignatureDoesNotMatch
        raise InvalidCredentialsError, FRIENDLY_NAME
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
    
    def exists?(key)
      resource.bucket(@credentials[:bucket_name]).object(key).exists?
    end
    
    def resource
      @resource ||= Aws::S3::Resource.new(client: client)
    end
    
    def directory_contents(prefix)
      contents = []
      
      resp = client.list_objects_v2(
               bucket: @credentials[:bucket_name],
               delimiter: "/",
               prefix: prefix
             )
      
      dirs = resp.common_prefixes.map {|dir| dir = dir.prefix.split("/").last }
      while resp.is_truncated
        marker = resp.next_continuation_token
        
        resp = client.list_objects_v2(
                 bucket: @credentials[:bucket_name],
                 delimiter: "/",
                 prefix: prefix,
                 continuation_token: marker
               )
        
        dirs += resp.common_prefixes.map {|dir| dir = dir.prefix.split("/").last }
      end
      dirs&.each do |dir|
        contents << dir + "/"
      end
      
      files = resource.bucket(@credentials[:bucket_name]).objects(
                delimiter: "/",
                prefix: prefix,
                start_after: prefix
              )
      
      files.collect(&:key)&.each do |file|
        contents << file.split("/").last
      end
      contents
    end
    
    def filesize(src)
      src = src.delete_prefix("/")
      
      resp = client.list_objects_v2(
        bucket: @credentials[:bucket_name],
        prefix: src
      )
      
      total = resp.contents.map { |o| o.size }.sum
      while resp.is_truncated
        marker = resp.next_continuation_token
        
        resp = client.list_objects_v2(
                 bucket: @credentials[:bucket_name],
                 prefix: src,
                 continuation_token: marker
               )
        
        total += resp.contents.map { |o| o.size }.sum
      end
      pretty_filesize(total)
    end
  end
end

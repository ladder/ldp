require 'mongoid'
require 'ladder/searchable/file'
require 'ladder/storage_adapters/grid_fs'

module Ladder
  class File
    include Mongoid::Document
    include Ladder::Searchable::File

    field :length
    field :chunkSize
    field :uploadDate
    field :md5
    field :contentType
    field :filename

    alias_method :content_type, :contentType

    def data
      collection.database.fs.open_download_stream_by_name(filename).read
    end

  end
end

module RDF::LDP
  class NonRDFSource
    def initialize(subject_uri, data = RDF::Repository.new)
      super

      # Configuration settings for Mongoid
      Mongo::Logger.level = Ladder::LDP.settings.log_level
      Mongoid.load_configuration({ clients: { default: { uri: Ladder::LDP.settings.uri } } }) unless Mongoid.configured?

      Ladder::File.store_in(collection: Ladder::LDP.settings.repository.client.database.fs.files_collection.name)
    end

    def storage
      @storage_adapter ||= GridFSAdapter.new(self)
    end

    def create(input, c_type)
      storage.io { |io| IO.copy_stream(input.binmode, io) }
      super
      self.content_type = c_type
      RDFSource.new(description_uri, @data).create('', 'application/n-triples')

      file = Ladder::File.where(filename: subject_uri.path).first
      file.send(:enqueue, :index) if file

      self
    end

    ##
    # @see RDF::LDP::Resource#update
    def update(input, c_type)
      storage.io { |io| IO.copy_stream(input.binmode, io) }
      super
      self.content_type = c_type

      file = Ladder::File.where(filename: subject_uri.path).first
      file.send(:enqueue, :update) if file

      self
    end

    ##
    # Deletes the LDP-NR contents from the storage medium and marks the
    # resource as destroyed.
    #
    # @see RDF::LDP::Resource#destroy
    def destroy
      file = Ladder::File.where(filename: subject_uri.path).first
      file.send(:enqueue, :delete) if file

      storage.delete
      super
    end
  end
end

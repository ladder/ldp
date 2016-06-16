require 'ladder/storage_adapters/grid_fs'
require 'ladder/searchable'

module Ladder
  class File
    include ActiveModel::Model
    attr_accessor :id, :resource

    define_model_callbacks :create, only: :after
    define_model_callbacks :update, only: :after
    define_model_callbacks :destroy, only: :before

    include Ladder::Searchable

    def self.find(uri)
binding.pry
      resource = RDF::LDP::NonRDFSource.find(RDF::URI(uri), Ladder::LDP.settings.repository)
      self.new(id: uri, resource: resource)
    end

    def as_indexed_json(*)
      storage = GridFSAdapter.new(resource)
binding.pry
      { file: Base64.encode64(data) }
    end

  end
end

module RDF::LDP
  class NonRDFSource
    def storage
      @storage_adapter ||= GridFSAdapter.new(self)
    end

    def create(input, c_type)
      storage.io { |io| IO.copy_stream(input.binmode, io) }
      super
      self.content_type = c_type
      RDFSource.new(description_uri, @data).create('', 'application/n-triples')
#      binding.pry if storage.file_exists?
#      Ladder::File.new(id: subject_uri).send(:enqueue, :index)
      self
    end

    ##
    # @see RDF::LDP::Resource#update
    def update(input, c_type)
      storage.io { |io| IO.copy_stream(input.binmode, io) }
      super
      self.content_type = c_type
#
      self
    end

    ##
    # Deletes the LDP-NR contents from the storage medium and marks the
    # resource as destroyed.
    #
    # @see RDF::LDP::Resource#destroy
    def destroy
#
      storage.delete
      super
    end
  end
end

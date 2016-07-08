require 'ladder/model/file'
require 'ladder/storage_adapters/grid_fs'

module Ladder
  module NonRDFSource
    def initialize(*)
      Ladder::File.store_in(collection: Ladder::LDP.settings.repository.client.database.fs.files_collection.name)
      super
    end

    # TODO: decouple these from #enqueue in favour of triggering callbacks
    # TODO: if file data is empty, how to handle?
    def file
      Ladder::File.where(filename: subject_uri.path).first
    end

    def create(input, c_type)
      super
      file.send(:enqueue, :index) if file
      self
    end

    def update(input, c_type)
      super
      file.send(:enqueue, :update) if file
      self
    end

    def destroy
      super
      file.send(:enqueue, :delete) if file
      self
    end
  end
end

# FIXME: PR against rdf-ldp to allow injecting a storage adapter
module RDF::LDP
  class NonRDFSource
    def storage
      @storage_adapter ||= GridFSAdapter.new(self)
    end
  end
end

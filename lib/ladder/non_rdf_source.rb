require 'ladder/model/file'
require 'ladder/storage_adapters/grid_fs'

module Ladder
  module NonRDFSource
    def file
      Ladder::File.where(filename: subject_uri.path).first
    end

    def create(input, c_type)
      super
      file.run_callbacks(:create) if file
      self
    end

    def update(input, c_type)
      super
      file.run_callbacks(:update) if file
      self
    end

    def destroy
      file.run_callbacks(:destroy) if file
      super
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

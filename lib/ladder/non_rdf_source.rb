require 'ladder/storage_adapters/grid_fs'

module RDF::LDP
  class NonRDFSource
    def storage
      @storage_adapter ||= GridFSAdapter.new(self)
    end
  end
end

require 'ladder/storage_adapters/grid_fs'

module Ladder
  class NonRDFSource < RDF::LDP::NonRDFSource
    def storage
      @storage_adapter ||= GridFSAdapter.new(self)
    end
  end
end

require_relative 'storage_adapters/grid_fs'

module RDF::LDP
  class NonRDFSource < Resource

    ##
    # FIXME: Monkey-patch storage until we have a better solution
    def storage
      @storage_adapter ||= GridFSAdapter.new(self)
    end
  end
end

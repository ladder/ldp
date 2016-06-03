require 'ladder/storage_adapters/grid_fs'

module Ladder
  class NonRDFSource < RDF::LDP::NonRDFSource
    def initialize(subject_uri, data = nil)
      super

      data = Ladder::LDP.settings.repository
    end

    def storage
      @storage_adapter ||= GridFSAdapter.new(self)
    end
  end
end

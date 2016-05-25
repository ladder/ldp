require 'ladder/storage_adapters/grid_fs'

module RDF::LDP
  class NonRDFSource < Resource
    def initialize(subject_uri, data = Ladder::LDP.settings.repository)

      # TODO
      # unless data.respond_to? :client
      #
      # The Mongo database instance
      # @return [Mongo::DB]
      # attr_reader :client
      #
      # The collection used for storing quads
      # @return [Mongo::Collection]
      # attr_reader :collection

      super
    end

    ##
    # FIXME: Monkey-patch storage until we have a better solution
    def storage
      @storage_adapter ||= GridFSAdapter.new(self)
    end
  end
end

module RDF::LDP
  class RDFSource < Resource

    ##
    # FIXME: Monkey-patch methods until we have a better solution
    def initialize(subject_uri, data = RDF::Repository.new)
      super
    end

    def create(input, content_type, &block)
      super
    end
    
    def update(input, content_type, &block)
      super
    end

    def destroy(&block)
      super
    end
    
  end
end
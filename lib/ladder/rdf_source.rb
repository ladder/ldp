module Ladder
  class Statement
    include ::Mongoid::Document

    # Use the same field names as RDF::Mongo::Conversion
    %i(s st p pt o ot ol c ct).each { |key| field key }

    index({s: 1})
    index({p: 1})
    index({o: 'hashed'})
    index({c: 1})
    index({s: 1, p: 1})
    index({s: 1, p: 1, o: 1})
  end
end

module Ladder
  class Graph
    include ::Mongoid::Document

    field :c
    field :ct, default: :default
    field :statements, type: Array

    index({c: 1})
    index({ct: 1})

    store_in collection: 'graphs'

    before_save { project_graph if changed? }

    def project_graph
      self.statements = Ladder::Statement.where({c: self.c, ct: self.ct}).map { |s| s.attributes }
    end
  end
end

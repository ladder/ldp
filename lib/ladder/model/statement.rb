require 'mongoid'

module Ladder
  class Statement
    include Mongoid::Document

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
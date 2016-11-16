require 'ladder/storage_adapters/grid_fs'

module Ladder
  class NonRDFSource < RDF::LDP::NonRDFSource
    def initialize(subject_uri, data)
      super

      # FIXME: clarify this logic
      @data = RDF::Ladder.settings.repository unless @data.is_a? RDF::Mongo::Repository
      @storage = GridFSAdapter.new(self)

      self
    end

=begin
    def initialize(*)
      Ladder::File.store_in(collection: Ladder::LDP.settings.repository.client.database.fs.files_collection.name)
      super
    end

    def file
      Ladder::File.where(filename: subject_uri.path).first
    end
=end
=begin
    def create(input, c_type)
      super
#      file.run_callbacks(:create) if file
      self
    end

    def update(input, c_type)
      super
#      file.run_callbacks(:update) if file
      self
    end

    def destroy
#      file.run_callbacks(:destroy) if file
      super
      self
    end
=end
  end
end

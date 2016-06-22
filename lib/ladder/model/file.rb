require 'mongoid'
require 'ladder/searchable/file'

module Ladder
  class File
    include Mongoid::Document
    include Ladder::Searchable::File

    field :length
    field :chunkSize
    field :uploadDate
    field :md5
    field :contentType
    field :filename

    alias_method :content_type, :contentType

    def data
      collection.database.fs.open_download_stream_by_name(filename).read
    end
  end
end
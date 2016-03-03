##
# StorageAdapters bundle the logic for mapping a `NonRDFSource` to a
# specific IO stream. Implementations must conform to a minimal interface:
#
#  - `#initialize` must accept a `resource` parameter. The input should be
#     a `NonRDFSource` (LDP-NR).
#  - `#io` must yield and return a IO object in binary mode that represents
#    the current state of the LDP-NR.
#    - If a block is passed to `#io`, the implementation MUST allow return a
#      writable IO object and that anything written to the stream while
#      yielding is synced with the source in a thread-safe manner.
#    - Clients not passing a block to `#io` SHOULD call `#close` on the
#      object after reading it.
#    - If the `#io` object responds to `#to_path` it MUST give the location
#      of a file whose contents are identical the IO object's. This supports
#      Rack's response body interface.
#  - `#delete` remove the contents from the corresponding storage. This MAY
#      be a no-op if is undesirable or impossible to delete the contents
#      from the storage medium.
#
# @see http://www.rubydoc.info/github/rack/rack/master/file/SPEC#The_Body
#   for details about `#to_path` in Rack response bodies.
#
# @example reading from a `StorageAdapter`
#   storage = StorageAdapter.new(an_nr_source)
#   storage.io.read # => [string contents of `an_nr_source`]
#
# @example writing to a `StorageAdapter`
#   storage = StorageAdapter.new(an_nr_source)
#   storage.io { |io| io.write('moomin')
#
# Beyond this interface, implementations are permitted to behave as desired.
# They may, for instance, reject undesirable content or alter the graph (or
# metagraph) of the resource. They should throw appropriate `RDF::LDP`
# errors when failing to allow the middleware to handle response codes and
# messages.
#

class GridFSAdapter
  ##
  # Initializes the storage adapter.
  #
  # @param [NonRDFSource] resource
  def initialize(resource)
    @resource = resource
    @filename = resource.subject_uri.path
    @bucket = Mongoid.default_client.database.fs
  end

  def io(&block)
    if block_given? then
      yield self
    else
      close_stream
      self
    end
  end

  def write(string)
    # NB: we explicitly set chunk_size based on the size
    # of incoming chunnks from rack; it is assumed that all
    # chunks will be the same size
    chunk_size = string.length

    # open an upload stream
    @stream ||= @bucket.open_upload_stream(@filename, chunk_size: chunk_size)
    @stream.write(string)

    chunk_size
  end

  def each(&block)
    # open a download stream
    @stream ||= @bucket.open_download_stream_by_name(@filename)
    @stream.each &block
  end

  def delete
    # FIXME: this requires extra querying; not performant
    file = @bucket.find_one(filename: @filename)
    @bucket.delete_one(file)
  end

  def close_stream
    @stream.close if @stream
    @stream = nil
  end

  def method_missing(symbol, *args)
    binding.pry
  end

end

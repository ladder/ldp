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
#   storage.io { |io| io.write('moomin') }
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
    raise ArgumentError, "non-parented URI: #{resource.subject_uri}" unless resource.subject_uri.has_parent?
    @filename = resource.subject_uri.path

    # FIXME: should this go in (patched) NonRDFSource#initialize?
    @bucket = Ladder::LDP.settings.repository.client.database.fs
  end

  ##
  # @yield [IO] yields an instance of GridFSAdapter with an opened write
  #   stream.  The stream will be closed when the block ends.
  #
  # @return [GridFSAdapter] an instance of GridFSAdapter
  def io(&block)
    yield(self) if block_given?
    close_stream
    self
  end

  ##
  # IO-like method for writing a file to GridFS as a stream.
  # Each chunk is persisted as it is written, with the write
  # stream left open.
  #
  # NB: We explicitly set chunk_size based on the size
  # of incoming chunks from Rack; it is assumed that all
  # chunks will be the same size.
  #
  # @param [String] a string to write to the GridFS file.
  def write(string)
    chunk_size = string.length

    # open an upload stream
    @stream = @bucket.open_upload_stream(@filename, chunk_size: chunk_size)
    @stream.write(string)

    chunk_size
  end

  def file_exists?
    @bucket.find(filename: @filename).count > 0
  end

  ##
  # IO-like method for reading a file from GridFS as a stream.
  #
  # @param [Proc] a block which iterates over the returned chunks.
  def each(&block)
    # write the file if it doesn't exist
    return self.write block.call if 0 == @bucket.find(filename: @filename).count

    # open a download stream
    @stream ||= @bucket.open_download_stream_by_name(@filename)

    block_given? ? @stream.each(&block) : @stream.to_a
  end

  def to_a
    self.each
  end

  ##
  # This will remove all revisions of the file and corresponding
  # chunks in the collection.
  # @return [Boolean] whether anything was deleted
  def delete
    files = @bucket.find(filename: @filename)
    return false if 0 == files.count

    ids = files.map(&:extract_id) # NB: requires Mongoid

    @bucket.files_collection.delete_many(_id: {'$in' => ids})
    @bucket.chunks_collection.delete_many(files_id: {'$in' => ids})

    true
  end

  ##
  # Remove all files and revisions
  def clear!
    @bucket.files_collection.delete_many
    @bucket.chunks_collection.delete_many
  end

  private

  def close_stream
    @stream.close if @stream
    @stream = nil
  end
end

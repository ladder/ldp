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
    @bucket = Mongoid.default_client.database.fs
  end

  def io(&block)

    if block_given? then # WRITE MODE
      yield GridIO.new(@resource.subject_uri.path)
    else # READ MODE
      @bucket.open_download_stream_by_name(@resource.subject_uri.path)
    end

  end

  def delete
    # FIXME: this requires an extra query
    file = @bucket.find_one(filename: @resource.subject_uri.path)
    @bucket.delete_one(file)
  end
end

class GridIO

  def initialize(filename)
    @filename = filename
    @bucket = Mongoid.default_client.database.fs
  end

  def write(string)
    @bucket.upload_from_stream(@filename, string)
    string.length
  end

#  def method_missing(symbol, *args)
#    binding.pry
#  end

end
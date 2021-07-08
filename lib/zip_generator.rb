# frozen_string_literal: true

# Copyright (c) 2012 Ram Dobson / MIT License
# Modified from https://github.com/fringd/zipline to remove some unneeded indirection
# and give us Ruby 3 compatibility
class ZipGenerator
  # takes an array of pairs [[uploader, filename], ... ]
  def initialize(files)
    @files = files
  end

  def each(&block)
    fake_io_writer = ZipTricks::BlockWrite.new(&block)
    # ZipTricks outputs lots of strings in rapid succession, and with
    # servers it can be beneficial to avoid doing too many tiny writes so that
    # the number of syscalls is minimized. See https://github.com/WeTransfer/zip_tricks/issues/78
    # There is a built-in facility for this in ZipTricks which can be used to implement
    # some cheap buffering here (it exists both in version 4 and version 5). The buffer is really
    # tiny and roughly equal to the medium Linux socket buffer size (16 KB). Although output
    # will be not so immediate with this buffering the overall performance will be better,
    # especially with multiple clients being serviced at the same time.
    # Note that the WriteBuffer writes the same, retained String object - but the contents
    # of that object changes between calls. This should work fine with servers where the
    # contents of the string gets written to a socket immediately before the execution inside
    # the WriteBuffer resumes), but if the strings get retained somewhere - like in an Array -
    # this might pose a problem. Unlikely that it will be an issue here though.
    write_buffer_size = 16 * 1024
    write_buffer = ZipTricks::WriteBuffer.new(fake_io_writer, write_buffer_size)
    ZipTricks::Streamer.open(write_buffer) do |streamer|
      @files.each do |file, name, options = {}|
        streamer.write_deflated_file(name.to_s, **options) do |writer_for_file|
          f = File.open(file.path)
          IO.copy_stream(f, writer_for_file)
          f.close
        end
      end
    end
    write_buffer.flush! # for any remaining writes
  end
end

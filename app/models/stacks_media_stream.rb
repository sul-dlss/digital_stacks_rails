##
# media stream via stacks
class StacksMediaStream < StacksFile
  TYPE_TO_MANIFEST_FILE = {
    hls: 'playlist.m3u8',
    dash: 'manifest.mpd'
  }.freeze

  attr_accessor :format

  def to_playlist_url
    streaming_url_for(:hls)
  end

  def to_manifest_url
    streaming_url_for(:dash)
  end

  private

  def streaming_url_for(type)
    return unless file_name && streaming_file_prefix
    suffix = TYPE_TO_MANIFEST_FILE[type]
    "#{streaming_base_url}/#{druid_tree}/#{streaming_url_file_segment}/#{suffix}"
  end

  def streaming_file_prefix
    if video?
      'mp4'
    elsif audio?
      'mp3'
    end
  end

  def video?
    Settings.stream.video.include? file_extension
  end

  def audio?
    Settings.stream.audio.include? file_extension
  end

  def file_extension
    ::File.extname(file_name).delete('.')
  end

  def streaming_base_url
    Settings.stream.url
  end

  def druid_tree
    @druid_tree ||= begin
      match = druid.match(/^([a-z]{2})(\d{3})([a-z]{2})(\d{4})$/i)
      File.join(match[1], match[2], match[3], match[4]) if match
    end
  end

  def druid
    id.split(':').last
  end

  def streaming_url_file_segment
    "#{streaming_file_prefix}:#{file_name}"
  end
end

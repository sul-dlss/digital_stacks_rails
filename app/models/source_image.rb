# @abstract Represents a source of an image.
class SourceImage
  def initialize(id:, file_name:, transformation:); end

  # @return [IO]
  def response
    benchmark "Fetch #{image_url}" do
      # HTTP::Response#body does response streaming
      HTTP.get(image_url).body
    end
  end

  def exist?; end

  def valid?; end

  def etag; end

  def mtime; end

  # I think this is unnecessary in later versions https://github.com/bbatsov/rubocop/pull/3883
  # rubocop:disable Lint/UselessAccessModifier
  private

  delegate :logger, to: Rails
end

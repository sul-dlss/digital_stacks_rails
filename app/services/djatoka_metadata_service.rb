# frozen_string_literal: true

# Fetch metadata from Djatoka
class DjatokaMetadataService < MetadataService
  def fetch(tile_size)
    @metadata ||= djatoka_metadata.as_json do |md|
      md.tile_height = tile_size
      md.tile_width = tile_size
    end
  end

  def image_width
    djatoka_metadata.max_width
  end

  def image_height
    djatoka_metadata.max_height
  end

  private

  delegate :canonical_url, to: :image

  def djatoka_metadata
    @djatoka_metadata ||= DjatokaMetadata.find(canonical_url, djatoka_path.uri)
  end

  def djatoka_path
    DjatokaPath.new(id)
  end
end
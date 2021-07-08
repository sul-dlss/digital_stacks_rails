# frozen_string_literal: true

require 'zip_generator'

##
# API for delivering whole objects from stacks
class ObjectController < ApplicationController
  def show
    files = accessible_files.map do |file|
      [
        file,
        file.file_name,
        modification_time: file.mtime
      ]
    end

    raise ActionController::RoutingError, 'No downloadable files' if files.none?

    zipline(files, "#{druid}.zip")
  end

  private

  def allowed_params
    params.permit(:id, :download)
  end

  def druid
    allowed_params[:id]
  end

  def accessible_files
    return to_enum(:accessible_files) unless block_given?

    Purl.files(druid).each do |file|
      yield file if can? :download, file
    end
  end

  def zipline(files, zipname = 'zipline.zip')
    zip_generator = ZipGenerator.new(files)
    headers['Content-Disposition'] = "attachment; filename=\"#{zipname.gsub '"', '\"'}\""
    headers['Content-Type'] = Mime::Type.lookup_by_extension('zip').to_s
    response.sending_file = true
    response.cache_control[:public] ||= false
    self.response_body = zip_generator
    response.headers['Last-Modified'] = Time.now.httpdate
  end
end

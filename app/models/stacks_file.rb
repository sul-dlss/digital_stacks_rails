class StacksFile
  include ActiveModel::Model
  include ActiveSupport::Benchmarkable

  attr_accessor :id, :file_name

  def world_unrestricted?
    rights.world_unrestricted_file? file_name
  end

  def world_rights
    rights.world_rights_for_file file_name
  end

  def stanford_only_rights
    rights.stanford_only_rights_for_file file_name
  end

  def agent_rights(agent)
    rights.agent_rights_for_file file_name, agent
  end

  def rights
    @rights ||= Dor::RightsAuth.parse(rights_xml)
  end

  def exist?
    File.exist?(path)
  end

  def mtime
    @mtime ||= File.mtime(path) if exist?
  end

  def etag
    mtime.to_i if mtime
  end

  def path
    @path ||= begin
      match = druid.match(/^([a-z]{2})(\d{3})([a-z]{2})(\d{4})$/i)

      File.join(Settings.stacks.storage_root, match[1], match[2], match[3], match[4], file_name)
    end
  end

  private

  def druid
    id.split(':').last
  end

  def rights_xml
    benchmark "Fetching public xml for #{druid}" do
      Hurley.get(Settings.purl.url + "/#{druid}.xml").body
    end
  end

  def logger
    Rails.logger
  end
end
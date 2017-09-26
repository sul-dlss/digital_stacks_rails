##
# Represents a file on disk in stacks. A StacksFile may be downloaded and
# may be the file that backs a StacksImage or StacksMediaStream
class StacksFile
  include ActiveModel::Model
  include StacksRights

  attr_accessor :id, :current_ability, :download

  # Some files exist but have unreadable permissions, treat these as non-existent
  def readable?
    path && File.readable?(path)
  end

  def mtime
    @mtime ||= File.mtime(path) if readable?
  end

  def etag
    mtime.to_i if mtime
  end

  def path
    @path ||= PathService.for(id)
  end
end

module ChunkUploader
  extend ActiveSupport::Concern

  class InvalidChecksumError < StandardError
  end

  included do
    UPLOADS_FOLDER = "#{Rails.root}/public/uploads"
    enum status: [:without_chunks, :uploading, :finalized]

    after_create do
      self.make_uploads_folder!
      self.without_chunks! if self.status.nil?
    end

    after_destroy do
      self.remove_uploads_folder!
    end
  end

  def directory_fullpath
    UPLOADS_FOLDER + "/#{self.id}"
  end

  def tmpfile_fullpath
    "#{directory_fullpath}/tmpfile"
  end

  def make_uploads_folder!
    Dir.mkdir(UPLOADS_FOLDER) unless File.directory? UPLOADS_FOLDER
    Dir.mkdir(self.directory_fullpath) unless File.directory? self.directory_fullpath
  end

  def remove_uploads_folder!
    FileUtils.rm_rf self.directory_fullpath
  end

  def append_chunk_to_file! chunk_params
    self.append_binary_to_file! chunk_params[:id].to_i, chunk_params[:data].tempfile.read
  end

  def append_binary_to_file! chunk_id, chunk_binary
    set_chunk_id! chunk_id
    self.uploading! if chunk_id == 1
    File.open(self.tmpfile_fullpath, 'ab') { |file| file.write(chunk_binary) }
  end

  def tmpfile_md5_checksum
    Digest::MD5.hexdigest(File.read(self.tmpfile_fullpath)) if File.file? self.tmpfile_fullpath
  end

  def tmpfile_size
    File.size self.tmpfile_fullpath if File.file? self.tmpfile_fullpath
  end

  def renamed_file_fullpath_by filename
    "#{directory_fullpath}/#{filename}"
  end

  def finalize_upload_by! file_params
    unless self.tmpfile_md5_checksum == file_params[:checksum]
      raise InvalidChecksumError
    end

    filename = file_params[:filename]
    File.rename(self.tmpfile_fullpath, self.renamed_file_fullpath_by(filename))
    self.finalized!
    File.open(self.renamed_file_fullpath_by(filename)) do |file|
      attach_file(file)
    end
  end

  def attach_file(file)
    self.update_attribute :file, File.open(file)
  end

  private
    def set_chunk_id! chunk_id
      self.update_attribute :last_chunk_id, chunk_id
    end

end

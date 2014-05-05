module ChunkUploader

  STATUS_UPLOADING = 0
  STATUS_DONE = 1

  UPLOADS_FOLDER = "#{::Rails.root}/public/uploads"

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
    raise "Empty chunk" unless chunk_params
    raise "Chunk id is empty" unless chunk_params[:id]
    raise "Chunk data is invalid" unless chunk_params[:data].respond_to?(:tempfile)
    self.append_binary_to_file! chunk_params[:id].to_i, chunk_params[:data].tempfile.read
  end

  def append_binary_to_file! chunk_id, chunk_binary
    raise "Can't add data to finalized upload" unless self.status == STATUS_UPLOADING
    set_chunk_id! chunk_id
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
    raise "Upload is already finalized" if self.status == STATUS_DONE
    raise "Empty file params" unless file_params
    raise "File name is empty" unless file_params[:filename]
    raise "File checksum is empty" unless file_params[:checksum]
    filename = file_params[:filename]
    raise "Invalid file checksum" unless self.tmpfile_md5_checksum == file_params[:checksum]
    File.rename(self.tmpfile_fullpath, self.renamed_file_fullpath_by(filename))
    self.update_attribute :status, STATUS_DONE
    File.open(self.renamed_file_fullpath_by(filename)) do |file|
      attach_file(file)
    end
  end

  def attach_file(file)
    self.update_attribute :file, File.open(file)
  end

  private
    def set_chunk_id! chunk_id
      raise "Invalid chunk id!" unless self.last_chunk_id + 1 == chunk_id
      self.update_attribute :last_chunk_id, chunk_id
    end

end

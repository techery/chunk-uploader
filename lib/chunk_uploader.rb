require 'exceptions/invalid_checksum_error'

module ChunkUploader
  extend ActiveSupport::Concern

  included do
    enum status: [:without_chunks, :uploading, :finalized]

    after_create do
      make_uploads_folder!
      self.without_chunks! if self.status.nil?
    end

    after_destroy do
      remove_uploads_folder!
    end

    def append_chunk_to_file!(id:, data:)
      append_binary_to_file! id, data.tempfile.read
    end

    def finalize_upload_by!(checksum:, filename:)
      unless tmpfile_md5_checksum == checksum
        raise InvalidChecksumError
      end

      File.rename(tmpfile_fullpath, renamed_file_fullpath_by(filename))
      self.finalized!
      File.open(renamed_file_fullpath_by(filename)) do |file|
        attach_file(file)
      end
    end

    private

    def self.uploads_chunks_to(upload_path)
      define_method :upload_path do
        upload_path
      end
    end

    def directory_fullpath
       "#{upload_path}/#{self.id}"
    end

    def tmpfile_fullpath
      "#{directory_fullpath}/tmpfile"
    end

    def make_uploads_folder!
      Dir.mkdir(upload_path) unless File.directory? upload_path
      Dir.mkdir(directory_fullpath) unless File.directory? directory_fullpath
    end

    def remove_uploads_folder!
      FileUtils.rm_rf directory_fullpath
    end

    def append_binary_to_file! chunk_id, chunk_binary
      set_chunk_id! chunk_id
      self.uploading! if chunk_id == 1
      File.open(tmpfile_fullpath, 'ab') { |file| file.write(chunk_binary) }
    end

    def tmpfile_md5_checksum
      Digest::MD5.hexdigest(File.read(tmpfile_fullpath)) if File.file?(tmpfile_fullpath)
    end

    def tmpfile_size
      File.size tmpfile_fullpath if File.file?(tmpfile_fullpath)
    end

    def renamed_file_fullpath_by filename
      "#{directory_fullpath}/#{filename}"
    end

    def attach_file(file)
      update_attribute :file, File.open(file)
    end

    def set_chunk_id! chunk_id
      update_attribute :last_chunk_id, chunk_id
    end
  end
end

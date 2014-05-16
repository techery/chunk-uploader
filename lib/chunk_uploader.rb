require 'exceptions/invalid_checksum_error'
require 'exceptions/invalid_chunk_id_error'
require 'active_support'

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
      unless last_chunk_id + 1 == id
        raise InvalidChunkIdError.new('invalid chunk id')
      end
      update_attribute :last_chunk_id, id
      self.uploading! if id == 1
      File.open(tmpfile_full_path, 'ab') { |file| file.write(data.read) }
    end

    def finalize_upload_by!(checksum:, filename:)
      unless tmpfile_md5_checksum == checksum
        raise InvalidChecksumError.new('file checksum is invalid')
      end
      if last_chunk_id == 0
        raise 'Upload is still empty'
      end

      File.rename(tmpfile_full_path, renamed_file_full_path_by(filename))
      self.finalized!
      update_attribute :file, File.open(renamed_file_full_path_by(filename))
    end

    private

    def self.uploads_chunks_to(upload_path)
      define_method :upload_path do
        upload_path
      end
    end

    def directory_full_path                ; "#{upload_path}/#{self.id}"         ; end
    def tmpfile_full_path                  ; "#{directory_full_path}/tmpfile"    ; end
    def renamed_file_full_path_by(filename); "#{directory_full_path}/#{filename}"; end

    def make_uploads_folder!
      Dir.mkdir(upload_path) unless File.directory? upload_path
      Dir.mkdir(directory_full_path) unless File.directory? directory_full_path
    end

    def remove_uploads_folder!
      FileUtils.rm_rf directory_full_path
    end

    def tmpfile_md5_checksum
      Digest::MD5.hexdigest(File.read(tmpfile_full_path)) if File.file?(tmpfile_full_path)
    end
  end
end

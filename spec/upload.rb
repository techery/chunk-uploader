shared_context "with_upload" do

  with_model :Upload do
    base_path = File.expand_path '../..', __FILE__

    table do |t|
      t.integer  :status,        default: 0
      t.integer  :last_chunk_id, default: 0
      t.string   :file
    end

    model do
      include ChunkUploader
      include ChunkUploader::Compatibility::CarrierWave

      uploads_chunks_to "#{base_path}/tmp/uploads"
    end
  end

end
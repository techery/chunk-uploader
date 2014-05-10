require 'spec_helper'

describe "ChunkUploader" do
  include_context 'with_upload'

  let(:upload) { Upload.create }
  let(:chunk_file) { File.open("spec/chunk.txt") }

  describe "#append_chunk_to_file!" do

    context "when chunk_id = 1" do
      before(:all) do
        upload.append_chunk_to_file!(id: 1, data: chunk_file)
      end

      it "should set last_chunk_id = 1" do
        expect(upload.last_chunk_id).to eq 1
      end

      it "should set status = 'uploading'" do
        expect(upload).to be_uploading
      end
    end

    context "when chunk_id > 1" do
      before(:all) do
        upload.append_chunk_to_file!(id: 1, data: chunk_file)
      end

      2.upto(5) do |i|
        context "when chunk_id = #{i}" do
          before(:all) do
            upload.append_chunk_to_file!(id: i, data: chunk_file)
          end

          it "should set last_chunk_id = #{i}" do
            expect(upload.last_chunk_id).to eq i
          end

          it "should not change status 'uploading'" do
            expect(upload).to be_uploading
          end
        end
      end

      context 'with invalid chunk id' do
        let(:upload) { Upload.create last_chunk_id: 5 }

        [0, 3, 8].each do |chunk_id|
          subject do
            lambda { upload.append_chunk_to_file!(id: chunk_id, data: chunk_file) }
          end

          it { should raise_error ChunkUploader::InvalidChunkIdError }
        end
      end
    end

  end

  describe 'path method' do
    before { upload.stub upload_path: 'path/to/upload' }

    describe '#directory_full_path' do
      subject { upload.send(:directory_full_path) }
      it { should eq "path/to/upload/#{upload.id}" }
    end

    describe '#tmpfile_full_path' do
      subject { upload.send(:tmpfile_full_path) }
      it { should eq "path/to/upload/#{upload.id}/tmpfile" }
    end

    describe '#renamed_file_full_path_by' do
      subject { upload.send(:renamed_file_full_path_by, 'filename') }
      it { should eq "path/to/upload/#{upload.id}/filename" }
    end
  end

  describe '#make_uploads_folder!' do
    context 'when uploads directory exists' do
      before do
        upload.stub id: SecureRandom.hex
        upload.send :make_uploads_folder!
      end

      subject { File.directory? "#{upload.upload_path}/#{upload.id}" }

      it { should be_true }
    end

    context 'when uploads directory doesn\'t exist' do
      before do
        upload.stub upload_path: "#{upload.upload_path}/new_path"
        upload.send :make_uploads_folder!
      end

      subject { File.directory? "#{upload.upload_path}/#{upload.id}" }

      it { should be_true }
    end
  end

  describe '#remove_uploads_folder!' do
    before do
      upload.send :make_uploads_folder!
      upload.send :remove_uploads_folder!
    end

    subject { File.directory? "#{upload.upload_path}/#{upload.id}" }

    it { should be_false }
  end

end
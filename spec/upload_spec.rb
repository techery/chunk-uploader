require 'spec_helper'

describe "Upload" do
  include_context 'with_upload'

  describe '.statuses' do
    subject { Upload.statuses }
    it { should eq({'without_chunks' => 0, 'uploading' => 1, 'finalized' => 2}) }
  end

  describe ".uploads_chunks_to" do
    before { class Upload; uploads_chunks_to('path/to/chunks'); end }

    let(:uploader) { Upload.new }

    subject { uploader.upload_path }
    it { should eql 'path/to/chunks' }
  end
end
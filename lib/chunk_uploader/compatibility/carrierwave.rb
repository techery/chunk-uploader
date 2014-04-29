module ChunkUploader
  module Compatibility
    module CarrierWave

      def self.included(klass)
        def file=(new_file)
          self[:file] = new_file.to_path
          @file = self[:file]
        end

        def file
          { "url" => @file }
        end
      end
    end
  end
end
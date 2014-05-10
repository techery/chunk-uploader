require 'bundler/setup'
Bundler.setup

require 'chunk_uploader'
require 'with_model'
require 'pry'

require 'upload'

RSpec.configure do |config|
  config.extend WithModel
end

ActiveRecord::Base.establish_connection(:adapter => "sqlite3",
                                       :database => ":memory:")

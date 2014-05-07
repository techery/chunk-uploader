# ChunkUploader

Ruby gem for uploading files in chunks.
Client breaks file into chunks, sends them with different request, then finalizes them with another request.

## Install

Add it to your Gemfile then run `bundle` to install it.

```ruby
gem 'chunk_uploader', git: 'git@bitbucket.org:annabalina/chunk-uploader.git'
bundle install
```

## Setup

Imagine, you have a model Video.
To be able to use this gem, you need to add `:file`, `:status`, `:last_chunk_id` attributes to your Video model.
Create a migration with the required fields:

```ruby
change_table :videos do |t|
  t.integer :status,        default: 0
  t.integer :last_chunk_id, default: 0
  t.string  :file
end
```
Next, run:

```console
rake db:migrate
```

Include `ChunkUploader module` into Video model and set upload path:

```ruby
include ChunkUploader
uploads_chunks_to "#{Rails.root}/public/uploads"
```

Mount uploader you work with to `:file` attribute:

```ruby
mount_uploader :file, VideoUploader
```

Then configure your `config/routes.rb` file.

```ruby
resources :videos do
  member do
    put 'append_chunk', controller: 'videos', action: 'append_chunk'
    put 'finalize',     controller: 'videos', action: 'finalize_upload'
  end
end
```

## Usage

Now you can use it in the following flow.

1. Create video object.

    ```
    POST /api/videos
    ```

    Get video `:id` from response

2. Send chunks in different requests.

    ```
    PUT /api/videos/:id/append_chunk
    ```

    Process request in controller:

    ```ruby
    video.append_chunk_to_file!(id: params[:chunk][:id], data: params[:chunk][:data])
    ```

3. Finalize uploading.

    ```
    PUT /api/videos/:id/finalize
    ```

    Process request in controller:

    ```ruby
    video.finalize_upload_by!(checksum: params[:video][:checksum], filename: params[:video][:filename])
```
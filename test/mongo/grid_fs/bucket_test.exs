defmodule Mongo.GridFs.BucketTest do
  use ExUnit.Case

  alias Mongo.GridFs.Bucket
  alias Mongo.GridFs.Upload

  setup_all do
    assert {:ok, pid} = Mongo.TestConnection.connect
    {:ok, [pid: pid]}
  end

  test "check implementation of the protocols Inspect and String.Chars", c do
    b = Bucket.new(c.pid)
    assert inspect b == to_string(b)
  end

  test "check if the name can be overridden", c do
    new_name = "my_fs"
    %Bucket{name: fs} = Bucket.new(c.pid, name: "my_fs")
    assert fs == new_name
  end

  test "check if the chunk_size can be overridden", c do
    new_chunk_size = 30 * 1024
    %Bucket{chunk_size: chunk_size} = Bucket.new(c.pid, chunk_size: new_chunk_size)
    assert chunk_size == new_chunk_size
  end

  test "delete a file", c do
    bucket        = Bucket.new(c.pid)
    upload_stream = Upload.open_upload_stream(bucket, "my-file-to-delete.txt")
    src_filename  = "./test/data/test.txt"

    File.stream!(src_filename, [], 512) |> Stream.into(upload_stream) |> Stream.run()

    file_id = upload_stream.id

    file = Bucket.find_one(bucket, file_id)
    assert file != nil

    Bucket.delete(bucket, file_id)

    file = Bucket.find_one(bucket, file_id)
    assert file == nil

    chunk = Mongo.find_one(c.pid, Bucket.chunks_collection_name(bucket), %{files_id: file_id})
    assert chunk == nil
  end

  test "rename a file", c do

    bucket        = Bucket.new(c.pid)
    new_filename  = "my-new-filename.txt"
    upload_stream = Upload.open_upload_stream(bucket, "my-example-file.txt")
    src_filename  = "./test/data/test.txt"

    File.stream!(src_filename, [], 512) |> Stream.into(upload_stream) |> Stream.run()

    file_id = upload_stream.id

    file = Bucket.find_one(bucket, file_id)
    assert file != nil

    Bucket.rename(bucket, file_id, new_filename)

    new_file = Bucket.find_one(bucket, file_id)

    assert new_filename == new_file["filename"]
  end

  test "drop bucket", c do

    bucket        = Bucket.new(c.pid, fs: "killme")
    upload_stream = Upload.open_upload_stream(bucket, "my-example-file.txt")
    src_filename  = "./test/data/test.txt"

    File.stream!(src_filename, [], 512) |> Stream.into(upload_stream) |> Stream.run()

    file_id = upload_stream.id
    file = Bucket.find_one(bucket, file_id)
    assert file != nil

    Bucket.drop(bucket)

    file = Mongo.find_one(c.pid, Bucket.files_collection_name(bucket), %{_id: file_id})
    assert file == nil

    file = Mongo.find_one(c.pid, Bucket.chunks_collection_name(bucket), %{file_id: file_id})
    assert file == nil

  end

end

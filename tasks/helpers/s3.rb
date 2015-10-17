def s3_connect
  return if @s3

  require 's3'

  unless ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
    puts 'please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in your environment'
    exit 1
  end

  @s3 = S3::Service.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
  )
end

# TODO: Fix rights
def s3_store(package_file, filename, bucket = 'assets.merqlove.ru')
  s3_connect
  puts "storing: #{filename}"
  release = @s3.bucket(bucket).objects.build(filename)
  release.content = File.read(package_file)
  release.save
end

def s3_store_dir(from, to, bucket = 'assets.merqlove.ru')
  Dir.glob(File.join(from, '**', '*')).each do |file|
    next if File.directory?(file)
    remote = file.gsub(from, to)
    s3_store file, remote, bucket
  end
end

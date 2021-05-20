# frozen_string_literal: true

namespace :proto do
  desc "Compile proto definitions"
  task :compile do
    def system!(*args)
      puts(args.join(' '))
      sh(*args) || abort("\n== Command #{args} failed ==")
    end

    proto_dir = Rails.root.join(Protorails.config.proto_dir)
    proto_path = Rails.root.join(proto_dir, '**', '*.proto').to_s
    proto_service_path = Rails.root.join(proto_dir, '**', '*_service.proto').to_s

    gen_dir = Rails.root.join(Protorails.config.proto_gen_dir)

    FileUtils.rm_f(Dir[Rails.root.join(gen_dir, '**', '*.rb').to_s])
    FileUtils.mkdir_p(gen_dir)

    # dependencies:
    #   protobuf
    #   go get github.com/twitchtv/twirp-ruby/protoc-gen-twirp_ruby
    system!(
      'bundle', 'exec', 'protoc', "--proto_path=#{proto_dir}",
      "--ruby_out=#{gen_dir}",
      "--twirp_ruby_out=#{gen_dir}",
      *Dir[proto_service_path]
    )

    Dir[Rails.root.join(gen_dir, '**', '*.rb').to_s]
      .select { |path| File.basename(path).end_with?('_service_twirp.rb')}
      .each do |path|
        pb_path = path.sub('_twirp.rb', '_pb.rb')
        pb_str = File.open(pb_path).read
        service_str = File.open(path).read
        File.open(path, 'w') do |f|
          f.write(pb_str)
          f.write(service_str)
        end
        FileUtils.rm(pb_path)
        FileUtils.touch(pb_path)
      end

    system!(
      'bundle','exec', 'protoc', "--proto_path=#{proto_dir}",
      "--ruby_out=#{gen_dir}",
      *(Dir[proto_path] - Dir[proto_service_path])
    )
  end
end

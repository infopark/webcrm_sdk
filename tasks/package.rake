require 'bundler/gem_helper'
require 'tmpdir'

namespace :package do
  gemspec = Bundler.load_gemspec('infopark_webcrm_sdk.gemspec')
  gem_file_name = "#{gemspec.name}-#{gemspec.version}.gem"

  desc "Build #{gem_file_name} into the pkg directory"
  task :build => ["documentation", "pkg/#{gem_file_name}"]

  file "pkg/#{gem_file_name}" => ['pkg', 'build_ca_bundle'] do
    repo_dir = Pathname(".").realpath
    commit = %x{git rev-parse HEAD}.strip
    tmp_dir = Dir.mktmpdir
    begin
      chdir(tmp_dir) do
        # ensure no untracked or gitignored files are present
        sh %!rsync -a #{repo_dir}/.git .!
        sh %!git reset --hard #{commit}!

        sh "gem build infopark_webcrm_sdk.gemspec"
      end
      cp "#{tmp_dir}/#{gem_file_name}", "pkg/"
    ensure
      FileUtils.remove_entry_secure(tmp_dir)
    end
  end

  directory 'pkg'

  desc "tests if yard documentation has valid syntax"
  task :documentation do
    output = `yard doc --no-cache --no-stats`.strip
    if output.empty?
      puts "YARD documentation check successfully finished."
    else
      puts output
      raise "YARD documentation has complained."
    end
  end
end

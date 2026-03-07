VERSION_PATTERN = /VERSION\s*=\s*"(\d+\.\d+\.\d+)"/

# Encapsulates version file manipulation logic for rake tasks.
module VersionBumper
  module_function

  def version_path
    File.expand_path("../lib/flexor/version.rb", __dir__)
  end

  def print_current
    require_relative "../lib/flexor/version"
    puts "Current version: #{Flexor::VERSION}"
  end

  def bump
    File.open(version_path, File::RDWR, 0o644) do |f|
      f.flock(File::LOCK_EX)
      old_version, new_version, new_source = compute_bump(f.read)
      f.rewind
      f.write(new_source)
      f.truncate(f.pos)
      puts "Version bumped from #{old_version} to #{new_version}"
    end
  end

  def compute_bump(source)
    match = source.match(VERSION_PATTERN)
    abort "Could not find VERSION in #{version_path}" unless match

    old_version = match[1]
    parts = old_version.split(".").map(&:to_i)
    parts[-1] += 1
    new_version = parts.join(".")
    new_source = source.sub(/VERSION\s*=\s*"#{Regexp.escape(old_version)}"/, "VERSION = \"#{new_version}\"")
    [old_version, new_version, new_source]
  end

  def commit
    require_relative "../lib/flexor/version"
    system("git", "add", version_path) || abort("git add failed")
    system("git", "commit", "-m", "Bump version to #{Flexor::VERSION}") || abort("git commit failed")
    puts "Version change committed."
  end

  def revert
    last_message = `git log -1 --pretty=%B`.strip
    abort "Last commit does not appear to be a version bump." unless last_message.start_with?("Bump version to ")

    system("git", "revert", "HEAD", "--no-edit") || abort("git revert failed")
    puts "Version bump reverted."
  end
end

namespace :version do
  desc "Display the current version"
  task(:current) { VersionBumper.print_current }

  desc "Bump the patch version"
  task(:bump) { VersionBumper.bump }

  desc "Commit the version change"
  task(:commit) { VersionBumper.commit }

  desc "Revert the last version bump commit"
  task(:revert) { VersionBumper.revert }
end

namespace :release do
  desc "Bump version, commit, and release"
  task full: ["version:bump", "version:commit", :release]
end

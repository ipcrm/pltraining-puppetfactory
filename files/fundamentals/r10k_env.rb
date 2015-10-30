#! /usr/bin/env ruby
require 'yaml'
require 'optparse'
require 'fileutils'

BASEDIR  = '/etc/puppetlabs/code/environments'
R10KYAML = '/etc/puppetlabs/r10k/r10k.yaml'
PATTERN  = 'https://github.com/%s/classroom-control.git'
NAME     = File.basename($PROGRAM_NAME)

options = {}
optparse = OptionParser.new { |opts|
  opts.banner = "Usage : #{NAME} <username>

Add or remove a user's control repository in r10k.yaml.
"

  opts.on("-o", "--output", "Print resulting file to stdout.") do
    options[:output] = true
  end

  opts.on("-n", "--noop", "Don't save updated file.") do
    options[:noop] = true
  end

  opts.separator('')

  opts.on("-h", "--help", "Displays this help") do
    puts opts
    exit
  end
}
optparse.parse!

if ARGV.size != 1
  puts "Please call this script with the name of a user."
  puts "  example usage: #{NAME} <username>"
  exit 1
end

File.open(R10KYAML) do |file|
  # make sure we don't have any concurrency issues
  file.flock(File::LOCK_EX)

  user = ARGV[0]
  r10k = YAML.load_file(R10KYAML)

  # look at the script name to determine mode.
  # We do this instead of an argument so it can be a Puppetfactory hook.
  if NAME =~ /create/
    r10k['sources'][user] = {
      'remote'  => sprintf(PATTERN, user),
      'basedir' => BASEDIR,
      'prefix'  => true,
    }
    FileUtils.mkdir_p "#{BASEDIR}/#{user}"
    puts "Created r10k user #{user}"

  elsif NAME =~ /delete/
    r10k['sources'].delete user
    FileUtils.rm_rf "#{BASEDIR}/#{user}"
    puts "Removed r10k user #{user}"

  else
    puts "Script name #{NAME} unknown"
    exit 1
  end

  # Ruby 1.8.7, why don't you just go away now
  File.open(R10KYAML, 'w') { |f| f.write(r10k.to_yaml) } unless options[:noop]

  puts r10k.to_yaml if options[:output]
end
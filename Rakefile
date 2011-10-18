# encoding: utf-8

require 'rubygems'
require 'bundler'
require 'openssl'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

begin
require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "uits"
  gem.required_ruby_version = ">= 1.8.6"
  gem.homepage = "http://github.com/diganta/uits"
  gem.platform = Gem::Platform::RUBY
  gem.license = "MIT"
  gem.summary = %Q{Get UITS code for audio file.}
  gem.description = %Q{Gem to get UITS code.}
  gem.email = "diganta@circarconsulting.com"
  gem.authors = ["Diganta Mandal"]
  gem.version = "0.0.0"
  gem.add_development_dependency "shoulda", ">= 0"
  gem.add_dependency "nokogiri", "1.5.0"
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
  test.rcov_opts << '--exclude "gems/*"'
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "uits #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'apprentice/version'

Gem::Specification.new do |spec|
  spec.name          = 'apprentice'
  spec.version       = Apprentice::VERSION
  spec.authors       = 'Moritz Heiber'
  spec.email         = %w{moritz.heiber@gmail.com}
  spec.description   = 'A MariaDB/MySQL slave lag and cluster integrity checker'
  spec.summary       = 'Checks a given server for consistency and replication status'
  spec.homepage      = 'http://github.com/moritzheiber/apprentice'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w{lib}

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end

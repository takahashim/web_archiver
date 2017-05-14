# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'web_archiver/version'

Gem::Specification.new do |spec|
  spec.name          = "web_archiver"
  spec.version       = WebArchiver::VERSION
  spec.authors       = ["takahashim"]
  spec.email         = ["maki@rubycolor.org"]

  spec.summary       = %q{archive web pages.}
  spec.description   = %q{archive web pages.}
  spec.homepage      = "https://github.com/takahashim/web_archiver"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency "httpclient"
  spec.add_dependency "nokogiri"
end

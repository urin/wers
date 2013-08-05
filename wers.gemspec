# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wers/version'

Gem::Specification.new do |spec|
  spec.name          = "wers"
  spec.version       = Wers::VERSION
  spec.authors       = ["urin"]
  spec.email         = ["urinkun@gmail.com"]
  spec.summary       = %q{Manage multiple Ruby versions for Microsoft Windows}
  spec.description   = %q{Usage:
  wers command [options...]

Commands:
  init     Add current available Ruby path for global use.
  list     List all Ruby versions known by wers.
  add      Add specified version of Ruby to wers.
  delete   Delete specified version of Ruby from wers.
  global   Set or show the global Ruby version.
  local    Set or show the local directory-specific Ruby version.
  shell    Set or show the shell-specific Ruby version.
  version  Show the current Ruby version.
  help     Show this help.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.extensions    = ["ext/wers/extconf.rb"]
end

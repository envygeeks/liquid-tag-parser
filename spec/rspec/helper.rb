# Frozen-string-literal: true
# Copyright: 2017 - 2020 - ISC License
# Author: Jordon Bedwell
# Encoding: utf-8

require 'rspec'
require 'luna/rspec/formatters/checks'
Dir[File.expand_path('../support/*.rb', __dir__)].sort.each do |file|
  require file
end

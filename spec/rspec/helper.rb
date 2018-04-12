# Frozen-string-literal: true
# Copyright: 2017 - 2018 - MIT License
# Author: Jordon Bedwell
# Encoding: utf-8

require "rspec"
require "luna/rspec/formatters/checks"
Dir[File.expand_path("../../support/*.rb", __FILE__)].each do |v|
  require v
end

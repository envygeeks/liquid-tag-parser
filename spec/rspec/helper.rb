# Frozen-string-literal: true

# Copyright: 2017 - 2018 - MIT License
# Author: Jordon Bedwell

require 'rspec'
require 'luna/rspec/formatters/checks'
Dir[File.expand_path('../support/*.rb', __dir__)].sort.each do |file|
  require file
end

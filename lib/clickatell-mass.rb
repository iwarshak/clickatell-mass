require 'active_support'
require 'httparty'
require 'logger'
require 'ostruct'

require 'clickatell/mass/sender'
require 'clickatell/mass/query'

module Clickatell
  class ParsingError < RuntimeError; end
end
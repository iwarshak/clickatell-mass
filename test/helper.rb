require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'mocha'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'clickatell-mass'

Clickatell::Sender::CLICKATELL_USER = "asdf"
Clickatell::Sender::CLICKATELL_PASSWORD = "asdf"
Clickatell::Sender::CLICKATELL_APPID = "asdf"

class Test::Unit::TestCase
end

require 'rack'
require './hello.rb'
require './timing.rb'

use Timing
run Hello

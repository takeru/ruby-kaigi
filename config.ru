require 'appengine-rack'

ENV['RAILS_ENV'] = AppEngine::Rack.environment

require "pp"
require "appengine-apis/logger"
$app_logger = AppEngine::Logger.new

deferred = true #ENV['RAILS_ENV']=="production"
if deferred
  require "lib/deferred_dispatcher2"
  deferred_dispatcher = DeferredDispatcher2.new(
    :require => File.expand_path('../config/environment', __FILE__),
    :dispatch => 'ActionController::Dispatcher')
  map '/' do
    run deferred_dispatcher
  end
else
  map '/' do
    $app_logger.info "[INFO] Rails loading"
    require File.expand_path('../config/environment', __FILE__)
    run ActionController::Dispatcher.new
    $app_logger.info "[INFO] Rails loaded"
  end
end

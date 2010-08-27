require "appengine-apis/memcache"

$gae_created_at ||= Time.now
$gae_uuid ||= "GAE"+$gae_created_at.strftime("%Y%m%d_%H%M%S%Z")+"_"+java.util.UUID.randomUUID().to_s
class DeferredDispatcher2
  def initialize args
    @args = args
    @request_counter = 0
    @last_record_at = Time.now
  end

  def call env
    @request_counter += 1
    gae_instance_log
    start_time = Time.now
    if @runtime.nil?
      @runtime = true
      logger.warn "DeferredDispatcher2 runtime loaded: #{Time.now-start_time} uuid=[#{$gae_uuid}]"
      # 1: redirect with runtime and jruby-rack loaded
      redirect_or_error(env)
    elsif @rack_app.nil?
      require @args[:require]
      @rack_app = Object.module_eval(@args[:dispatch]).new
      logger.warn "DeferredDispatcher2 rack_app loaded: #{Time.now-start_time} uuid=[#{$gae_uuid}]"
      # 2: redirect with framework required & dispatched
      redirect_or_error(env)
    else
      result = nil
      begin
        # 3: process all other requests
        result = @rack_app.call(env)
        unless [200,302,304,404].include?(result[0])
          logger.warn("DeferredDispatcher2 error: uuid=[#{$gae_uuid}] status=#{result[0]}")
        end
      rescue Object => e
        logger.warn("DeferredDispatcher2 rescued: uuid=[#{$gae_uuid}] e=#{e.inspect} bt=[#{e.backtrace.join("\n")}]")
      ensure
        sec = Time.now-start_time
        if 5 <= sec
          logger.warn("DeferredDispatcher2 too long request: #{sec}sec.")
        end
      end
      result
    end
  end

  def redirect_or_error(env)
    if env['REQUEST_METHOD'].eql?('GET')
      redir_url = env['REQUEST_URI'] +
          (env['QUERY_STRING'].eql?('') ? '?' : '&') + Time.now.to_i.to_s
      res = ::Rack::Response.new('*', 302)
      res['Location'] = redir_url
      res.finish
    else
      ::Rack::Response.new('Service Unavailable', 503).finish
    end
  end

  def gae_instance_log
    if @request_counter<=2 || 30<(Time.now-@last_record_at)
      begin
        mc = AppEngine::Memcache.new(:namespace=>"AppEngineInstanceLog2")
        data = mc.get("data")
        data ||= {:instances=>{}, :created_at=>Time.now}
        data[:updated_at] = Time.now
        log = data[:instances][$gae_uuid]
        log ||= {
          :version        => com.google.apphosting.api.ApiProxy.getCurrentEnvironment.getVersionId,
          :gae_created_at => $gae_created_at,
          :created_at     => Time.now,
          :counts         => []
        }
        log[:updated_at] = Time.now
        log[:counts] = ([[@request_counter, Time.now]] + log[:counts])[0,10]
        data[:instances][$gae_uuid] = log
        if 250 < data[:instances].size
          data[:instances].keys.sort[0,50].each do |k|
            data[:instances].delete(k)
          end
        end
        mc.set("data", data)
      rescue => e
        logger.error("DeferredDispatcher2 gae_instance_log: e=#{e.inspect}")
      end
      @last_record_at = Time.now
    end
  end
  def logger
    return @logger if @logger
    require 'appengine-apis/logger'
    @logger = AppEngine::Logger.new
  end
end

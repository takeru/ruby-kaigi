class Admin::AdminController < ::Admin::Base
  def instances
    mc = AppEngine::Memcache.new(:namespace=>"AppEngineInstanceLog2")
    @data = mc.get("data")
    @active_counts = Hash.new{|h,k| h[k]=0 }
    prev_log = {}
    @logs = @data[:instances].keys.sort.reverse.collect do |uuid|
      log = @data[:instances][uuid]
      next if params[:version] && log[:version].index(params[:version])!=0

      log[:uuid] = uuid
      @active_counts[log[:version]] ||= 0
      log[:total_count]         = log[:counts].first.first rescue nil
      if 10 < log[:total_count]
        log[:req_per_min_current] = 60.0 * (log[:counts][1][0]-log[:counts][0][0]) / (log[:counts][1][1]-log[:counts][0][1]) rescue nil
      end
      log[:req_per_min_total]   = 60.0 * log[:total_count] / (log[:updated_at] - log[:gae_created_at]) rescue nil
      if Time.now - log[:updated_at] < 60.0
        @active_counts[log[:version]] += 1
      end
      if prev_log[log[:version]]
        prev_log[log[:version]][:create_delta_sec] = prev_log[log[:version]][:gae_created_at] - log[:gae_created_at]
      end
      prev_log[log[:version]] = log
    end.compact
  end

  def hhmmss(sec)
    sec = sec.to_i
    d  = sec / (24*60*60)
    hh = sec % (24*60*60) / 3600
    mm = sec % 3600 / 60
    ss = sec % 60
    ret = "%02d:%02d:%02d" % [hh,mm,ss]
    if 0<d
      ret = "#{d}d #{ret}"
    end
    ret
  end
  helper_method :hhmmss
end

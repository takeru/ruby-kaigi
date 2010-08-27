class User < TinyDS::Base
  property :twitter_info_json, :text
  property :screen_name, :string
  property :atoken,  :string, :index=>false
  property :asecret, :string, :index=>false

  property :badges, :list
  property :url,  :text
  property :memo, :text
  property :tags, :list
 #property :favorite_uids, :list
  property :counter, :integer, :default=>0

  property :registered_at, :time
  property :last_login_at, :time
  property :created_at, :time
  property :updated_at, :time

  def self.login(info, atoken, asecret)
    TinyDS.tx do
      u = User.get_by_id(info["id"])
      unless u
        u = User.new({}, :id=>info["id"])
      end
      u.twitter_info_json   = info.to_json
      u.screen_name         = info["screen_name"]
      u.url               ||= info["url"]

      u.atoken  = atoken
      u.asecret = asecret
      u.last_login_at   = Time.now
      u.registered_at ||= Time.now
      u.save
      u
    end
  end

  def self.prepare(info)
    TinyDS.tx do
      u = User.get_by_id(info["id"])
      unless u
        u = User.new({}, :id=>info["id"])
      end
      u.twitter_info_json = info.to_json
      u.screen_name = info["screen_name"]
      u.save
      u
    end
  end

  def self.badge_options
    [
     ['Attendee',           'attendee'],
     ['Attendee(Away)',     'away'],
     ['Speaker',            'speaker'],
     ['Committer',          'committer'],
     ['Individual Sponsor', 'individual_sponsor'],
     ['Sponsor',            'sponsor'],
     ['Staff',              'staff'],
    ]
    #dubious.png
  end

  def self.valid_badge_key?(b)
    @@valid_badge_keys ||= badge_options.collect{|a,b| b }
    return @@valid_badge_keys.include?(b)
  end

  def badges=(_badges)
    set_property(:badges, _badges.select{|b| User.valid_badge_key?(b) })
  end

  def twitter_info
    @twitter_info ||= JSON.parse(self.twitter_info_json)
  end

  ["profile_image_url","name"].each do |n|
    define_method n do
      twitter_info[n]
    end
  end

  require "appengine-apis/memcache"
  def self.get_cache(ids, opts={})
    _ids = ids.kind_of?(Array) ? ids : [ids]
    mc = AppEngine::Memcache.new(:namespace=>"user_cache")
    user_caches = if opts[:reload]
                    {}
                  else
                    mc.get_hash(*_ids)
                  end
#p "user_caches=#{user_caches.inspect}"
    new_user_ids = []
    _ids.each{|_id| new_user_ids << _id if user_caches[_id].nil? }
#p "new_user_ids=#{new_user_ids.inspect}"
    unless new_user_ids.empty?
      users = User.get_by_ids(new_user_ids)
      new_user_caches = {}
      users.each do |u|
        next unless u
        new_user_caches[u.id] = to_cache_hash(u)
      end
      mc.set_many(new_user_caches, 30*60) # 30mins.
#p "mc.set_many(new_user_caches)=#{new_user_caches.keys.inspect}"
      user_caches.merge!(new_user_caches)
    end

    if ids.kind_of?(Array)
      user_caches
    else
      user_caches[ids]
    end
  end
  def self.to_cache_hash(u)
    {:user_id=>u.id, :screen_name=>u.screen_name, :profile_image_url=>u.profile_image_url}
  end
end

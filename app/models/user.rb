class User < TinyDS::Base
  property :twitter_info_json, :text
  property :screen_name, :string
  property :atoken,  :string, :index=>false
  property :asecret, :string, :index=>false

  property :url,  :text
  property :memo, :text
  property :tags, :list

  property :created_at, :time
  property :updated_at, :time

  def self.login(info, atoken, asecret)
    TinyDS.tx do
      u = User.get_by_id(info["id"])
      unless u
        u = User.new({}, :id=>info["id"])
        u.url = info["url"]
      end
      u.twitter_info_json = info.to_json
      u.screen_name = info["screen_name"]
      u.atoken  = atoken
      u.asecret = asecret
      u.save
      u
    end
  end

  def twitter_info
    @twitter_info ||= JSON.parse(self.twitter_info_json)
  end

  ["profile_image_url"].each do |n|
    define_method n do
      twitter_info["profile_image_url"]
    end
  end
end

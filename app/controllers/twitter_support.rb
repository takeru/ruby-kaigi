require "twitter_oauth" # http://github.com/moomerman/twitter_oauth
module TwitterSupport
  def new_twitter_client(opts={})
    TwitterOAuth::Client.new(
      :consumer_key    => twitter_config["oauth"]["key"],
      :consumer_secret => twitter_config["oauth"]["secret"],
      :token           => opts[:access_token],
      :secret          => opts[:access_secret]
    )
  end
  def twitter_config
    @twitter_config ||= YAML.load_file(Pathname(RAILS_ROOT)+"config"+"secret.yaml")["twitter"]
  end

  def user_twitter_client
    if logged_in?
      new_twitter_client(:access_token=>current_user.atoken, :access_secret=>current_user.asecret)
    else
      nil
    end
  end
  def anon_twitter_client
    u = User.get_by_id(182874406) # @gae_jruby_demo
    new_twitter_client(:access_token=>u.atoken, :access_secret=>u.asecret)
  end
end

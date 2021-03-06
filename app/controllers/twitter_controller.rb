class TwitterController < ApplicationController
  def login
    client = new_twitter_client
    p client
    callback_url = url_for(:action=>"callback")
    request_token = client.request_token(:oauth_callback=>callback_url)
    session[:rt] = request_token.token
    session[:rs] = request_token.secret
    redirect_to request_token.authorize_url
  end
  def callback
    client = new_twitter_client
    access_token = client.authorize(
                     session[:rt],
                     session[:rs],
                     :oauth_verifier => params[:oauth_verifier]
                   )
    session[:rt] = nil
    session[:rs] = nil
    if client.authorized?
      info = client.info
      @user = User.login(info, access_token.token, access_token.secret)
      session[:user_id] = @user.id
      flash[:notice] = "Hello, @#{@user.screen_name}!!"
      redirect_to :controller=>"users", :action=>"edit"
    else
      render :text=>"NG"
    end
  end
  def logout
    session[:user_id] = nil
    reset_session
    redirect_to "/"
  end

  def tweet
    unless logged_in?
      redirect_to :controller=>"twitter", :action=>"login"
      return
    end

    tw = user_twitter_client
    tw.update(params[:status])

    flash[:notice] = "tweeted!! '#{params[:status]}'"
    redirect_to :controller=>"users", :action=>"show", :screen_name=>params[:screen_name]
  end

  def demo_twitter_jruby
    require 'twitter' # "twitter-jruby" gem
    sio = StringIO.new

    # http://route477.net/w/?RubyTwitterJa
    sio.puts Twitter.user("urekat").pretty_inspect
    sio.puts Twitter.follower_ids("urekat").pretty_inspect
    sio.puts Twitter.friend_ids("urekat").pretty_inspect
    sio.puts Twitter.timeline("urekat").pretty_inspect

    response.headers["Content-Type"] = "text/plain"
    render :text=>sio.string
  end
end

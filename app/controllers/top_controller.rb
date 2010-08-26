class TopController < ApplicationController
  def index
    # cache!!
    @user_count = User.count # todo 1000+??
    @users      = User.query.sort(:counter, :desc).all #(:limit=>50, :offset=>@offset)
  end

  def sitemap
    # cache!!
  end
  
  def ping
    render :text=>"OK #{Time.now}"
  end
end

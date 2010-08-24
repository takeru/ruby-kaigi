class UsersController < ApplicationController
  def list
    @user_count = User.count # todo 1000+??
    @offset = (params[:offset] || 0).to_i
    @users = User.query.sort(:created_at, :desc).all(:limit=>50, :offset=>@offset)
  end
  def show
    users = User.query.filter(:screen_name=>params[:screen_name]).all
    if users.empty?
      redirect_to :action=>"list"
      return
    end
    if 2 <= users.size
      raise "OMG! users.size=#{users.size}"
    end
    @user = users.first
  end
end

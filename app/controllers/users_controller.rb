class UsersController < ApplicationController
  def list
    @offset = (params[:offset] || 0).to_i

    @user_count = User.count # todo 1000+??
    @users      = User.query.sort(:created_at, :desc).all(:limit=>50, :offset=>@offset)
    @title      = "All users"
  end
  def list_by_tag
    q = User.query.filter(:tags=>params[:tag])
    @user_count = q.count
    @users      = q.all
    @title = "Tag '#{params[:tag]}' users"
    render :action=>"list"
  end
  def list_by_badge
    q = User.query.filter(:badge=>params[:badge])
    @user_count = q.count
    @users      = q.all
    @title      = "Badge '#{params[:badge]}' users"
    render :action=>"list"
  end
  def tags
  end

  def edit
    unless logged_in?
      redirect_to :action=>"list"
      return
    end
    @user = current_user
    if request.put?
      @user.tx do |u|
        u.badge = params[:user][:badge]
        u.url   = params[:user][:url]
        u.memo  = params[:user][:memo]
        u.tags  = params[:user][:tags].strip.split(/[\s,]/).compact.uniq.collect{|t| t.downcase }

        u.save
      end
      flash[:notice] = "saved!"
      redirect_to :action=>"show", :screen_name=>@user.screen_name
      return
    end
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
    if !logged_in? || @user.id != current_user.id
      @user.tx do |u|
        u.counter += 1
        u.save
      end
    end
  end
end

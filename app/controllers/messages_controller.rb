class MessagesController < ApplicationController
  def create
    unless logged_in?
      redirect_to :controller=>"twitter", :action=>"login"
      return
    end

    sid = current_user.id
    rid = params[:message][:receiver_id].to_i
    TinyDS.tx do
      key = Message.key_from_sender_id_receiver_id(sid,rid)
      m = Message.get(key)
      unless m
        m = Message.new({}, :key=>key)
        m.sender_id   = sid
        m.receiver_id = rid
      end
      m.body = params[:message][:body] if params[:message][:body]
      m.save
    end
    receiver = User.get_by_id(rid)
    redirect_to :controller=>"users", :action=>"show", :screen_name=>receiver.screen_name
  end
end

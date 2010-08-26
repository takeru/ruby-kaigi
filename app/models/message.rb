class Message < TinyDS::Base
  property :sender_id,   :integer
  property :receiver_id, :integer

  property :body,        :text

  property :created_at,  :time
  property :updated_at,  :time

  def self.key_from_sender_id_receiver_id(sid, rid)
    build_key("#{sid}|#{rid}", nil)
  end
end

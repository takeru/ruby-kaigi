class Article < TinyDS::Base
  property :title,      :string
  property :summary,    :text
  property :url,        :string
  property :pages,      :integer
  property :created_at, :time
  property :updated_at, :time
end

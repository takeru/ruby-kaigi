class CacheUtil
  def update_tag_counts(tags)
    tag_to_counts = {}
    tags.each do |tag|
      tag_to_counts[tag] = User.query.filter(:tags=>tag).count
    end
    set_tag_count(tag_to_counts)
    nil
  end
  def set_tag_count(tag_to_counts)
    memcache_for_tag_count.set_many(tag_to_counts)
    _tags = ((get_tags-tag_to_counts.keys) + tag_to_counts.keys.select{|k| 0<tag_to_counts[k] }).sort.uniq
    memcache.set("tags", _tags)
  end
  def get_tags
    memcache.get("tags") || []
  end
  def get_tag_and_counts(tags=:all)
    tags = get_tags if tags==:all
    memcache_for_tag_count.get_hash(*tags)
  end
  def memcache
    @memcache ||= AppEngine::Memcache.new(:namespace=>"CacheUtil")
  end
  def memcache_for_tag_count
    @memcache_for_tag_count ||= AppEngine::Memcache.new(:namespace=>"CacheUtil:tag_count")
  end
end

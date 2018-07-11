class Group
  include Mongoid::Document
  field :gid, type: String
  field :name, type: String
  field :is_private, type: Boolean
  field :last_fetched_at, type: DateTime
  has_and_belongs_to_many :users
  has_and_belongs_to_many :summaries
  index({ gid: 1 }, {})
  index({ name: 1 }, {})

  def self.find_or_fetch(client, gid)
    group = self.where(gid: gid).first
    if group
      group.fetch(client) unless (group.last_fetched_at && group.last_fetched_at > 24.hours.ago)
      user
    else
      self.fetch(client, gid)
    end
  end

  def self.fetch(client, gid)
    channel = client.channel_info(channel: gid)
    group = client.group_info(group: gid)
    if channel['ok']
      raw = channel['channel']
      is_private = false
    elsif group['ok']
      raw = group['group']
    else
      return nil
    end
    new_group = Group.create(
      gid: raw['id'],
      name: raw['name'],
      is_private: is_private
      last_fetched_at: Time.now,
    )
    raw['members'].each do |member|
      new_group.users << User.find(:all, :conditions => { :uid => member })
    end
    new_group.save
  end

  def fetch(client)
    channel = client.channel_info(channel: gid)
    group = client.group_info(group: gid)
    if channel['ok']
      raw = channel['channel']
      is_private = false
    elsif group['ok']
      raw = group['group']
    else
      return
    end
    self.update(
      name: raw['name'],
      last_fetched_at: Time.now,
    )
    raw['members'].each do |member|
      self.users << User.find(:all, :conditions => { :uid => member })
    end
    self.save
  end
end
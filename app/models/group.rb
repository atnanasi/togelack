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
      group
    else
      self.fetch(client, gid)
    end
  end

  def self.fetch(client, gid)
    new_group = Group.create()
    raw = new_group.channel_data(client, gid)

    new_group.update(
      gid: raw['id'],
      name: raw['name'],
      is_private: raw['is_group'],
      last_fetched_at: Time.now,
    )
    new_group.users = raw['members'].map do |member|
      User.where(uid: member)
    end
    new_group.save
  end

  def fetch(client)
    raw = self.channel_data(client, gid)

    self.users = raw['members'].map do |member|
      User.where(uid: member)
    end
    self.save
    self.update(
      name: raw['name'],
      last_fetched_at: Time.now,
    )
  end


  def channel_data(client, gid)
    if gid[0]=='C'
      channel = Rails.cache.fetch("channels##{gid}", expires_in: 1.hours) do
        hit = nil
        channels = client.channels_list()['channels']
        channels.each do |ch|
          if ch['id']==gid
            hit = ch
            hit['is_group'] = false
          end
          Rails.cache.write("channels##{ch['id']}", ch)
        end
        hit
      end
      return channel
    elsif gid[0]=='G'
      group = Rails.cache.fetch("groups##{gid}", expires_in: 1.hours) do
        hit = nil
        groups = client.groups_list()['groups']
        groups.each do |gr|
          if gr['id']==gid
            hit = gr
            hit['is_group'] = true
          end
          Rails.cache.write("groups##{gr['id']}", gr)
        end
        hit
      end
      return group
    else
      return nil
    end
  end
end
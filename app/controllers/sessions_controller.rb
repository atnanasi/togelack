class SessionsController < ApplicationController
  skip_before_action :require_login_in_private

  # GET /auth/slack/callback
  def create
    auth = request.env['omniauth.auth']

    redirect_to '/' unless auth
    redirect_to '/' unless auth['provider'] == 'slack'
    redirect_to '/' unless auth['info']['team_id'] == ENV['SLACK_TEAM_ID']

    user = User.find_or_initialize_by(uid: auth['uid'])
    user.name = auth['info']['nickname']
    user.avatar_url = auth['info']['image']
    user.is_admin = auth.extra.user_info['user']['is_admin']
    user.save!

    client = Slack::Client.new(token: ENV['SLACK_TOKEN'])

    channels_list = client.channels_list()['channels']
    channels_list.each do |channel|
      Group.find_or_fetch(client, channel["id"])
    end

    groups_list = client.groups_list()['groups']
    groups_list.each do |group|
      Group.find_or_fetch(client, group["id"])
    end

    session[:user_id] = user.uid
    session[:token] = auth.credentials.token

    redirect_to '/'
  end

  # DELETE /logout
  def destroy
    session[:user_id] = nil
    session[:token] = nil
    redirect_to '/'
  end
end

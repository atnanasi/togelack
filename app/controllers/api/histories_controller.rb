require 'slack'

module API
  class HistoriesController < ApplicationController
    before_action :do_check_login

    # 暫定
    # GET /api/histories.json?url=http://〜
    def index
      client = Slack::Client.new(token: session[:token])
      chs = Services::CacheHistoryService.new(client)
      messages = chs.cache(params[:url])

      archive_url = SlackSupport::ArchiveURL.new(params[:url])
      is_private = archive_url.channel.start_with?("G")

      render json: {result: MessageDecorator.decorate_collection(messages), is_private: is_private}, root: nil
    end
  end
end

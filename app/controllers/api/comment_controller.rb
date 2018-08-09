require 'slack'
require 'date'

module API
  class CommentController < ApplicationController
    before_action :do_check_login

    # 暫定
    # GET /api/comment.json?text=some_text
    def index
      comment = [Message.find_or_initialize_by(
        user: @current_user["uid"],
        text: params[:text],
        type: "comment",
        channel: "togelack",
        channel_name: "togelack",
        ts: Time.now.to_i.to_s,
      )]
      render json: {result: MessageDecorator.decorate_collection(comment)}, root: nil
    end
  end
end

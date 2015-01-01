class ChangesetCommentsController < ApplicationController
  layout 'site', :except => :rss

  before_filter :authorize_web
  before_filter :set_locale
  before_filter :require_user, :only => [:list, :new, :edit, :comment, :hide, :hidecomment]
  before_filter :lookup_this_user, :only => [:view, :comments]
  before_filter :check_database_readable
  before_filter :check_database_writable, :only => [:new, :edit]
  before_filter :require_administrator, :only => [:hide, :hidecomment]

  # Counts and selects pages of GPX comments for various criteria (by user, tags, public etc.).
  #  target_user - if set, specifies the user to fetch comments for.  if not set will fetch all comments
  def list
    # from display name, pick up user id if one user's comments only
    display_name = params[:display_name]
    if !display_name.blank?
      target_user = User.active.where(:display_name => display_name).first
      if target_user.nil?
        render_unknown_user display_name
        return
      end
    end

    # set title
    if target_user.nil?
      @title = t 'trace.list.public_comments'
    elsif @user and @user == target_user
      @title = t 'trace.list.your_comments'
    else
      @title = t 'trace.list.public_comments_from', :user => target_user.display_name
    end

    @title += t 'trace.list.tagged_with', :tags => params[:tag] if params[:tag]


    if target_user.nil? # all comments
      @comments = ChangesetComment.all
    else
      if current_user and current_user == target_user and params[:type] == 'received_subscribed'
        @comments = ChangesetComment.joins(:changeset)
        .joins('inner join changesets_subscribers on changesets.id = changesets_subscribers.changeset_id')
        .where('changesets.user_id = ?', current_user.id)
        .where('changesets_subscribers.subscriber_id = ?', current_user.id)
      elsif !params[:type].blank? and params[:type] == 'received'
        @comments = ChangesetComment.joins(:changeset).where('changesets.user_id = ?', target_user.id)
      else
        @comments = target_user.changeset_comments
      end
    end

    @page = (params[:page] || 1).to_i
    @page_size = 20

    @comments = @comments.order("created_at DESC")
    @comments = @comments.offset((@page - 1) * @page_size)
    @comments = @comments.limit(@page_size)
    @comments = @comments.includes(:author)

    # final helper vars for view
    @target_user = target_user
    @display_name = target_user.display_name if target_user
  end

end

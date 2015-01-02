class ChangesetCommentsController < ApplicationController
  layout 'site'

  before_filter :authorize_web
  before_filter :set_locale
  before_filter :require_user, :only => [:mine]

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
    if target_user.nil? # all comments
      @title = t 'changeset_comments.list.all_changesets_comments'
    else
      if current_user and current_user == target_user and params[:type] == 'subscribed'
        @title = t 'changeset_comments.list.subscribed_changesets_comments'
        @type = 'subscribed'
      elsif !params[:type].blank? and params[:type] == 'received'
        @title = t 'changeset_comments.list.received_changesets_comments'
        @type = 'received'
      elsif current_user and current_user == target_user
        @title = t 'changeset_comments.list.own_changesets_comments'
        @type = 'own'
      else
        @title = t 'changeset_comments.list.user_changesets_comments', :user => target_user.display_name
      end
    end

    if target_user.nil? # all comments
      @comments = ChangesetComment.all
    else
      if current_user and current_user == target_user and params[:type] == 'subscribed'
        @comments = ChangesetComment.joins(:changeset)
        .joins('inner join changesets_subscribers on changesets.id = changesets_subscribers.changeset_id')
        .where('changesets_subscribers.subscriber_id = ?', current_user.id)
      elsif !params[:type].blank? and params[:type] == 'received'
        @comments = ChangesetComment.joins(:changeset).where('changesets.user_id = ?', target_user.id)
      else
        @comments = target_user.changeset_comments
      end
    end

    @page = (params[:page] || 1).to_i
    @page_size = 20

    @comments = @comments.visible
    @comments = @comments.order("changeset_comments.created_at DESC")
    @comments = @comments.offset((@page - 1) * @page_size)
    @comments = @comments.limit(@page_size)
    @comments = @comments.includes(:author,:changeset, :changeset => :user)

    # final helper vars for view
    @target_user = target_user
    @display_name = target_user.display_name if target_user
  end

  def mine
    redirect_to :action => :list, :display_name => @user.display_name, :type => params[:type]
  end
end

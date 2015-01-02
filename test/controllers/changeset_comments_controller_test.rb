require 'test_helper'

class ChangesetCommentsControllerTest < ActionController::TestCase
  fixtures :users, :changeset_comments, :changesets_subscribers

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/changeset_comments", :method => :get },
      { :controller => "changeset_comments", :action => "list" }
    )
    assert_routing(
      { :path => "/changeset_comments/page/1", :method => :get },
      { :controller => "changeset_comments", :action => "list", :page => "1" }
    )
    assert_routing(
      { :path => "/user/username/changeset_comments", :method => :get },
      { :controller => "changeset_comments", :action => "list", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/changeset_comments/page/1", :method => :get },
      { :controller => "changeset_comments", :action => "list", :display_name => "username", :page => "1" }
    )
    assert_routing(
        { :path => "/user/username/changeset_comments/subscribed", :method => :get },
        { :controller => "changeset_comments", :action => "list", :display_name => "username", :type => "subscribed" }
    )
    assert_routing(
        { :path => "/user/username/changeset_comments/subscribed/page/1", :method => :get },
        { :controller => "changeset_comments", :action => "list", :display_name => "username", :type => "subscribed", :page => "1" }
    )
    assert_routing(
      { :path => "/changeset_comments/mine", :method => :get },
      { :controller => "changeset_comments", :action => "mine" }
    )
    assert_routing(
      { :path => "/changeset_comments/mine/page/1", :method => :get },
      { :controller => "changeset_comments", :action => "mine", :page => "1" }
    )
    assert_routing(
        { :path => "/changeset_comments/mine/received", :method => :get },
        { :controller => "changeset_comments", :action => "mine", :type => "received" }
    )
    assert_routing(
        { :path => "/changeset_comments/mine/received/page/1", :method => :get },
        { :controller => "changeset_comments", :action => "mine", :page => "1", :type => "received" }
    )
  end

  # Check that the list of changesets is displayed
  def test_list
    get :list
    check_changeset_comments_list ChangesetComment.all
  end

  # Check that I can get mine
  def test_list_mine
    # First try to get it when not logged in
    get :mine
    assert_redirected_to :controller => 'user', :action => 'login', :referer => '/changeset_comments/mine'

    # Now try when logged in
    get :mine, {}, {:user => users(:public_user).id}
    assert_redirected_to :controller => 'changeset_comments', :action => 'list', :display_name => users(:public_user).display_name

    # Fetch the actual list
    get :list, {:display_name => users(:second_public_user).display_name}, {:user => users(:second_public_user).id}
    check_changeset_comments_list users(:second_public_user).changeset_comments

    # Should be able to see own subscribed changesets comments
    get :list, {:display_name => users(:normal_user).display_name, :type => 'subscribed'}, {:user => users(:normal_user).id}
    check_changeset_comments_list ChangesetComment.where(changeset_id: users(:normal_user).changeset_subscriptions.map(&:id))
  end

  # Check the list of changeset comments for a specific user
  def test_list_user
    # Test a user with no changeset comments
    get :list, :display_name => users(:public_user).display_name
    check_changeset_comments_list users(:public_user).changeset_comments

    # Test a user with some changeset comments
    get :list, :display_name => users(:second_public_user).display_name
    check_changeset_comments_list users(:second_public_user).changeset_comments

    # Should still see only user ones when authenticated as another user
    get :list, {:display_name => users(:second_public_user).display_name}, {:user => users(:normal_user).id}
    check_changeset_comments_list users(:second_public_user).changeset_comments

    # Should be able to see user's received comments
    get :list, :display_name => users(:normal_user).display_name, :type => 'received'
    check_changeset_comments_list ChangesetComment.where(changeset_id: users(:normal_user).changesets.map(&:id))

    # Should still see only user ones when authenticated as another user
    get :list, {:display_name => users(:normal_user).display_name, :type => 'received'}, {:user => users(:public_user).id}
    check_changeset_comments_list ChangesetComment.where(changeset_id: users(:normal_user).changesets.map(&:id))
  end

private
  def check_changeset_comments_list(changeset_comments)
    assert_response :success
    assert_template "list"

    if changeset_comments.count > 0
      assert_select "table#changeset_comments_list tbody", :count => 1 do
        assert_select "tr", :count => changeset_comments.visible.count do |rows|
          changeset_comments.visible.order("created_at DESC").zip(rows).each do |changeset_comment,row|
            assert_select row, "td", Regexp.new(Regexp.escape(changeset_comment.body))
            assert_select row, "td", Regexp.new(Regexp.escape(changeset_comment.changeset.user.display_name))
          end
        end
      end
    else
      assert_select "h4", /No comments to display/
    end
  end
end

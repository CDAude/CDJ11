class DebatesController < ApplicationController
  include FeatureFlags
  include CommentableActions
  include FlagActions

  before_action :parse_tag_filter, only: :index
  before_action :authenticate_user!, except: [:index, :show, :map]

  feature_flag :debates

  invisible_captcha only: [:create, :update], honeypot: :subtitle

  has_orders %w{created_at confidence_score most_commented featured relevance}, only: :index
  has_orders %w{most_voted newest oldest}, only: :show

  load_and_authorize_resource
  helper_method :resource_model, :resource_name
  respond_to :html, :js

  def index_customization
    @featured_debates = @debates.featured
    @proposal_successfull_exists = Proposal.successful.exists?
  end

  def show
    super
    redirect_to debate_path(@debate), status: :moved_permanently if request.path != debate_path(@debate)
  end
  
  def mark_featured
    @debate.update_attribute(:featured_at, Time.current)
  end

  def unmark_featured
    @debate.update_attribute(:featured_at, nil)
  end
  
  def vote
    @debate.register_vote(current_user, params[:value])
    set_debate_votes(@debate)
    if (@debate.likes - @debate.dislikes) >= Setting['votes_for_debate_success'].to_i
      mark_featured
    end
  end

  private

    def debate_params
      params.require(:debate).permit(:title, :description, :tag_list, :terms_of_service)
    end

    def resource_model
      Debate
    end
end

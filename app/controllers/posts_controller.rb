class PostsController < ApplicationController

  before_action :doorkeeper_authorize!, only: [:create]

  def index
    authorize Post
    posts = find_posts!
    render json: posts, meta: meta_for(Post)
  end

  def show
    post = find_post!
    authorize post

    render json: post, include: [:comments]
  end

  def create
    authorize Post
    post = Post.new(create_params)
    if post.save
      render json: post
    else
      render_validation_errors post.errors
    end
  end

  private

    def create_params
      record_attributes.permit(:markdown, :title, :post_type).merge(relationships)
    end

    def project_relationship_id
      record_relationships.fetch(:project, {}).fetch(:data, {})[:id]
    end

    def user_id
      current_user.id
    end

    def relationships
      { project_id: project_relationship_id, user_id: user_id }
    end

    def project_id
      params[:project_id]
    end

    def post_id
      params[:id]
    end

    def find_project!
      Project.find(project_id)
    end

    def find_post!
      project = find_project!
      Post.includes(comments: :user).find_by!(project: project, number: post_id)
    end

    def find_posts!
      project = find_project!
      Post.where(project: project).page(page_number).per(page_size).includes [:comments, :user, :project]
    end
end

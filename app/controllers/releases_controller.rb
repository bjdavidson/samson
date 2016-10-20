# frozen_string_literal: true
class ReleasesController < ApplicationController
  include CurrentProject

  before_action :authorize_project_deployer!, except: [:show, :flow, :index]
  before_action :find_release, only: [:show, :flow]

  def show
    @changeset = @release.changeset
  end

  def flow
    groups = ENV.fetch("RELEASE_FLOW").split("|").map { |g| g.split(",") }

    @release_flow = groups.map do |env_values|
      stage = current_project.stages.detect {|stage| stage.deploy_groups.map(&:env_value).sort == env_values.sort }
      [env_values, stage]
    end
  end

  def index
    @stages = @project.stages
    @releases = @project.releases.sort_by_version.page(params[:page])
  end

  def new
    @release = @project.releases.build
    @release.assign_release_number
  end

  def create
    @release = ReleaseService.new(@project).create_release!(release_params)
    redirect_to [@project, @release]
  end

  private

  def release_params
    params.require(:release).permit(:commit, :number).merge(author: current_user)
  end

  def find_release
    @release = @project.releases.find_by_version!(params[:id])
  end
end

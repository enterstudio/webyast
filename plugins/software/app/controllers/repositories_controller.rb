class RepositoriesController < ApplicationController

  before_filter :login_required

  # cache index and show action
  before_filter :check_cache_status, :only => [:index, :show]
  before_filter :check_read_permissions, :only => [:index, :show]
  caches_action :index, :show

  CACHE_ID = 'repositories:timestamp'

  private

  # check whether the cached result is still valid
  def check_cache_status
    cache_timestamp = Rails.cache.read(CACHE_ID)

    if cache_timestamp.nil?
	# this is the first run, the cache is not initialized yet, just return
	Rails.cache.write(CACHE_ID, Time.now)
    # the cache expires when /etc/zypp/repos.d is modified
    elsif cache_timestamp < Repository.mtime
	Rails.logger.debug "#### Repositories cache expired"
	expire_action :action => :index, :format => params["format"]
	expire_action :action => :show, :format => params["format"]
	Rails.cache.write(CACHE_ID, Time.now)
    end
  end

  def check_read_permissions
    permission_check "org.opensuse.yast.system.repositories.read"
  end


  public

  # GET /repositories.xml
  def index
    # read permissions were checked in a before filter
    @repos = Repository.find(:all)
  end

  # GET /repositories/my_repo.xml
  def show
    # read permissions were checked in a before filter

    repos = Repository.find(params[:id])
    if repos.nil? || repos.size.zero?
      Rails.logger.error "Repository #{params[:id]} not found."
      render ErrorResult.error(404, 1, "Repository #{params[:id]} was not found.") and return
    end

    @repo = repos.first
  end

  def update
    permission_check "org.opensuse.yast.system.repositories.write"

    param = params[:repositories]
    if param.blank?
      render ErrorResult.error(404, 1, "Missing parameters for repository #{params[:id]}") and return
    end

    @repo = Repository.new(params[:id], param[:name], (param[:enabled] == true || param[:enabled] == 'true' || param[:enabled] == '1'))

    @repo.autorefresh = param[:autorefresh] == 'true' || param[:enabled] == '1'
    @repo.keep_packages = param[:keep_packages] == 'true' || param[:keep_packages] == '1'
    @repo.url = param[:url]
    @repo.priority = param[:priority].to_i

    unless @repo.save
      render ErrorResult.error(404, 2, "packagekit error") and return
    end

    render :show
  end

  # POST /repositories/
  def create
    permission_check "org.opensuse.yast.system.repositories.write"

    param = params[:repositories]
    if param.blank?
      render ErrorResult.error(404, 1, "Missing parameters for repository #{params[:id]}") and return
    end

    @repo = Repository.new(params[:id].to_s, param[:name].to_s, param[:enabled])

    unless @repo.save
      render ErrorResult.error(404, 2, "Cannot save repository '#{@repo.id}'") and return
    end
    render :show
  end

  def destroy
    permission_check "org.opensuse.yast.system.repositories.write"

    repos = Repository.find(params[:id])

    if repos.nil? || repos.size.zero?
      Rails.logger.error "Repository #{params[:id]} was not found."
      render ErrorResult.error(404, 1, "Repository '#{params[:id]}' not found.") and return
    end

    @repo = repos.first

    unless @repo.destroy
      render ErrorResult.error(404, 2, "packagekit error") and return
    end

    render :show
  end

end
#--
# Copyright (c) 2009-2010 Novell, Inc.
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++

include ApplicationHelper

class UsersController < ApplicationController

  private

  def init_cache(controller_name = request.parameters["controller"])
    if params[:getent] == "1"
      super "getent_passwd"
    else
      super
    end
  end

  def save_roles (userid,roles_string)
    all_roles = Role.find :all
    roles = roles_string.split(",")
    my_roles=[]
    all_roles.each do |role|
      role.name=role.name
      if role.users.include?(userid)
       if roles.include?(role.name)
        # already written - do nothing
        roles.delete(role.name)
       else
        # remove item
        role.users.delete(userid)
        role.save
        roles.delete(role.name)
       end
      end
    end
    roles.each do |role|
      # this should be added
      r = Role.find(role)
      r.name=r.name
      r.users << userid
      r.save
    end
  end

  def all_users
    all_users_list = []
    all_users = User.find :all
    all_users.each do |user|
      all_users_list.push(user.uid)
    end
    all_users_list.join(",")
  end

  public

  # GET /users
  # GET /users.xml
  # GET /users.json
  def index
    authorize! :usersget, User
    if params[:getent] == "1"
      respond_to do |format|
        format.html { render  :xml => GetentPasswd.find.to_xml }
        format.xml { render  :xml => GetentPasswd.find.to_xml }
        format.json { render :json => GetentPasswd.find.to_json }
      end
      return
    end

    @users = User.find_all params
    Rails.logger.error "No users found." if @users.nil?
    respond_to do |format|
      format.xml {
        if @users.nil?
          render ErrorResult.error(404, 2, "No users found") and return
        else
          render  :xml => @users.to_xml(:root => "users",
                  :dasherize => false )
        end
      }
      format.json {
        if @users.nil?
          render ErrorResult.error(404, 2, "No users found") and return
        else
          render :json => @users.to_json
        end
      }
      format.html {
        if @users.nil?
          flash[:error] = _("No users found.")
        else
          @users.each do |user|
            user.user_password2 = user.user_password
            user.uid_number     = user.uid_number
            user.grp_string     = user.grouplist.keys.join(",")
            my_roles=[]
            all_roles=[]
            @roles= Role.find :all
            @roles.each do |role|
              if role.users.include?(user.id)
                my_roles.push(role.name)
              end
              all_roles.push(role.name)
            end if @roles

            user.roles_string = my_roles.join(",")
            @all_roles_string = all_roles.join(",")
            @groups = []
            if can? :groupsget, User
              @groups = Group.find :all
            end
            grps_list=[]
            @groups.each do |group|
              grps_list.push(group.cn)
            end
            @all_grps_string = grps_list.join(",")
          end unless @users.nil?
        end
        render :index
      }
    end
  end

  # GET /users/:user_id.xml
  def show
    authorize! :userget, User
    if params[:id].blank?
      problem :error, "No user id given"
      return
    end
    @user = User.find(params[:id])
    if @user.nil?
      problem :not_found, "User '#{params[:id]}' not found"
      return
    end

    respond_to do |format|
      format.html { redirect_to :index    }
      format.xml  { render  :xml => @user }
      format.json { render :json => @user }
    end
  rescue Exception => e
    problem :error, e.message
  end

  # GET /users/new
  def new
    authorize! :useradd, User
    @user = User.new()
    @all_roles_string = ""
    all_roles=[]
    @roles = Role.find :all
    my_roles=[]
    @roles.each do |role|
      all_roles.push(role.name)
    end if @roles
    users = User.find :all
    @all_roles_string = all_roles.join(",")
    @all_users_string = users.map(&:uid).join(',')
    @all_uid_numbers_string = users.map(&:uid_number).join(',')

    @groups = []
    if can? :groupsget, User
      @groups = Group.find :all
    end
    grp_list=[]
    @groups.each do |group|
     grp_list.push(group.cn)
    end
    @all_grps_string = grp_list.join(",")

    @user.grp_string = ""
  end


  # GET /users/:user_id/edit
  def edit
    authorize! :usermodify, User
    @user = User.find(params[:id])
    @groups = Group.find(:all)

    #FIXME handle if id is invalid

    @user.type	= ""
    @user.id	= @user.uid # use id for storing index value (see update)
    @user.grp_string = ""

    @all_grps_string = ""
    @user.grouplist.each do |group|
       if @user.grp_string.blank?
          @user.grp_string = group.cn
       else
          @user.grp_string += ",#{group.cn}"
       end
    end
    @groups.each do |group|
       if @all_grps_string.blank?
          @all_grps_string = group.cn
       else
          @all_grps_string += ",#{group.cn}"
       end
    end
  end


  # POST /users
  # POST /users.xml
  # POST /users.json
  def create
    authorize! :useradd, User
    user_params = params[:user] || {}
    @user = User.create user_params
    if @user.roles_string.present?
      save_roles @user.id, @user.roles_string
    end
    @user = User.new user_params

    respond_to do |format|
      format.xml  { render :xml  => @user }
      format.json { render :json => @user }
      format.html do
        flash[:notice] = _("User %s was successfully created.") % @user.uid
        redirect_to :action => "index", :controller=>'users'
      end
    end
  end

  # PUT /users/:user_id
  # PUT /users/:user_id.xml
  def update
    authorize! :usermodify, User
    @user = User.find(params[:user][:id])
    if @user
      roles = params[:user][:roles_string]
      if roles && roles.present?
        save_roles @user.id, roles
      end
      @user.load_attributes(params[:user])
      @user.type = "local"
      @user.grouplist = {}
      params[:user][:grp_string].split(",").each do |groupname|
        @user.grouplist[groupname.strip] = "1"
      end unless params[:user][:grp_string].blank?
      @user.save(params[:user][:id])
    else
      problem :not_found, "User '#{params[:user][:id]}' not found"
      return
    end

    respond_to do |format|
      format.xml  { render :xml  => @user }
      format.json { render :json => @user }
      format.html do
        flash[:notice] = _("User %s was successfully updated.") % @user.uid
        redirect_to :action => "index"
      end
    end
  rescue => error
    Rails.logger.error error.message
    problem :error, error.message
  end

  # DELETE /users/:user_id
  # DELETE /users/:user_id.xml
  # DELETE /users/:user_id.json
  def destroy
    authorize! :userdelete, User
    @user = User.find(params[:id])
    if @user
      @user.destroy
      respond_to do |format|
        format.xml  { render :xml  => @user }
        format.json { render :json => @user }
        format.html do
          flash[:notice] = _("User %s was successfully removed.") % @user.uid
          redirect_to :action=>:index, :controller=>:users
        end
      end
    else
      problem :not_found, _("User '#{params[:id]}' not found")
    end
  rescue => e
    Rails.logger.error e.message
    problem :error, _("Error: Could not remove user '#{params[:id]}")
  end

  private

  def problem type, message
    case type
    when :error
      code   = 500
      status = "Application error"
    when :not_found
      code   = 404
      status = "Not found"
    end

    respond_to do |format|
      format.xml  { render ErrorResult.error(code, status, message) }
      format.json { render ErrorResult.error(code, status, message) }
      format.html do
        flash[:error] = message
        redirect_to :action => "index"
      end
    end
  end
end

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
require 'firewall'

class FirewallController < ApplicationController
  before_filter :login_required
  
  CGI_PREFIX="firewall"
  layout 'main'
  
  NEEDED_SERVICES=["service:webyast","service:webyast-ui"]
  
  private

  def checkbox_true?(name)
    params[name] == "true"
  end

  def service_to_js(service)
    return ("{ input_name: '"+service.input_name+
            "', name: '"+service.name+
            "', allowed: " + (service.allowed ? "true" : "false") + "}")
  end
 
  public 
    def index
      yapi_perm_check "firewall.read"
      @firewall = Firewall.find

      
      #Rails.logger.error @firewall.use_firewall.inspect
      @firewall.fw_services.each do |service|
        service["css_class"] = CGI_PREFIX+"-"+service["id"].gsub(/^service:/,"service-")
        service["name"] = service["id"].gsub(/^service:/,"")
        service["input_name"] = CGI_PREFIX+"_"+service["id"]
      end
      
      @firewall.fw_services.sort! {|x,y| x["name"] <=> y["name"]}
      #@permissions = Firewall.permissions
      permissions = Permission.find("org.opensuse.yast.modules.yapi.firewall", {:user_id => session[:user]})
      Rails.logger.error "*** PERMISSIONS #{permissions.inspect}"
      @permissions = true #{:read => true, :write => false}
      
      needed_services = @firewall.fw_services.find_all{|s| NEEDED_SERVICES.include? s.object_id}
      @needed_services_js = "["+needed_services.collect{|s| service_to_js s}.join(",")+"]"
      
      respond_to do |format|
        format.html
        format.xml { render  :xml => @firewall.to_xml( :dasherize => false ) }
        format.json { render :json => @firewall.to_json( :dasherize => false ) }
      end
    end
    

    def show
      yapi_perm_check "firewall.read"
      firewall = Firewall.find

      respond_to do |format|
        format.xml { render  :xml => firewall.to_xml( :dasherize => false ) }
        format.html { render  :xml => firewall.to_xml( :dasherize => false ) }
        format.json { render :json => firewall.to_json( :dasherize => false ) }
      end
    end

#    def update
#      root = params["firewall"]
#      if root == nil || root == {}
#        raise InvalidParameters.new :firewall => "Missing"
#      end

#      firewall = Firewall.new(root)
#      yapi_perm_check "firewall.write"
#      firewall.save

#      show
#    end
    
    def update
      firewall = Firewall.find 
      
      if request.format.html?
        Rails.logger.error "HTML"
      
        firewall.use_firewall = checkbox_true? "use_firewall"

        firewall.fw_services.each do |service|
          service["allowed"] = checkbox_true?(CGI_PREFIX+"_" + service["id"])
        end
      
        flash[:notice] = _('Firewall settings have been written.')
        redirect_to :controller => "controlpanel"
        
        firewall.save
      else     
        root = params["firewall"]
        if root == nil || root == {}
          raise InvalidParameters.new :firewall => "Missing"
        end

        firewall = Firewall.new(root)
        yapi_perm_check "firewall.write"
        firewall.save

        show
      end

        
      #redirect_success
    end

    # See update
    def create
      update
    end
end

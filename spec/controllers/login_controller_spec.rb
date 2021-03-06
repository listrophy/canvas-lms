#
# Copyright (C) 2011 - 2015 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require_relative '../spec_helper'

describe LoginController do
  describe "#new" do
    it "redirects to dashboard if already logged in" do
      user_session(user_with_pseudonym(active: true))
      get 'new'
      expect(response).to redirect_to(dashboard_url)
    end

    it "should set merge params correctly in the session" do
      user_with_pseudonym(active: true)
      @cc = @user.communication_channels.create!(:path => 'jt+1@instructure.com')
      get 'new', :confirm => @cc.confirmation_code, :expected_user_id => @user.id
      expect(response).to be_redirect
      expect(session[:confirm]).to eq @cc.confirmation_code
      expect(session[:expected_user_id]).to eq @user.id
    end

    it "respects auth_discovery_url" do
      Account.default.auth_discovery_url = 'https://google.com/'
      Account.default.save!

      get 'new'
      expect(response).to redirect_to('https://google.com/')
    end

    it "handles legacy canvas_login=1 param" do
      account_with_cas(account: Account.default)

      get 'new', canvas_login: '1'
      expect(response).to redirect_to(canvas_login_url)
    end

    it "handles legacy SAML AAC-specific :id" do
      # it should ignore an auth_discovery_url
      Account.default.auth_discovery_url = 'https://google.com/'
      Account.default.save!

      account_with_saml(account: Account.default)
      aac = Account.default.account_authorization_configs.first
      get 'new', id: aac
      expect(response).to redirect_to(saml_login_url(aac))
    end

    it "redirects to Canvas auth by default" do
      get 'new'
      expect(response).to redirect_to(canvas_login_url)
    end

    it "redirects to CAS if it's the default" do
      account_with_cas(account: Account.default)

      get 'new'
      expect(response).to redirect_to(controller.url_for(controller: 'login/cas', action: :new))
    end
  end

  describe "#logout" do
    it "doesn't logout if the authenticity token is invalid" do
      enable_forgery_protection do
        delete 'destroy'
        # it could be a 422, or 0 if error handling isn't enabled properly in specs
        expect(response).to_not be_success
        expect(response).to_not be_redirect
      end
    end

    it "logs out" do
      delete 'destroy'
      expect(response).to redirect_to(login_url)
    end

    it "follows SAML logout redirect to IdP" do
      account_with_saml(account: Account.default, saml_log_out_url: 'https://www.google.com/')
      session[:login_aac] = Account.default.account_authorization_configs.last
      delete 'destroy'
      expect(response.status).to eq 302
      expect(response.location).to match(%r{^https://www.google.com/\?SAMLRequest=})
    end

    it "follows CAS logout redirect to CAS server" do
      account_with_cas(account: Account.default)
      session[:login_aac] = Account.default.account_authorization_configs.last
      delete 'destroy'
      expect(response.status).to eq 302
      expect(response.location).to match(%r{localhost/cas/})
    end
  end

  describe "#logout_confirm" do
    it "redirects to /login if not logged in" do
      get 'logout_confirm'
      expect(response).to redirect_to(login_url)
    end

    it "renders if you are logged in" do
      user_session(user)
      get 'logout_confirm'
      expect(response).to be_success
    end
  end
end

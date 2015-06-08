#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

class Login::OauthBaseController < ApplicationController
  include Login::Shared

  before_filter :forbid_on_files_domain
  before_filter :run_login_hooks, :check_sa_delegated_cookie, only: :new

  def new
    auth_type = params[:controller].sub(%r{^login/}, '')
    # ActionController::TestCase can't deal with aliased controllers, so we have to
    # explicitly specify this
    auth_type = params[:auth_type] if Rails.env.test?
    scope = @domain_root_account.authentication_providers.active.where(auth_type: auth_type)
    if params[:id]
      @aac = scope.find(params[:id])
    else
      @aac = scope.first!
    end

    reset_session_for_login
  end

  protected

  def timeout_protection
    default_timeout = Setting.get('oauth_timelimit', 10.seconds.to_s).to_f

    timeout_options = { raise_on_timeout: true, fallback_timeout_length: default_timeout }

    Canvas.timeout_protection("oauth:#{@aac.global_id}", timeout_options) do
      yield
      true
    end
  rescue => e
    Canvas::Errors.capture(e,
                           type: :oauth_consumer,
                           aac_id: @aac.global_id,
                           account_id: @aac.global_account_id)
    flash[:delegated_message] = t("There was a problem logging in at %{institution}",
                                  institution: @domain_root_account.display_name)
    redirect_to login_url
    false
  end

  def find_pseudonym(unique_ids)
    pseudonym = nil
    unique_ids = Array(unique_ids)
    unique_ids.any? do |unique_id|
      pseudonym = @domain_root_account.pseudonyms.for_auth_configuration(unique_id, @aac)
    end
    if pseudonym
      # Successful login and we have a user
      @domain_root_account.pseudonym_sessions.create!(pseudonym, false)
      session[:login_aac] = @aac.global_id

      successful_login(pseudonym.user, pseudonym)
    else
      unknown_user_url = @domain_root_account.unknown_user_url.presence || login_url
      logger.warn "Received OAuth2 login for unknown user: #{unique_ids.inspect}, redirecting to: #{unknown_user_url}."
      flash[:delegated_message] = t "Canvas doesn't have an account for user: %{user}", :user => unique_ids.first
      redirect_to unknown_user_url
    end
  end
end
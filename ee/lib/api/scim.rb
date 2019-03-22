# frozen_string_literal: true

module API
  class Scim < Grape::API
    prefix 'api/scim'
    version 'v2'
    content_type :json, 'application/scim+json'

    namespace 'groups/:group' do
      params do
        requires :group, type: String
      end

      helpers do
        def logger
          API.logger
        end

        def destroy_identity(identity)
          GroupSaml::Identity::DestroyService.new(identity).execute(transactional: true)

          true
        rescue => e
          logger.error(e.message)

          false
        end

        def scim_not_found!(message:)
          error!({ with: EE::Gitlab::Scim::NotFound }.merge(detail: message), 404)
        end

        def scim_error!(message:)
          error!({ with: EE::Gitlab::Scim::Error }.merge(detail: message), 409)
        end

        def find_and_authenticate_group!(group_path)
          group = find_group(group_path)

          scim_not_found!(message: "Group #{group_path} not found") unless group

          token = Doorkeeper::OAuth::Token.from_request(current_request, *Doorkeeper.configuration.access_token_methods)
          unauthorized! unless token

          scim_token = ScimOauthAccessToken.token_matches_for_group?(token, group)
          unauthorized! unless scim_token

          group
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def update_scim_user(identity)
          parser = EE::Gitlab::Scim::ParamsParser.new(params)
          parsed_hash = parser.to_hash

          if parser.deprovision_user?
            destroy_identity(identity)
          elsif parsed_hash[:extern_uid]
            identity.update(parsed_hash.slice(:extern_uid))
          else
            scim_error!(message: 'Email has already been taken') if email_taken?(parsed_hash[:email], identity)

            result = ::Users::UpdateService.new(identity.user,
                                                parsed_hash.except(:extern_uid, :provider)
                                                  .merge(user: identity.user)).execute

            result[:status] == :success
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        # rubocop: disable CodeReuse/ActiveRecord
        def email_taken?(email, identity)
          return unless email

          User.by_any_email(email.downcase).where.not(id: identity.user.id).exists?
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end

      resource :Users do
        before do
          check_group_scim_enabled(find_group(params[:group]))
          check_group_saml_configured
        end

        desc 'Get SAML users' do
          detail 'This feature was introduced in GitLab 11.10.'
        end
        get do
          group = find_and_authenticate_group!(params[:group])

          scim_error!(message: 'Missing filter params') unless params[:filter]

          parsed_hash = EE::Gitlab::Scim::ParamsParser.new(params).to_hash
          identity = GroupSamlIdentityFinder.find_by_group_and_uid(group: group, uid: parsed_hash[:extern_uid])

          status 200

          present identity || {}, with: ::EE::Gitlab::Scim::Users
        end

        desc 'Get a SAML user' do
          detail 'This feature was introduced in GitLab 11.10.'
        end
        get ':id' do
          group = find_and_authenticate_group!(params[:group])

          identity = GroupSamlIdentityFinder.find_by_group_and_uid(group: group, uid: params[:id])

          scim_not_found!(message: "Resource #{params[:id]} not found") unless identity

          status 200

          present identity, with: ::EE::Gitlab::Scim::User
        end
        desc 'Updates a SAML user' do
          detail 'This feature was introduced in GitLab 11.10.'
        end
        patch ':id' do
          scim_error!(message: 'Missing ID') unless params[:id]

          group = find_and_authenticate_group!(params[:group])
          identity = GroupSamlIdentityFinder.find_by_group_and_uid(group: group, uid: params[:id])

          scim_not_found!(message: "Resource #{params[:id]} not found") unless identity

          updated = update_scim_user(identity)

          if updated
            status 204

            {}
          else
            scim_error!(message: "Error updating #{identity.user.name} with #{params.inspect}")
          end
        end

        desc 'Removes a SAML user' do
          detail 'This feature was introduced in GitLab 11.10.'
        end
        delete ":id" do
          scim_error!(message: 'Missing ID') unless params[:id]

          group = find_and_authenticate_group!(params[:group])
          identity = GroupSamlIdentityFinder.find_by_group_and_uid(group: group, uid: params[:id])

          scim_not_found!(message: "Resource #{params[:id]} not found") unless identity

          scim_not_found!(message: "Resource #{params[:id]} not found") unless destroy_identity(identity)

          status 204

          {}
        end
      end
    end
  end
end

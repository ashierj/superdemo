# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registrations::WelcomeController, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project) }

  let(:onboarding_enabled?) { true }

  before do
    stub_saas_features(onboarding: onboarding_enabled?)
  end

  describe '#show' do
    let(:show_params) { {} }

    subject(:get_show) { get :show, params: show_params }

    context 'without a signed in user' do
      it { is_expected.to redirect_to new_user_registration_path }
    end

    context 'with signed in user' do
      before do
        sign_in(user)
      end

      it { is_expected.to render_template(:show) }

      context 'for signup_intent_step_one experiment' do
        let(:experiment) { instance_double(ApplicationExperiment) }

        it 'tracks experiment events' do
          allow(controller)
            .to receive(:experiment)
                  .with(:signup_intent_step_one, actor: user)
                  .and_return(experiment)

          expect(experiment).to receive(:run)
          expect(experiment).to receive(:track).with(:show, label: :welcome)

          get_show
        end
      end

      it 'tracks render event' do
        get_show

        expect_snowplow_event(
          category: 'registrations:welcome:show',
          action: 'render',
          user: user,
          label: 'free_registration'
        )
      end

      context 'when onboarding feature is not available' do
        let(:onboarding_enabled?) { false }

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      context 'when in invitation flow' do
        before do
          create(:group_member, source: group, user: user)
        end

        it 'tracks render event' do
          get_show

          expect_snowplow_event(
            category: 'registrations:welcome:show',
            action: 'render',
            user: user,
            label: 'invite_registration'
          )
        end
      end

      context 'when in trial flow' do
        let(:show_params) { { trial: 'true' } }

        it 'tracks render event' do
          get_show

          expect_snowplow_event(
            category: 'registrations:welcome:show',
            action: 'render',
            user: user,
            label: 'trial_registration'
          )
        end
      end

      context 'when completed welcome step' do
        context 'when setup_for_company is set to true' do
          let_it_be(:user) { create(:user, setup_for_company: true) }

          it 'does not track render event' do
            get_show

            expect_no_snowplow_event(
              category: 'registrations:welcome:show',
              action: 'render',
              user: user,
              label: 'free_registration'
            )
          end
        end

        context 'when setup_for_company is set to false' do
          before do
            user.update!(setup_for_company: false)
            sign_in(user)
          end

          it { is_expected.to redirect_to(dashboard_projects_path) }
        end
      end

      context 'when 2FA is required from group' do
        before do
          user = create(:user, onboarding_in_progress: true, require_two_factor_authentication_from_group: true)
          sign_in(user)
        end

        it 'does not perform a redirect' do
          expect(subject).not_to redirect_to(profile_two_factor_auth_path)
        end
      end

      context 'when welcome step is completed' do
        before do
          user.update!(setup_for_company: true)
        end

        context 'when user is confirmed' do
          before do
            sign_in(user)
          end

          it { is_expected.to render_template(:show) }
        end

        context 'when user is not confirmed' do
          before do
            stub_application_setting_enum('email_confirmation_setting', 'hard')

            sign_in(user)

            user.update!(confirmed_at: nil)
          end

          it { is_expected.to redirect_to user_session_path }
        end
      end

      render_views

      it 'has the expected submission url' do
        get_show

        expect(response.body).to include("action=\"#{users_sign_up_welcome_path}\"")
      end
    end
  end

  describe '#update' do
    let(:setup_for_company) { 'false' }
    let(:joining_project) { 'false' }
    let(:extra_params) { {} }
    let(:extra_user_params) { {} }
    let(:update_params) do
      {
        user: {
          role: 'software_developer',
          setup_for_company: setup_for_company,
          registration_objective: 'code_storage'
        }.merge(extra_user_params),
        joining_project: joining_project,
        jobs_to_be_done_other: '_jobs_to_be_done_other_',
        glm_source: 'some_source',
        glm_content: 'some_content'
      }.merge(extra_params)
    end

    subject(:patch_update) { patch :update, params: update_params }

    context 'without a signed in user' do
      it { is_expected.to redirect_to new_user_registration_path }
    end

    context 'with a signed in user' do
      before do
        sign_in(user)
      end

      context 'when onboarding feature is not available' do
        let(:onboarding_enabled?) { false }

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      context 'with email updates' do
        context 'when registration_objective field is provided' do
          it 'sets the registration_objective' do
            patch_update

            expect(controller.current_user.registration_objective).to eq('code_storage')
          end
        end
      end

      describe 'redirection' do
        context 'when onboarding is not enabled' do
          before do
            allow_next_instance_of(Onboarding::Status) do |instance|
              allow(instance).to receive(:enabled?).and_return(false)
            end
          end

          it { is_expected.to redirect_to dashboard_projects_path }

          it 'tracks successful submission event' do
            patch_update

            expect_snowplow_event(
              category: 'registrations:welcome:update',
              action: 'successfully_submitted_form',
              user: user,
              label: 'free_registration'
            )
          end

          context 'with joining_project selection' do
            context 'when creating a new project' do
              it 'does not track join a project event' do
                patch_update

                expect_no_snowplow_event(
                  category: 'registrations:welcome:update',
                  action: 'select_button',
                  user: user,
                  label: 'join_a_project'
                )
              end
            end

            context 'when joining a project' do
              let(:joining_project) { 'true' }

              it 'tracks join a project event' do
                patch_update

                expect_snowplow_event(
                  category: 'registrations:welcome:update',
                  action: 'select_button',
                  user: user,
                  label: 'join_a_project'
                )
              end
            end
          end

          context 'when the new user already has any accepted group membership' do
            let!(:member1) { create(:group_member, user: user) }

            it 'redirects to the group page' do
              expect(patch_update).to redirect_to(group_path(member1.source))
            end

            context 'when the new user already has more than 1 accepted group membership' do
              it 'redirects to the most recent membership group page' do
                member2 = create(:group_member, user: user)

                expect(patch_update).to redirect_to(group_path(member2.source))
              end
            end

            context 'when the member has an orphaned source at the time of the welcome' do
              it 'redirects to the project dashboard page' do
                member1.source.delete

                expect(patch_update).to redirect_to(dashboard_projects_path)
              end
            end
          end
        end

        context 'when onboarding is enabled' do
          let_it_be(:user) do
            create(:user, onboarding_in_progress: true) do |record|
              create(:user_detail, user: record, onboarding_status_step_url: '_url_')
            end
          end

          context 'when the new user already has any accepted group membership' do
            let!(:member1) { create(:group_member, user: user) }

            context 'when the member has an orphaned source at the time of the welcome' do
              it 'redirects to the project non invite onboarding flow' do
                member1.source.delete

                expect(patch_update).to redirect_to(new_users_sign_up_group_path)
              end
            end
          end

          context 'when joining_project is "true"' do
            let(:joining_project) { 'true' }

            specify do
              patch_update
              user.reload

              expect(user.onboarding_in_progress).to be(false)
              expect(response).to redirect_to dashboard_projects_path
            end
          end

          context 'when joining_project is "false"' do
            context 'with group and project creation' do
              specify do
                patch_update
                user.reload
                path = new_users_sign_up_group_path

                expect(user.onboarding_in_progress).to be(true)
                expect(response).to redirect_to path
              end
            end
          end

          context 'when eligible for iterable trigger' do
            before do
              allow_next_instance_of(::Onboarding::Status) do |instance|
                allow(instance).to receive(:eligible_for_iterable_trigger?).and_return(true)
              end
            end

            it 'initiates iterable trigger creation' do
              expect(::Onboarding::CreateIterableTriggerWorker).to receive(:perform_async)

              patch_update
            end
          end

          context 'when not eligible for iterable trigger' do
            before do
              allow_next_instance_of(::Onboarding::Status) do |instance|
                allow(instance).to receive(:eligible_for_iterable_trigger?).and_return(false)
              end
            end

            it 'does not initiate iterable trigger creation' do
              expect(::Onboarding::CreateIterableTriggerWorker).not_to receive(:perform_async)

              patch_update
            end
          end

          context 'for email opt_in' do
            using RSpec::Parameterized::TableSyntax

            let(:invite?) { true }
            let(:setup_for_company?) { false }

            before do
              allow_next_instance_of(::Onboarding::Status) do |instance|
                allow(instance).to receive(:invite?).and_return(invite?)
                allow(instance).to receive(:setup_for_company?).and_return(setup_for_company?)
              end
            end

            where(:extra_user_params, :opt_in) do
              { onboarding_status_email_opt_in: 'true' }  | true
              { onboarding_status_email_opt_in: 'false' } | false
              { onboarding_status_email_opt_in: nil }     | false
              { onboarding_status_email_opt_in: '1' }     | true
              { onboarding_status_email_opt_in: '0' }     | false
              { onboarding_status_email_opt_in: '' }      | false
              {}                                          | false
            end

            with_them do
              context 'for an invite' do
                specify do
                  patch_update
                  user.reload

                  expect(user.onboarding_status_email_opt_in).to eq(false)
                end
              end

              context 'for a non-invite' do
                let(:invite?) { false }

                context 'when setup_for_company is true' do
                  let(:setup_for_company?) { true }

                  specify do
                    patch_update
                    user.reload

                    expect(user.onboarding_status_email_opt_in).to eq(true)
                  end
                end

                context 'when setup_for_company is false' do
                  specify do
                    patch_update
                    user.reload

                    expect(user.onboarding_status_email_opt_in).to eq(opt_in)
                  end
                end
              end
            end
          end

          context 'when setup_for_company is "true"' do
            let(:setup_for_company) { 'true' }
            let(:trial_concerns) { {} }
            let(:redirect_path) { new_users_sign_up_company_path(expected_params) }
            let(:expected_params) do
              {
                registration_objective: 'code_storage',
                role: 'software_developer',
                jobs_to_be_done_other: '_jobs_to_be_done_other_',
                glm_source: 'some_source',
                glm_content: 'some_content'
              }.merge(trial_concerns)
            end

            it 'redirects to the company path and stores the url' do
              patch_update
              user.reload

              expect(user.onboarding_in_progress).to be(true)
              expect(user.onboarding_status_step_url).to eq(redirect_path)
              expect(user.onboarding_status_email_opt_in).to eq(true)
              expect(user.onboarding_status_registration_type).to eq(::Onboarding::Status::REGISTRATION_TYPE[:trial])
              expect(response).to redirect_to redirect_path
            end

            context 'with trial param sent with update' do
              let(:trial_concerns) { extra_params }

              before do
                patch_update
              end

              context 'with trial as true' do
                let(:extra_params) { { trial: 'true' } }

                it 'redirects to the company path with trial param' do
                  expect(response).to redirect_to redirect_path
                end
              end

              context 'with trial as not true' do
                let(:extra_params) { { trial: 'false' } }

                it 'does not include the trial param in the redirect path' do
                  expect(response).to redirect_to redirect_path
                end
              end
            end

            context 'when user is an invite flow eligible registration' do
              before do
                create(:group_member, source: group, user: user)
              end

              it 'does not convert to a trial' do
                patch_update
                user.reload

                expect(user.onboarding_status_registration_type)
                  .not_to eq(::Onboarding::Status::REGISTRATION_TYPE[:invite])
              end
            end
          end

          context 'when setup_for_company is "false"' do
            let(:setup_for_company) { 'false' }

            specify do
              patch_update
              user.reload
              path = new_users_sign_up_group_path

              expect(user.onboarding_in_progress).to be(true)
              expect(user.onboarding_status_step_url).to eq(path)
              expect(user.onboarding_status_registration_type)
                .not_to eq(::Onboarding::Status::REGISTRATION_TYPE[:trial])
              expect(response).to redirect_to path
            end

            context 'when trial is true' do
              using RSpec::Parameterized::TableSyntax

              let(:extra_params) { { trial: 'true' } }

              where(:extra_user_params, :opt_in) do
                { onboarding_status_email_opt_in: 'true' }  | true
                { onboarding_status_email_opt_in: 'false' } | false
                { onboarding_status_email_opt_in: nil }     | false
                { onboarding_status_email_opt_in: '1' }     | true
                { onboarding_status_email_opt_in: '0' }     | false
                { onboarding_status_email_opt_in: '' }      | false
                {}                                          | false
              end

              with_them do
                specify do
                  expected_params = {
                    registration_objective: 'code_storage',
                    role: 'software_developer',
                    jobs_to_be_done_other: '_jobs_to_be_done_other_',
                    glm_source: 'some_source',
                    glm_content: 'some_content',
                    trial: 'true'
                  }

                  patch_update
                  user.reload
                  path = new_users_sign_up_company_path(expected_params)

                  expect(user.onboarding_in_progress).to be(true)
                  expect(user.onboarding_status_step_url).to eq(path)
                  expect(user.onboarding_status_email_opt_in).to eq(opt_in)
                  expect(response).to redirect_to path
                end
              end
            end

            context 'when trial is false' do
              let(:extra_params) { { trial: 'false' } }
              let(:expected_params) do
                {
                  registration_objective: 'code_storage',
                  role: 'software_developer',
                  jobs_to_be_done_other: '_jobs_to_be_done_other_',
                  glm_source: 'some_source',
                  glm_content: 'some_content',
                  trial: 'false'
                }
              end

              specify do
                patch_update
                user.reload
                path = new_users_sign_up_group_path

                expect(user.onboarding_in_progress).to be(true)
                expect(user.onboarding_status_step_url).to eq(path)
                expect(response).to redirect_to path
              end
            end
          end

          context 'when in subscription flow' do
            subject { patch :update, params: update_params, session: { user_return_to: new_subscriptions_path } }

            it { is_expected.not_to redirect_to new_users_sign_up_group_path }
          end

          context 'when in invitation flow' do
            before do
              create(:group_member, source: group, user: user)
            end

            it { is_expected.not_to redirect_to new_users_sign_up_group_path }

            it 'tracks successful submission event' do
              patch_update

              expect_snowplow_event(
                category: 'registrations:welcome:update',
                action: 'successfully_submitted_form',
                user: user,
                label: 'invite_registration'
              )
            end
          end

          context 'when in trial flow' do
            let(:extra_params) { { trial: 'true' } }

            it { is_expected.not_to redirect_to new_users_sign_up_group_path }

            it 'tracks successful submission event' do
              patch_update

              expect_snowplow_event(
                category: 'registrations:welcome:update',
                action: 'successfully_submitted_form',
                user: user,
                label: 'trial_registration'
              )
            end

            context 'when stored company path' do
              let(:stored_path) { new_users_sign_up_company_path }

              before do
                controller.store_location_for(:user, stored_path)
              end

              specify do
                patch_update
                user.reload

                path = ::Gitlab::Utils.add_url_parameters(
                  stored_path, {
                    glm_content: 'some_content',
                    glm_source: 'some_source',
                    jobs_to_be_done_other: '_jobs_to_be_done_other_',
                    registration_objective: 'code_storage',
                    role: 'software_developer'
                  }.merge(extra_params)
                )

                expect(user.onboarding_in_progress).to be(true)
                expect(user.onboarding_status_step_url).to eq(path)
                expect(response).to redirect_to path
              end
            end
          end
        end

        context 'when failed request' do
          subject(:patch_update) do
            patch :update, params: { user: { role: 'software_developer' }, joining_project: 'true' }
          end

          before do
            allow_next_instance_of(::Users::SignupService) do |service|
              allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'failed'))
            end
          end

          it 'does not track submission event' do
            patch_update

            expect_no_snowplow_event(
              category: 'registrations:welcome:update',
              action: 'successfully_submitted_form',
              user: user,
              label: 'free_registration'
            )
          end

          it 'does not track join a project event' do
            patch_update

            expect_no_snowplow_event(
              category: 'registrations:welcome:update',
              action: 'select_button',
              user: user,
              label: 'join_a_project'
            )
          end
        end
      end
    end
  end
end

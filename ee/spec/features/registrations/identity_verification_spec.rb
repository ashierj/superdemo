# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Identity Verification', :js, feature_category: :instance_resiliency do
  include IdentityVerificationHelpers
  include ListboxHelpers

  before do
    stub_application_setting_enum('email_confirmation_setting', 'hard')
    stub_application_setting(
      require_admin_approval_after_user_signup: false,
      arkose_labs_public_api_key: 'public_key',
      arkose_labs_private_api_key: 'private_key',
      telesign_customer_xid: 'customer_id',
      telesign_api_key: 'private_key'
    )

    stub_request(:get, "https://status.arkoselabs.com/api/v2/status.json")
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent' => 'Ruby'
        })
      .to_return(
        status: 200,
        body: '{ "status": { "indicator": "none" }}',
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  let(:user_email) { 'onboardinguser@example.com' }
  let(:new_user) { build(:user, email: user_email) }
  let(:user) { User.find_by_email(user_email) }

  shared_examples 'does not allow unauthorized access to verification endpoints' do |protected_endpoints|
    # Normally, users cannot trigger requests to endpoints of verification
    # methods in later steps by only using the UI (e.g. if the current step is
    # email verification. Phone and credit card steps cannot be interacted
    # with). However, there is nothing stopping users from manually or
    # programatically sending requests to these endpoints.
    #
    # This spec ensures that only the endpoints of the verification method in
    # the current step are accessible to the user regardless of the way the
    # request is sent.
    #
    # Note: SAML flow is skipped as the signin process is more involved which
    # makes the test unnecessarily complex.

    def send_request(session, method, path, headers:)
      session.public_send(method, path, headers: headers, xhr: true, as: :json)
    end

    it do
      session = ActionDispatch::Integration::Session.new(Rails.application)

      # sign in
      session.post user_session_path, params: { user: { login: new_user.username, password: new_user.password } }

      # visit identity verification page
      session.get identity_verification_path

      # extract CSRF token
      body = session.response.body
      html = Nokogiri::HTML.parse(body)
      csrf_token = html.at("meta[name=csrf-token]")['content']

      headers = { 'X-CSRF-Token' => csrf_token }

      phone_send_code_path = send_phone_verification_code_identity_verification_path
      phone_verify_code_path = verify_phone_verification_code_identity_verification_path
      credit_card_verify_path = verify_credit_card_identity_verification_path

      verification_endpoint_requests = {
        phone: [
          -> { send_request(session, :post, phone_send_code_path, headers: headers) },
          -> { send_request(session, :post, phone_verify_code_path, headers: headers) }
        ],
        credit_card: [
          -> { send_request(session, :get, credit_card_verify_path, headers: {}) }
        ]
      }

      protected_endpoints.each do |e|
        verification_endpoint_requests[e].each do |request_lambda|
          expect(request_lambda.call).to eq 400
        end
      end
    end
  end

  shared_examples 'registering a low risk user with identity verification' do |flow: :others|
    let(:risk) { :low }

    it 'verifies the user' do
      expect_to_see_identity_verification_page

      verify_email

      expect_verification_completed

      expect_to_see_dashboard_page
    end

    context 'when the verification code is empty' do
      it 'shows error message' do
        verify_code('')

        expect(page).to have_content(s_('IdentityVerification|Enter a code.'))
      end
    end

    context 'when the verification code is invalid' do
      it 'shows error message' do
        verify_code('xxx')

        expect(page).to have_content(s_('IdentityVerification|Enter a valid code.'))
      end
    end

    context 'when the verification code has expired' do
      before do
        travel (Users::EmailVerification::ValidateTokenService::TOKEN_VALID_FOR_MINUTES + 1).minutes
      end

      it 'shows error message' do
        verify_code(email_verification_code)

        expect(page).to have_content(s_('IdentityVerification|The code has expired. Send a new code and try again.'))
      end
    end

    context 'when the verification code is incorrect' do
      it 'shows error message' do
        verify_code('000000')

        expect(page).to have_content(
          s_('IdentityVerification|The code is incorrect. Enter it again, or send a new code.')
        )
      end
    end

    context 'when user requests a new code' do
      it 'resends a new code' do
        click_link 'Send a new code'

        expect(page).to have_content(s_('IdentityVerification|A new code has been sent.'))
      end
    end

    unless flow == :saml
      describe 'access to verification endpoints' do
        it_behaves_like 'does not allow unauthorized access to verification endpoints', [:phone, :credit_card]
      end
    end
  end

  shared_examples 'registering a medium risk user with identity verification' do
    |skip_email_validation: false, flow: :others|

    let(:risk) { :medium }

    it 'verifies the user' do
      expect_to_see_identity_verification_page

      verify_email unless skip_email_validation

      verify_phone_number

      expect_verification_completed

      expect_to_see_dashboard_page
    end

    context 'when the user requests a phone verification exemption' do
      it 'verifies the user' do
        expect_to_see_identity_verification_page

        verify_email unless skip_email_validation

        request_phone_exemption

        verify_credit_card

        # verify_credit_card creates a credit_card verification record &
        # refreshes the page. This causes an automatic redirect to the welcome
        # page, skipping the verification successful badge, and preventing us
        # from calling expect_verification_completed

        expect_to_see_dashboard_page
      end
    end

    unless flow == :saml
      describe 'access to verification endpoints' do
        it_behaves_like 'does not allow unauthorized access to verification endpoints', [:credit_card]

        context 'when all prerequisite verification methods have not been completed' do
          unless skip_email_validation
            it_behaves_like 'does not allow unauthorized access to verification endpoints', [:phone]
          end
        end
      end
    end
  end

  shared_examples 'registering a high risk user with identity verification' do
    |skip_email_validation: false, flow: :others|

    let(:risk) { :high }

    it 'verifies the user' do
      expect_to_see_identity_verification_page

      verify_email unless skip_email_validation

      verify_phone_number

      verify_credit_card

      expect_to_see_dashboard_page
    end

    context 'and the user has a phone verification exemption' do
      it 'verifies the user' do
        user.create_phone_number_exemption!

        expect_to_see_identity_verification_page

        verify_email unless skip_email_validation

        verify_credit_card

        # verify_credit_card creates a credit_card verification record &
        # refreshes the page. This causes an automatic redirect to the welcome
        # page, skipping the verification successful badge, and preventing us
        # from calling expect_verification_completed

        expect_to_see_dashboard_page
      end
    end

    unless flow == :saml
      describe 'access to verification endpoints' do
        context 'when all prerequisite verification methods have been completed' do
          before do
            verify_email unless skip_email_validation
            verify_phone_number
          end

          it_behaves_like 'does not allow unauthorized access to verification endpoints', [:phone]
        end

        context 'when some prerequisite verification methods have not been completed' do
          before do
            verify_email unless skip_email_validation
          end

          it_behaves_like 'does not allow unauthorized access to verification endpoints', [:credit_card]
        end

        context 'when all prerequisite verification methods have not been completed' do
          it_behaves_like 'does not allow unauthorized access to verification endpoints', [:credit_card]
        end
      end
    end
  end

  describe 'Standard flow' do
    before do
      visit new_user_registration_path
      sign_up
    end

    it_behaves_like 'registering a low risk user with identity verification'
    it_behaves_like 'registering a medium risk user with identity verification'
    it_behaves_like 'registering a high risk user with identity verification'
  end

  describe 'Invite flow' do
    let(:invitation) { create(:group_member, :invited, :developer, invite_email: user_email) }

    before do
      visit invite_path(invitation.raw_invite_token, invite_type: Emails::Members::INITIAL_INVITE)
      sign_up(invite: true)
    end

    context 'when the user is low risk' do
      let(:risk) { :low }

      it 'does not verify the user and lands on group page' do
        expect(page).to have_current_path(group_path(invitation.group))
        expect(page).to have_content("You have been granted Developer access to group #{invitation.group.name}.")
      end
    end

    it_behaves_like 'registering a medium risk user with identity verification', skip_email_validation: true
    it_behaves_like 'registering a high risk user with identity verification', skip_email_validation: true
  end

  describe 'Trial flow', :saas do
    before do
      visit new_trial_registration_path
      trial_sign_up
    end

    it_behaves_like 'registering a low risk user with identity verification'
    it_behaves_like 'registering a medium risk user with identity verification'
    it_behaves_like 'registering a high risk user with identity verification'
  end

  describe 'SAML flow' do
    let(:provider) { 'google_oauth2' }

    before do
      mock_auth_hash(provider, 'external_uid', user_email)
      stub_omniauth_setting(block_auto_created_users: false)

      visit new_user_registration_path
      saml_sign_up
    end

    around do |example|
      with_omniauth_full_host { example.run }
    end

    it_behaves_like 'registering a low risk user with identity verification', flow: :saml
    it_behaves_like 'registering a medium risk user with identity verification', flow: :saml
    it_behaves_like 'registering a high risk user with identity verification', flow: :saml
  end

  describe 'Subscription flow', :saas do
    before do
      stub_ee_application_setting(should_check_namespace_plan: true)

      visit new_subscriptions_path
      sign_up
    end

    it_behaves_like 'registering a low risk user with identity verification'
    it_behaves_like 'registering a medium risk user with identity verification'
    it_behaves_like 'registering a high risk user with identity verification'
  end

  describe 'user that already went through identity verification' do
    context 'when the user is medium risk but phone verification feature-flag is turned off' do
      let(:risk) { :medium }

      before do
        stub_feature_flags(identity_verification_phone_number: false)

        visit new_user_registration_path
        sign_up
      end

      it 'verifies the user with email only' do
        expect_to_see_identity_verification_page

        verify_email

        expect_verification_completed

        expect_to_see_dashboard_page

        user_signs_out

        # even though the phone verification feature-flag is turned back on
        # when the user logs in next, they will not be asked to do identity verification again
        stub_feature_flags(identity_verification_phone_number: true)

        gitlab_sign_in(user, password: new_user.password)

        expect_to_see_dashboard_page
      end
    end
  end

  private

  def sign_up(invite: false)
    fill_in_sign_up_form(new_user, invite: invite) { solve_arkose_verify_challenge(risk: risk) }
  end

  def saml_sign_up
    click_button "oauth-login-#{provider}"
    solve_arkose_verify_challenge(saml: true, risk: risk)
  end

  def trial_sign_up
    fill_in_sign_up_form(new_user, 'Continue') { solve_arkose_verify_challenge(risk: risk) }
  end

  def verify_credit_card
    # It's too hard to simulate an actual credit card validation, since it relies on loading an external script,
    # rendering external content in an iframe and several API calls to the subscription portal from the backend.
    # So instead we create a credit_card_validation directly and reload the page here.
    create(:credit_card_validation, user: user)
    visit current_path
  end

  def verify_phone_number
    phone_number = '400000000'
    verification_code = '4319315'
    stub_telesign_verification

    select_from_listbox('🇦🇺 Australia (+61)', from: '🇺🇸 United States of America (+1)')

    fill_in 'phone_number', with: phone_number
    click_button s_('IdentityVerification|Send code')

    expect(page).to have_content(
      format(
        s_("IdentityVerification|We've sent a verification code to +%{phoneNumber}"),
        phoneNumber: '61400000000'
      )
    )

    fill_in 'verification_code', with: verification_code
    click_button s_('IdentityVerification|Verify phone number')
  end

  def expect_to_see_dashboard_page
    expect(page).to have_content(_('Welcome to GitLab'))
  end

  def request_phone_exemption
    click_button s_('IdentityVerification|Verify with a credit card instead?')
  end

  def user_signs_out
    find_by_testid('user-dropdown').click
    click_link 'Sign out'

    expect(page).to have_button(_('Sign in'))
  end
end

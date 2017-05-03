require 'rails_helper'

describe GroupsController do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:empty_project, namespace: group) }
  let!(:group_member) { create(:group_member, group: group, user: user) }

  describe 'GET #index' do
    context 'as a user' do
      it 'redirects to Groups Dashboard' do
        sign_in(user)

        get :index

        expect(response).to redirect_to(dashboard_groups_path)
      end
    end

    context 'as a guest' do
      it 'redirects to Explore Groups' do
        get :index

        expect(response).to redirect_to(explore_groups_path)
      end
    end
  end

  describe 'GET #subgroups' do
    let!(:public_subgroup) { create(:group, :public, parent: group) }
    let!(:private_subgroup) { create(:group, :private, parent: group) }

    context 'as a user' do
      before do
        sign_in(user)
      end

      it 'shows the public subgroups' do
        get :subgroups, id: group.to_param

        expect(assigns(:nested_groups)).to contain_exactly(public_subgroup)
      end

      context 'being member' do
        it 'shows public and private subgroups the user is member of' do
          private_subgroup.add_guest(user)

          get :subgroups, id: group.to_param

          expect(assigns(:nested_groups)).to contain_exactly(public_subgroup, private_subgroup)
        end
      end
    end

    context 'as a guest' do
      it 'shows the public subgroups' do
        get :subgroups, id: group.to_param

        expect(assigns(:nested_groups)).to contain_exactly(public_subgroup)
      end
    end
  end

  describe 'GET #issues' do
    let(:issue_1) { create(:issue, project: project) }
    let(:issue_2) { create(:issue, project: project) }

    before do
      create_list(:award_emoji, 3, awardable: issue_2)
      create_list(:award_emoji, 2, awardable: issue_1)
      create_list(:award_emoji, 2, :downvote, awardable: issue_2,)

      sign_in(user)
    end

    context 'sorting by votes' do
      it 'sorts most popular issues' do
        get :issues, id: group.to_param, sort: 'upvotes_desc'
        expect(assigns(:issues)).to eq [issue_2, issue_1]
      end

      it 'sorts least popular issues' do
        get :issues, id: group.to_param, sort: 'downvotes_desc'
        expect(assigns(:issues)).to eq [issue_2, issue_1]
      end
    end

    context 'when requesting the canonical path with different casing' do
      it 'redirects to the correct casing' do
        get :issues, id: group.to_param.upcase

        expect(response).to redirect_to(issues_group_path(group.to_param))
        expect(controller).not_to set_flash[:notice]
      end
    end

    context 'when requesting a redirected path' do
      let(:redirect_route) { group.redirect_routes.create(path: 'old-path') }

      it 'redirects to the canonical path' do
        get :issues, id: redirect_route.path

        expect(response).to redirect_to(issues_group_path(group.to_param))
        expect(controller).to set_flash[:notice].to(/moved/)
      end
    end
  end

  describe 'GET #merge_requests' do
    let(:merge_request_1) { create(:merge_request, source_project: project) }
    let(:merge_request_2) { create(:merge_request, :simple, source_project: project) }

    before do
      create_list(:award_emoji, 3, awardable: merge_request_2)
      create_list(:award_emoji, 2, awardable: merge_request_1)
      create_list(:award_emoji, 2, :downvote, awardable: merge_request_2)

      sign_in(user)
    end

    context 'sorting by votes' do
      it 'sorts most popular merge requests' do
        get :merge_requests, id: group.to_param, sort: 'upvotes_desc'
        expect(assigns(:merge_requests)).to eq [merge_request_2, merge_request_1]
      end

      it 'sorts least popular merge requests' do
        get :merge_requests, id: group.to_param, sort: 'downvotes_desc'
        expect(assigns(:merge_requests)).to eq [merge_request_2, merge_request_1]
      end
    end

    context 'when requesting the canonical path with different casing' do
      it 'redirects to the correct casing' do
        get :merge_requests, id: group.to_param.upcase

        expect(response).to redirect_to(merge_requests_group_path(group.to_param))
        expect(controller).not_to set_flash[:notice]
      end
    end

    context 'when requesting a redirected path' do
      let(:redirect_route) { group.redirect_routes.create(path: 'old-path') }

      it 'redirects to the canonical path' do
        get :merge_requests, id: redirect_route.path

        expect(response).to redirect_to(merge_requests_group_path(group.to_param))
        expect(controller).to set_flash[:notice].to(/moved/)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'as another user' do
      it 'returns 404' do
        sign_in(create(:user))

        delete :destroy, id: group.to_param

        expect(response.status).to eq(404)
      end
    end

    context 'as the group owner' do
      before do
        sign_in(user)
      end

      it 'schedules a group destroy' do
        Sidekiq::Testing.fake! do
          expect { delete :destroy, id: group.to_param }.to change(GroupDestroyWorker.jobs, :size).by(1)
        end
      end

      it 'redirects to the root path' do
        delete :destroy, id: group.to_param

        expect(response).to redirect_to(root_path)
      end

      context 'when requesting the canonical path with different casing' do
        it 'does not 404' do
          delete :destroy, id: group.to_param.upcase

          expect(response).not_to have_http_status(404)
        end

        it 'does not redirect to the correct casing' do
          delete :destroy, id: group.to_param.upcase

          expect(response).not_to redirect_to(group_path(group.to_param))
        end
      end

      context 'when requesting a redirected path' do
        let(:redirect_route) { group.redirect_routes.create(path: 'old-path') }

        it 'returns not found' do
          delete :destroy, id: redirect_route.path

          expect(response).to have_http_status(404)
        end
      end
    end
  end

  describe 'PUT update' do
    before do
      sign_in(user)
    end

    it 'updates the path successfully' do
      post :update, id: group.to_param, group: { path: 'new_path' }

      expect(response).to have_http_status(302)
      expect(controller).to set_flash[:notice]
    end

    it 'does not update the path on error' do
      allow_any_instance_of(Group).to receive(:move_dir).and_raise(Gitlab::UpdatePathError)
      post :update, id: group.to_param, group: { path: 'new_path' }

      expect(assigns(:group).errors).not_to be_empty
      expect(assigns(:group).path).not_to eq('new_path')
    end

    context 'when requesting the canonical path with different casing' do
      it 'does not 404' do
        post :update, id: group.to_param.upcase, group: { path: 'new_path' }

        expect(response).not_to have_http_status(404)
      end

      it 'does not redirect to the correct casing' do
        post :update, id: group.to_param.upcase, group: { path: 'new_path' }

        expect(response).not_to redirect_to(group_path(group.to_param))
      end
    end

    context 'when requesting a redirected path' do
      let(:redirect_route) { group.redirect_routes.create(path: 'old-path') }

      it 'returns not found' do
        post :update, id: redirect_route.path, group: { path: 'new_path' }

        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'POST create' do
    it 'allows creating a group' do
      sign_in(user)

      expect do
        post :create, group: { name: 'new_group', path: "new_group" }
      end.to change { Group.count }.by(1)

      expect(response).to have_http_status(302)
    end

    context 'authorization' do
      it 'allows an admin to create a group' do
        sign_in(create(:admin))

        expect do
          post :create, group: { name: 'new_group', path: "new_group" }
        end.to change { Group.count }.by(1)

        expect(response).to have_http_status(302)
      end

      it 'does not allow a user with "can_create_group" set to false to create a group' do
        sign_in(create(:user, can_create_group: false))

        expect do
          post :create, group: { name: 'new_group', path: "new_group" }
        end.not_to change { Group.count }

        expect(response).to have_http_status(404)
      end

      it 'allows an auditor with "can_create_group" set to true to create a group' do
        sign_in(create(:user, :auditor, can_create_group: true))

        expect do
          post :create, group: { name: 'new_group', path: "new_group" }
        end.to change { Group.count }.by(1)

        expect(response).to have_http_status(302)
      end
    end
  end
end

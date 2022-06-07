# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project' do
  describe 'Custom instance-level projects templates' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let!(:projects) { create_list(:project, 3, :public, :metrics_dashboard_enabled, namespace: group) }

    before do
      stub_ee_application_setting(custom_project_templates_group_id: group.id)
    end

    describe 'when feature custom_project_templates is enabled' do
      before do
        stub_licensed_features(custom_project_templates: true)
        allow(Project).to receive(:default_per_page).and_return(2)

        sign_in user
        visit new_project_path
      end

      it 'shows built-in templates tab' do
        page.within '.project-template .built-in-tab' do
          expect(page).to have_content 'Built-in'
        end
      end

      it 'shows custom projects templates tab' do
        page.within '.project-template .custom-instance-project-templates-tab' do
          expect(page).to have_content 'Instance'
        end
      end

      it 'displays the number of projects templates available to the user' do
        page.within '.project-template .custom-instance-project-templates-tab span.badge' do
          expect(page).to have_content '3'
        end
      end

      it 'allows creation from custom project template', :js do
        new_path = 'example-custom-project-template'
        new_name = 'Example Custom Project Template'

        create_from_template(:instance, projects.first.name)

        page.within '.project-fields-form' do
          fill_in('project_name', with: new_name)
          # Have to reset it to '' so it overwrites rather than appends
          fill_in('project_path', with: '')
          fill_in('project_path', with: new_path)

          Sidekiq::Testing.inline! do
            click_button 'Create project'
          end
        end

        expect(page).to have_content new_name
        expect(Project.last.name).to eq new_name
        expect(page).to have_current_path "/#{user.username}/#{new_path}"
        expect(Project.last.path).to eq new_path
      end

      it 'allows creation from custom project template using only the name', :js do
        new_path = 'example-custom-project-template'
        new_name = 'Example Custom Project Template'

        create_from_template(:instance, projects.first.name)

        page.within '.project-fields-form' do
          fill_in('project_name', with: new_name)

          Sidekiq::Testing.inline! do
            click_button 'Create project'
          end
        end

        expect(page).to have_content new_name
        expect(Project.last.name).to eq new_name
        expect(page).to have_current_path "/#{user.username}/#{new_path}"
        expect(Project.last.path).to eq new_path
      end

      it 'allows creation from custom project template using only the path', :js do
        new_path = 'example-custom-project-template'
        new_name = 'Example Custom Project Template'

        create_from_template(:instance, projects.first.name)

        page.within '.project-fields-form' do
          fill_in('project_path', with: new_path)

          Sidekiq::Testing.inline! do
            click_button 'Create project'
          end
        end

        expect(page).to have_content new_name
        expect(Project.last.name).to eq new_name
        expect(page).to have_current_path "/#{user.username}/#{new_path}"
        expect(Project.last.path).to eq new_path
      end

      it 'has a working pagination', :js do
        last_project = "label[for='#{projects.last.name}']"

        click_link 'Create from template'
        find('.project-template .custom-instance-project-templates-tab').click

        expect(page).to have_css('.custom-project-templates .gl-pagination')
        expect(page).not_to have_css(last_project)

        find('.js-next-button a').click

        expect(page).to have_css(last_project)
      end
    end

    describe 'when feature custom_project_templates is disabled' do
      it 'does not show custom project templates tab' do
        expect(page).not_to have_css('.project-template .nav-tabs')
      end
    end
  end

  describe 'Custom group-level project templates', :js do
    let!(:user) { create(:user) }
    let!(:group) { create(:group, name: 'parent-group') }
    let!(:template_subgroup) { create(:group, parent: group, name: 'template-subgroup') }
    let!(:template) { create(:project, namespace: template_subgroup) }

    before do
      stub_licensed_features(custom_project_templates: true)
      group.add_owner(user)
      group.update!(custom_project_templates_group_id: template_subgroup.id)
      sign_in user
    end

    context 'from default new project path', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/208500' do
      it 'displays user namespace for default project URL' do
        visit new_project_path
        create_from_template(:group, template.name)

        expect(page).to have_button(user.username, exact: true)
      end
    end

    context 'from subgroup new project path' do
      let!(:other_subgroup) { create(:group, parent: group, name: 'other-subgroup') }

      it 'displays subgroup namespace for default project URL' do
        visit new_project_path(namespace_id: other_subgroup.id)
        create_from_template(:group, template.name)

        expect(page).to have_button("#{group.name}/#{other_subgroup.name}", exact: true)
      end
    end
  end

  def create_from_template(type, template_name)
    tab = if type == :instance
            '.custom-instance-project-templates-tab'
          elsif type == :group
            '.custom-group-project-templates-tab'
          else
            raise ArgumentError, "#{type} is not a valid template type"
          end

    click_link 'Create from template'
    find(tab).click
    find("label[for=#{template_name}]").click
  end
end

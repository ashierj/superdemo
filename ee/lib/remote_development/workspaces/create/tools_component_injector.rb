# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Create
      class ToolsComponentInjector
        include Messages

        # @param [Hash] value
        # @return [Hash]
        def self.inject(value)
          value => {
            processed_devfile: Hash => processed_devfile,
            volume_mounts: Hash => volume_mounts,
            params: Hash => params
          }
          volume_mounts => { data_volume: Hash => data_volume }
          data_volume => { path: String => volume_path }
          params => { agent: Clusters::Agent => agent }

          editor_port = WorkspaceCreator::WORKSPACE_PORT
          ssh_port = 60022
          tools_dir = "#{volume_path}/.gl-tools"
          enable_marketplace = Feature.enabled?(
            :allow_extensions_marketplace_in_workspace,
            agent.project.root_namespace,
            type: :beta
          )

          tools_component = processed_devfile['components'].find { |c| c.dig('attributes', 'gl/inject-editor') }
          use_vscode_1_81_attribute = tools_component.fetch('attributes', {}).fetch('gl/use-vscode-1-81', true)
          use_vscode_1_81 = [true, "true"].include? use_vscode_1_81_attribute
          inject_tools_component(processed_devfile, tools_dir, use_vscode_1_81)

          if tools_component
            override_main_container(
              tools_component,
              tools_dir,
              editor_port,
              ssh_port,
              enable_marketplace
            )
          end

          value
        end

        # @param [Hash] component
        # @param [String] tools_dir
        # @param [Integer] editor_port
        # @param [Integer] ssh_port
        # @param [Boolean] enable_marketplace
        # @return [Hash]
        def self.override_main_container(component, tools_dir, editor_port, ssh_port, enable_marketplace)
          # This overrides the main container's command
          # Open issue to support both starting the editor and running the default command:
          # https://gitlab.com/gitlab-org/gitlab/-/issues/392853
          container_args = <<~"SH".chomp
            sshd_path=$(which sshd)
            if [ -x "$sshd_path" ]; then
              echo "Starting sshd on port ${GL_SSH_PORT}"
              $sshd_path -D -p $GL_SSH_PORT &
            else
              echo "'sshd' not found in path. Not starting SSH server."
            fi
            ${GL_TOOLS_DIR}/init_tools.sh
          SH
          component['container']['command'] = %w[/bin/sh -c]
          component['container']['args'] = [container_args]
          component['container']['env'] = [] if component['container']['env'].nil?
          component['container']['env'] += [
            {
              'name' => 'GL_TOOLS_DIR',
              'value' => tools_dir
            },
            {
              'name' => 'GL_EDITOR_LOG_LEVEL',
              'value' => 'info'
            },
            {
              'name' => 'GL_EDITOR_PORT',
              'value' => editor_port.to_s
            },
            {
              'name' => 'GL_SSH_PORT',
              'value' => ssh_port.to_s
            },
            {
              'name' => 'GL_EDITOR_ENABLE_MARKETPLACE',
              'value' => enable_marketplace.to_s
            }
          ]

          component['container']['endpoints'] = [] if component['container']['endpoints'].nil?
          component['container']['endpoints'].append(
            {
              'name' => 'editor-server',
              'targetPort' => editor_port,
              'exposure' => 'public',
              'secure' => true,
              'protocol' => 'https'
            },
            {
              'name' => 'ssh-server',
              'targetPort' => ssh_port,
              'exposure' => 'internal',
              'secure' => true
            }
          )
          component
        end

        # @param [Hash] processed_devfile
        # @param [String] tools_dir
        # @param [Boolean] use_vscode_1_81
        # @return [Array]
        def self.inject_tools_component(processed_devfile, tools_dir, use_vscode_1_81)
          processed_devfile['components'] += tools_components(tools_dir, use_vscode_1_81)

          processed_devfile['commands'] = [] if processed_devfile['commands'].nil?
          processed_devfile['commands'] += [{
            'id' => 'gl-tools-injector-command',
            'apply' => {
              'component' => 'gl-tools-injector'
            }
          }]

          processed_devfile['events'] = {} if processed_devfile['events'].nil?
          processed_devfile['events']['preStart'] = [] if processed_devfile['events']['preStart'].nil?
          processed_devfile['events']['preStart'] += ['gl-tools-injector-command']
        end

        # @param [String] tools_dir
        # @param [Boolean] use_vscode_1_81
        # @return [Array]
        def self.tools_components(tools_dir, use_vscode_1_81)
          # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409775 - choose image based on which editor is passed.
          image_name = 'registry.gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork/web-ide-injector'
          image_tag = use_vscode_1_81 ? '7' : '8'

          [
            {
              'name' => 'gl-tools-injector',
              'container' => {
                'image' => "#{image_name}:#{image_tag}",
                'env' => [
                  {
                    'name' => 'GL_TOOLS_DIR',
                    'value' => tools_dir
                  }
                ],
                'memoryLimit' => '256Mi',
                'memoryRequest' => '128Mi',
                'cpuLimit' => '500m',
                'cpuRequest' => '100m'
              }
            }
          ]
        end
      end
    end
  end
end

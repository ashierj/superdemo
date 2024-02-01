# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Create
      class EditorComponentInjector
        include Messages

        # @param [Hash] value
        # @return [Hash]
        def self.inject(value)
          value => {
            processed_devfile: Hash => processed_devfile,
            volume_mounts: Hash => volume_mounts,
            # params: Hash => params # NOTE: Params is currently unused until we use the editor entry
          }
          volume_mounts => { data_volume: Hash => data_volume }
          data_volume => { path: String => volume_path }

          # NOTE: Editor is currently unused
          # editor = params[:editor]

          editor_port = 60001
          ssh_port = 60022

          editor_component = processed_devfile['components'].find { |c| c.dig('attributes', 'gl/inject-editor') }
          override_main_container(editor_component, volume_path, editor_port, ssh_port) if editor_component
          inject_editor_component(processed_devfile, volume_path)

          value
        end

        # @param [Hash] component
        # @param [String] volume_path
        # @param [Integer] editor_port
        # @param [Integer] ssh_port
        # @return [Hash]
        def self.override_main_container(component, volume_path, editor_port, ssh_port)
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
            #{volume_path}/.gl-editor/start_server.sh
          SH
          component['container']['command'] = %w[/bin/sh -c]
          component['container']['args'] = [container_args]
          component['container']['env'] = [] if component['container']['env'].nil?
          component['container']['env'] += [
            {
              'name' => 'GL_EDITOR_VOLUME_DIR',
              'value' => "#{volume_path}/.gl-editor"
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
        # @param [String] volume_path
        # @return [Array]
        def self.inject_editor_component(processed_devfile, volume_path)
          processed_devfile['components'] += editor_components(volume_path)

          processed_devfile['commands'] = [] if processed_devfile['commands'].nil?
          processed_devfile['commands'] += [{
            'id' => 'gl-editor-injector-command',
            'apply' => {
              'component' => 'gl-editor-injector'
            }
          }]

          processed_devfile['events'] = {} if processed_devfile['events'].nil?
          processed_devfile['events']['preStart'] = [] if processed_devfile['events']['preStart'].nil?
          processed_devfile['events']['preStart'] += ['gl-editor-injector-command']
        end

        # @param [String] volume_path
        # @return [Array]
        def self.editor_components(volume_path)
          # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409775 - choose image based on which editor is passed.
          image_name = 'registry.gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork/web-ide-injector'
          image_tag = '5'

          [
            {
              'name' => 'gl-editor-injector',
              'container' => {
                'image' => "#{image_name}:#{image_tag}",
                'env' => [
                  {
                    'name' => 'GL_EDITOR_VOLUME_DIR',
                    'value' => "#{volume_path}/.gl-editor"
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

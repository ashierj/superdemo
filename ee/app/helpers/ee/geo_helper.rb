# frozen_string_literal: true

module EE
  module GeoHelper
    STATUS_ICON_NAMES_BY_STATE = {
        synced: 'check-circle-filled',
        pending: 'status_pending',
        failed: 'status_failed',
        never: 'status_notfound'
    }.freeze

    def self.current_node_human_status
      return s_('Geo|primary') if ::Gitlab::Geo.primary?
      return s_('Geo|secondary') if ::Gitlab::Geo.secondary?

      s_('Geo|misconfigured')
    end

    def geo_sites_vue_data
      {
        replicable_types: replicable_types.to_json,
        new_site_url: new_admin_geo_node_path,
        geo_sites_empty_state_svg: image_path("illustrations/empty-state/geo-empty.svg")
      }
    end

    def selective_sync_types_json
      options = {
        ALL: {
          label: s_('Geo|All projects'),
          value: ''
        },
        NAMESPACES: {
          label: s_('Geo|Projects in certain groups'),
          value: 'namespaces'
        },
        SHARDS: {
          label: s_('Geo|Projects in certain storage shards'),
          value: 'shards'
        }
      }

      options.to_json
    end

    def geo_registry_status(registry)
      status_type = case registry.synchronization_state
                    when :synced then 'gl-text-green-500'
                    when :pending then 'gl-text-orange-500'
                    when :failed then 'gl-text-red-500'
                    else 'gl-text-gray-500'
                    end

      content_tag(:div, class: status_type, data: { testid: 'project-status-icon' }) do
        icon = geo_registry_status_icon(registry)
        text = geo_registry_status_text(registry)

        [icon, text].join(' ').html_safe
      end
    end

    def geo_registry_status_icon(registry)
      sprite_icon(STATUS_ICON_NAMES_BY_STATE.fetch(registry.synchronization_state, 'status_notfound'))
    end

    def geo_registry_status_text(registry)
      case registry.synchronization_state
      when :never
        _('Never')
      when :failed
        _('Failed')
      when :pending
        if registry.pending_synchronization?
          s_('Geo|Pending synchronization')
        elsif registry.pending_verification?
          s_('Geo|Pending verification')
        else
          # should never reach this state, unless we introduce new behavior
          _('Unknown')
        end
      when :synced
        _('Synced')
      else
        # should never reach this state, unless we introduce new behavior
        _('Unknown')
      end
    end

    def format_project_count(projects_count, limit)
      if projects_count >= limit
        number_with_delimiter(limit - 1) + "+"
      else
        number_with_delimiter(projects_count)
      end
    end

    def replicable_types
      enabled_replicator_classes.map do |replicator_class|
        {
          data_type: replicator_class.data_type,
          data_type_title: replicator_class.data_type_title,
          data_type_sort_order: replicator_class.data_type_sort_order,
          title: replicator_class.replicable_title,
          title_plural: replicator_class.replicable_title_plural,
          name: replicator_class.replicable_name,
          name_plural: replicator_class.replicable_name_plural,
          verification_enabled: replicator_class.verification_enabled?
        }
      end
    end

    def enabled_replicator_classes
      ::Gitlab::Geo.enabled_replicator_classes
    end

    def geo_filter_nav_options(replicable_controller, replicable_name)
      [
        {
          value: '',
          text: sprintf(s_('Geo|All %{replicable_name}'), { replicable_name: replicable_name }),
          href: url_for(controller: replicable_controller)
        },
        {
          value: 'pending',
          text: s_('Geo|In progress'),
          href: url_for(controller: replicable_controller, sync_status: 'pending')
        },
        {
          value: 'failed',
          text: s_('Geo|Failed'),
          href: url_for(controller: replicable_controller, sync_status: 'failed')
        },
        {
          value: 'synced',
          text: s_('Geo|Synced'),
          href: url_for(controller: replicable_controller, sync_status: 'synced')
        }
      ]
    end

    def prepare_error_app_data(registry)
      {
        synchronizationFailure: registry.last_repository_sync_failure,
        verificationFailure: registry.last_repository_verification_failure,
        retryCount: registry.repository_retry_count || 0
      }.to_json
    end

    def format_file_size_for_checksum(file_size)
      return file_size if file_size.length.even?

      "0" + file_size
    end
  end
end

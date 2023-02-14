# frozen_string_literal: true

module BoardItemFilterable
  extend ActiveSupport::Concern

  private

  def item_filters(args, resource_parent)
    filters = args.to_h

    set_filter_values(filters)

    if filters[:not]
      set_filter_values(filters[:not])
    end

    if filters[:or]
      if ::Feature.disabled?(:or_issuable_queries, resource_parent)
        raise ::Gitlab::Graphql::Errors::ArgumentError,
              "'or' arguments are only allowed when the `or_issuable_queries` feature flag is enabled."
      end

      rewrite_param_name(filters[:or], :author_usernames, :author_username)
      rewrite_param_name(filters[:or], :assignee_usernames, :assignee_username)
      rewrite_param_name(filters[:or], :label_names, :label_name)
    end

    filters
  end

  def set_filter_values(filters)
    filter_by_assignee(filters)
  end

  def filter_by_assignee(filters)
    if filters[:assignee_username] && filters[:assignee_wildcard_id]
      raise ::Gitlab::Graphql::Errors::ArgumentError, 'Incompatible arguments: assigneeUsername, assigneeWildcardId.'
    end

    if filters[:assignee_wildcard_id]
      filters[:assignee_id] = filters.delete(:assignee_wildcard_id)
    end
  end

  def rewrite_param_name(filters, old_name, new_name)
    filters[new_name] = filters.delete(old_name) if filters[old_name].present?
  end
end

::BoardItemFilterable.prepend_mod_with('Resolvers::BoardItemFilterable')

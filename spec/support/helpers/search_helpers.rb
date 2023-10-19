# frozen_string_literal: true

module SearchHelpers
  def fill_in_search(text)
    page.within('.header-search') do
      find('#search').click
      fill_in 'search', with: text
    end

    wait_for_all_requests
  end

  def submit_search(query)
    if has_testid?('super-sidebar-search-button')
      find_by_testid('super-sidebar-search-button').click
      search_form = '#super-sidebar-search-modal'
    else
      search_form = '.header-search-form, .search-page-form'
    end

    page.within(search_form) do
      field = find_field('search')
      field.click
      field.fill_in(with: query)

      if javascript_test?
        field.send_keys(:enter)
      else
        click_button('Search')
      end

      wait_for_all_requests
    end
  end

  def select_search_scope(scope)
    within_testid('search-filter') do
      click_link scope

      wait_for_all_requests
    end
  end

  def has_search_scope?(scope)
    return false unless has_testid?('search-filter')

    within_testid('search-filter') do
      has_link?(scope)
    end
  end

  def max_limited_count
    Gitlab::SearchResults::COUNT_LIMIT_MESSAGE
  end
end

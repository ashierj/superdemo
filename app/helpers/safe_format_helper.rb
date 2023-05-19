# frozen_string_literal: true

module SafeFormatHelper
  # Returns a HTML-safe String.
  #
  # @param [String] format is escaped via `html_escape_once`
  # @param [Array<Hash>] args are escaped via `html_escape` if they are not marked as HTML-safe
  #
  # @example
  #   safe_format('See %{user_input}', user_input: '<b>bold</b>')
  #   # => "See &lt;b&gt;bold&lt;/b&gt"
  #
  #   safe_format('In &lt; hour & more')
  #   # => "In &lt; hour &amp; more"
  #
  # @example With +tag_pair+a support
  #   safe_format('Some %{open}bold%{close} text.', tag_pair(tag.strong, :open, :close))
  #   # => "Some <strong>bold</strong>"
  #   safe_format('Some %{open}bold%{close} %{italicStart}text%{italicEnd}.',
  #     tag_pair(tag.strong, :open, :close),
  #     tag_pair(tag.i, :italicStart, italicEnd))
  #   # => "Some <strong>bold</strong> <i>text</i>.
  def safe_format(format, *args)
    args = args.inject({}, &:merge)

    # Use `Kernel.format` to avoid conflicts with ViewComponent's `format`.
    Kernel.format(
      html_escape_once(format),
      args.transform_values { |value| html_escape(value) }
    ).html_safe
  end

  # Returns a Hash containing a pair of +open+ and +close+ tag parts extracted
  # from HTML-safe +tag+. The values are HTML-safe.
  #
  # Note: If +tag+ is does not start with `<` or does not contain `>` or `/>`
  # an empty Hash is returned.
  #
  # @param [String] tag is a HTML-safe output from tag helper
  # @param [Symbol,Object] open_name name of opening tag
  # @param [Symbol,Object] close_name name of closing tag
  # @raise [ArgumentError] if +tag+ is not HTML-safe
  #
  # @example
  #   tag_pair(helper.tag.strong, :open, close)
  #   # => { open: '<strong>', close: '</strong>' }
  #   tag_pair(helper.tag.link_to('', '/', :open, :close)
  #   # => { open: '<a href="/">', close: '</a>' }
  def tag_pair(tag, open_name, close_name)
    raise ArgumentError, 'Argument `tag` must be a `html_safe`!' unless tag.html_safe?
    return {} unless tag.start_with?('<')

    open_index = tag.index('>')
    close_index = tag.rindex('</')
    return {} unless open_index && close_index

    {
      open_name => tag[0, open_index + 1],
      close_name => tag[close_index, tag.size]
    }
  end
end

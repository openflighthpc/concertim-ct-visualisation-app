module MarkdownRenderer
  class << self
    def render(markdown_text)
      Commonmarker.to_html(
        markdown_text,
        options: {
          parse: { smart: true },
          render: { hardbreaks: false },
        }
      ).html_safe
    end
  end
end

module ApplicationHelper

  def icon_text(text, icon_class)
    separator = text.empty? ? "" : "&nbsp;&nbsp;"
    raw(%{<span class="glyphicon glyphicon-#{icon_class}"></span>#{separator}#{text}})
  end

  # renders a markdown text to HTML
  def md(text)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
    raw(markdown.render(text))
  end

end

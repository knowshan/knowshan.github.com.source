#!/usr/bin/env ruby
# http://blog.nistu.de/2011/08/14/a-category-list-generator-for-jekyll
module Jekyll
  class CategoryListTag < Liquid::Tag
    def render(context)
      html = ""
      categories = context.registers[:site].categories.keys
      categories.sort.each do |category|
        posts_in_category = context.registers[:site].categories[category].size
        html << "<li class='category'><a href='/categories/#{category}/'>#{category} (#{posts_in_category})</a></li>\n"
      end
      html
    end
  end
end

Liquid::Template.register_tag('category_list', Jekyll::CategoryListTag)

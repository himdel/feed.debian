#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# Hpricot::Text to readable string without magic nbsp
def str(s)
  raise "Parse error" unless Hpricot::Text === s
  s.to_s.strip.gsub("\u00a0", ' ')
end

def items
  require 'hpricot'
  require 'open-uri'

  menu = Hpricot(open("https://www.debian.org/vote/")) / "#second-nav > .votemenu"

  sections = (menu / "> li").map do |li|
    {
      :name => str(li.children.first),
      :children => (li / "> ul > li > a").map do |a|
        {
          :href => a[:href],
          :title => str(a.children.first),
        }
      end,
    }
  end

  flat = sections.flat_map do |section|
    section[:children].map do |child|
      child.merge(:section => section[:name])
    end
  end

  flat.reject { |item| ['Home', 'How To'].include?(item[:section]) }
end

def feed(items)
  require 'rss'

  RSS::Maker.make("atom") do |maker|
    maker.channel.author = "Debian"
    maker.channel.updated = Time.now.to_s
    maker.channel.about = "https://www.debian.org/vote/"
    maker.channel.title = "Debian Voting Information"

    items.each do |item|
      maker.items.new_item do |new_item|
        new_item.link = item[:href]
        new_item.title = "#{item[:section]}: #{item[:title]}"
        new_item.updated = Time.now.to_s
      end
    end
  end
end


puts 'Content-Type: application/atom+xml'
puts
puts feed(items).to_s

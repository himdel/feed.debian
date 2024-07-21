#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

FEED_TITLE = "Debian Voting Information"
FEED_SOURCE = "https://www.debian.org/vote/"


# Text to readable string without magic nbsp
def str(s)
  raise "Parse error" unless Nokogiri::XML::Text === s
  s.to_s.strip.gsub("\u00a0", ' ')
end

def items
  require 'nokogiri'
  require 'open-uri'

  menu = Nokogiri::HTML(URI.open(FEED_SOURCE)) / "#second-nav > .votemenu"

  sections = (menu / "> li").map do |li|
    {
      :name => str(li.children.first),
      :children => (li / "> ul > li > a").map do |a|
        {
          :href => a[:href].sub('../vote/', FEED_SOURCE),
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

  filtered = flat.reject { |item| ['Home', 'How To'].include?(item[:section]) }

  filtered.map do |item|
    item.merge(:title => "#{item[:section]}: #{item[:title]}")
  end
end

def json_feed(items)
  require 'json'

  JSON.pretty_generate({
    :version => "https://jsonfeed.org/version/1",
    :home_page_url => FEED_SOURCE,
    :title => FEED_TITLE,
    :items => items.map do |item|
      {
        :content_text => item[:title],
        :id => item[:href],
        :url => item[:href],
      }
    end,
  })
end

puts json_feed(items)

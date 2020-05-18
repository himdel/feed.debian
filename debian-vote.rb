#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

FEED_TITLE = "Debian Voting Information"
FEED_SOURCE = "https://www.debian.org/vote/"


# Hpricot::Text to readable string without magic nbsp
def str(s)
  raise "Parse error" unless Hpricot::Text === s
  s.to_s.strip.gsub("\u00a0", ' ')
end

def items
  require 'hpricot'
  require 'open-uri'

  menu = Hpricot(open(FEED_SOURCE)) / "#second-nav > .votemenu"

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

  filtered = flat.reject { |item| ['Home', 'How To'].include?(item[:section]) }

  filtered.map do |item|
    item.merge(:title => "#{item[:section]}: #{item[:title]}")
  end
end

def atom_feed(items)
  require 'rss'

  RSS::Maker.make("atom") do |maker|
    maker.channel.about = FEED_SOURCE
    maker.channel.author = FEED_TITLE
    maker.channel.title = FEED_TITLE
    maker.channel.updated = Time.now.to_s

    items.each do |item|
      maker.items.new_item do |new_item|
        new_item.link = item[:href]
        new_item.title = item[:title]
        new_item.updated = Time.now.to_s
      end
    end
  end
end

def json_feed(items)
  {
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
  }
end

def atom
  puts 'Content-Type: application/atom+xml'
  puts
  puts atom_feed(items).to_s
end

def json
  require 'json'

  puts 'Content-Type: application/json'
  puts
  puts JSON.pretty_generate(json_feed(items))
end

#atom
json

require 'rubygems'
require 'nokogiri'
require 'json'

def random
  (1..16).collect {(rand*16).floor.to_s(16)}.join ''
end

def is_numeric? item
	begin Integer(item) ; true end rescue false
end


def slug title
  title.gsub(/\s/, '-').gsub(/[^A-Za-z0-9-]/, '').downcase()
end

def clean text
  text.gsub(/’/,"'").gsub(/&nbsp;/,' ').gsub(/^\n\s*/, '').gsub(/Therefore/,"<b>Therefore</b>")
end

def url text
  text.gsub(/(http:\/\/)?([a-zA-Z0-9._-]+?\.(net|com|org|edu)(\/[^ )]+)?)/,'[http:\/\/\2 \2]')
end

def create title
  {'type' => 'create', 'id' => random, 'item' => {'title' => title}}
end 

def paragraph text
  {'type' => 'paragraph', 'text' => text, 'id' => random()}
end

def page title, story
  page = {'title' => title, 'story' => story, 'journal' => [create(title)]}
  File.open("../pages/#{slug(title)}", 'w') do |file| 
    file.write JSON.pretty_generate(page)
  end
end

@summary = []
@patternNames = []

def convert title, doc
#  puts title
  doc.css('b').each do |elem|
    elem.content = "[[#{elem.content}]]" unless elem.content == 'Therefore'
  end
  doc.css('a').each do |elem|
  	elem.replace doc.create_element('i', "[[#{elem.content}]]")
  end
  doc.css('img').each do |elem|  	
  	elem.replace doc.create_element('p', doc.create_element('blockquote',"❖ ❖ ❖") )
  end
  i = 0
  newTitle = title
  story = doc.css('p').collect do |elem|
	if(i == 0 && is_numeric? (title))
		i = 1
		newTitle = elem.content.gsub(/[0-9'\*\.]/,'').gsub(/\s/,"-")
		newTitle = newTitle.gsub(/^-*/,'').gsub(/-*$/, "")
	end
    paragraph clean(elem.inner_html)
  end
  puts newTitle
  page newTitle, story
  # Following depends on all numeric file names processed first. 
  if title != newTitle
  	@summary[Integer(title) - 1] = paragraph(title  + ". [[#{newTitle}]]")
  	@patternNames[Integer(title) - 1] = newTitle
  else
  	@summary << paragraph("[[#{newTitle}]]")
  end
  @patternNames << "Title And License"
end

def summarize
  page "Seminars", @summary
end

Dir.glob('originals/*.html').each do |filename|
  File.open(filename) do |file|
    title = filename.gsub(/originals\//,'').gsub(/\.html/,'').gsub(/([a-z])([A-Z])/,'\1 \2')
    doc = Nokogiri::HTML(file)
    convert title, doc
  end
end

summarize
require 'digest/sha2'
require 'mechanize'

base_dir = ARGV[0] || File.expand_path("../data", __FILE__)
html_dir = File.join(base_dir, "html")
text_dir = File.join(base_dir, "text")
FileUtils.mkdir_p(html_dir)
FileUtils.mkdir_p(text_dir)
downloaded_files = File.join(base_dir, "downloaded")
FileUtils.touch(downloaded_files)
file_to_title = File.join(base_dir, 'file_to_title.tsv')
FileUtils.touch(file_to_title)

agent = Mechanize.new { |a| a.user_agent_alias = "Windows IE 9" }
index_page = agent.get("http://law.e-gov.go.jp/cgi-bin/idxsearch.cgi")
yomi_form = index_page.forms_with(name: "index")[1]
yomi_buttons = yomi_form.buttons_with(name: "H_NAME_YOMI_SUBMIT")

yomi_buttons.each do |button|
  list_page = agent.submit(yomi_form, button)

  laws = list_page.links
  laws.each do |law|
    link  = law.text
    next if File.readlines(downloaded_files).grep(/^#{link}$/).size > 0

    data  = law.click.frame_with(name: "data").click
    title = data.title
    file = Digest::SHA256.hexdigest(title)
    html  = data.content
    text  = data.at('/html/body').text

    puts title
    File.write(File.join(html_dir, "#{file}.html"), html)
    File.write(File.join(text_dir, "#{file}.txt"),  text)
    open(downloaded_files, 'a') { |f| f.puts link }
    open(file_to_title, 'a'){|f| f.puts "#{file}\t#{title}"}
    sleep 3
  end
  sleep 2
end

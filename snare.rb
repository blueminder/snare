require 'sinatra'
require 'redis'
require 'json'
require 'time'

require_relative 'config'
                                                          
before do
    $r = Redis.new(:host => RedisHost, :port => RedisPort) if !$r
    # stand-in user variable until authentication is added
    $user = "test"
end

# list sites
get '/sites' do
  list_sites
end

# new site
post '/:site_id' do
  @current_site = params["site_id"]
  create_site(@current_site)
end

# show site
get '/:site_id' do
  @current_site = params["site_id"]
  show_site(@current_site)
end

# new node
post '/:site_id/n\::node_id' do
  @current_site = params["site_id"]
  @current_node = params["node_id"]
  create_node(@current_site, @current_node)
end

# remove node
delete '/:site_id/n\::node_id' do
  @current_site = params["site_id"]
  @current_node = params["node_id"]
  remove_node(@current_site, @current_node)
end

# create or modify entry
post '/:site_id/n\::node_id/e\::entry_id' do
  @current_site = params["site_id"]
  @current_node = params["node_id"]
  @entry_title = params["entry_id"]
  @entry_body = params["body"]
  if ($r.exists("#{$user}:#{@current_site}:#{@current_node}:#{@entry_title}"))
    edit_node_entry(@current_site, @current_node, @entry_title, @entry_body) 
  else
    create_node_entry(@current_site, @current_node, @entry_title, @entry_body)
  end
end 

# remove node entry
delete '/:site_id/n\::node_id/e\::entry_id' do
  @current_site = params["site_id"]
  @current_node = params["node_id"]
  @entry_title = params["entry_id"]
  remove_node_entry(@current_site, @current_node, @entry_title)
end

# get node attribute
get '/:site_id/n\::node_id/a\::attribute' do
  @current_site = params["site_id"]
  @current_node = params["node_id"]
  @attribute = params["attribute"]
  show_node_attribute(@current_site, @current_node, @attribute)
end

# set node attribute
post "/:site_id/n\::node_id/a\::attribute" do
  @current_site = params["site_id"]
  @current_node = params["node_id"]
  @attribute = params["attribute"]
  @content = params["content"]
  set_node_attribute(@current_site, @current_node, @attribute, @content)
end

# remove node attribute
delete "/:site_id/n\::node_id/a\::attribute" do
  @current_site = params["site_id"]
  @current_node = params["node_id"]
  @attribute = params["attribute"]
  remove_node_attribute(@current_site, @current_node, @attribute)
end

# tag site
post "/:site_id/t\::tags" do
  @current_site = params["site_id"]
  # tags represented as a '+' separated string
  @tags = params["tags"].split('+')
  tag_site(@current_site, @tags)
end

# untag site
delete "/:site_id/t\::tags" do
  @current_site = params["site_id"]
  # tags represented as a '+' separated string
  @tags = params["tags"].split('+')
  untag_site(@current_site, @tags)
end

# tag node
post "/:site_id/n\::node_id/t\::tags" do
  @current_site = params["site_id"]
  @current_node = params["node_id"]
  # tags represented as a '+' string
  @tags = params["tags"].split('+')
  tag_node(@current_site, @current_node, @tags)
end

# untag node
delete "/:site_id/n\::node_id/t\::tags" do
  @current_site = params["site_id"]
  @current_node = params["node_id"]
  # tags represented as a '+' separated string
  @tags = params["tags"].split('+')
  untag_node(@current_site, @current_node, @tags)
end

# tag entry
post "/:site_id/n\::node_id/e\::entry_id/t\::tags" do
  @current_site = params["site_id"]
  @current_node = params["node_id"]
  @current_entry = params["entry_id"]
  # tags represented as a '+' separated string
  @tags = params["tags"].split('+')
  tag_node_entry(@current_site, @current_node, @current_entry, @tags)
end

# untag entry
delete "/:site_id/n\::node_id/e\::entry_id/t\::tags" do
  @current_site = params["site_id"]
  @current_node = params["node_id"]
  @current_entry = params["entry_id"]
  # tags represented as a '+' separated string
  @tags = params["tags"].split('+')
  untag_node_entry(@current_site, @current_node, @current_entry, @tags)
end

# tag relationship
post "/:site_id/n\::node_id/r\::rel/:object_user/:object_site/:object_node/t\::tags" do
  @current_site = params["site_id"]
  @current_node = params["node_id"]
  @predicate = params["rel"]
  @object_user = params["object_user"]
  @object_site = params["object_site"]
  @object_node = params["object_node"]
  # tags represented as a '+' separated string
  @tags = params["tags"].split('+')
  tag_rel(@current_site, @current_node, @predicate, @object_site, @object_node, @tags)
end

# untag relationship
delete "/:site_id/n\::node_id/r\::rel/:object_user/:object_site/:object_node/t\::tags" do
  @current_site = params["site_id"]
  @current_node = params["node_id"]
  @predicate = params["rel"]
  @object_user = params["object_user"]
  @object_site = params["object_site"]
  @object_node = params["object_node"]
  # tags represented as a '+' separated string
  @tags = params["tags"].split('+')
  untag_rel(@current_site, @current_node, @predicate, @object_site, @object_node, @tags)
end

# add relationship
post "/:subject_site/:subject_node/r\::rel/:object_user/:object_site/:object_node" do
  @subject_site = params["subject_site"]
  @subject_node = params["subject_node"]
  @predicate = params["rel"]
  @object_user = params["object_user"]
  @object_site = params["object_site"]
  @object_node = params["object_node"]
  create_rel(@subject_site, @subject_node, @predicate, @object_user, @object_site, @object_node)
end

# edit relationship
post "/:subject_site/:subject_node/r\::rel/:object_user/:object_site/:object_node/r\::new_rel" do
  @subject_site = params["subject_site"]
  @subject_node = params["subject_node"]
  @predicate = params["rel"]
  @object_user = params["object_user"]
  @object_site = params["object_site"]
  @object_node = params["object_node"]
  @new_predicate = params["new_rel"]
  edit_rel(@subject_site, @subject_node, @predicate, @object_user, @object_site, @object_node, @new_predicate)
end

# remove relationship
delete "/:subject_site/:subject_node/r\::rel/:object_user/:object_site/:object_node" do
  @subject_site = params["subject_site"]
  @subject_node = params["subject_node"]
  @predicate = params["rel"]
  @object_user = params["object_user"]
  @object_site = params["object_site"]
  @object_node = params["object_node"]
  remove_rel(@subject_site, @subject_node, @predicate, @object_user, @object_site, @object_node)
end

# show node
get '/:site_id/n\::node_id' do
  @current_site = params["site_id"]
  @current_node = params["node_id"]
  show_node(@current_site, @current_node)
end

# show tagged sites
get '/t\::tag_id/sites' do
  @current_tag = params["tag_id"]
  show_tagged_sites(@current_tag)
end

# show tagged nodes
get '/t\::tag_id/nodes' do
  @current_tag = params["tag_id"]
  show_tagged_nodes(@current_tag)
end

# show tagged entries
get '/t\::tag_id/entries' do
  @current_tag = params["tag_id"]
  show_tagged_node_entries(@current_tag)
end

# show entry
get '/:site_id/n\::node_id/e\::entry_id' do
  @current_site = params["site_id"]
  @current_node = params["node_id"]
  @current_entry = params["entry_id"]
  show_entry(@current_site, @current_node, @current_entry)
end

def list_sites
  unless $r.scard("#{$user}::sites") == 0
    sites = $r.smembers("#{$user}::sites")
    content_type :json
    sites.to_json
  else
    status 400
    body JSON.generate({:user => $user, :error => "No sites currently exist"})
  end
end

def create_site(title)
  unless $r.sismember("#{$user}::sites", title)
    $r.sadd("#{$user}::sites", title)
    $r.hset("#{$user}:#{title}", "title", title)
    content_type :json
    JSON.generate({:user => $user, :site => title})
  else
    status 400
    body JSON.generate({:user => $user, :site => title, :error => "Site already exists"})
  end
end

def rename_site(old_title, new_title)
  if ($r.exists("#{$user}:#{site}"))
    $r.srem("#{$user}::sites", old_title)
    $r.sadd("#{$user}::sites", new_title)
    $r.smembers("#{$user}:#{old_title}::nodes").each do |n|
      $r.smembers("#{$user}:#{old_title}:#{n}::entries").each do |e|
        $r.renamenx("#{$user}:#{old_title}:#{n}:#{e}", "#{$user}:#{new_title}:#{n}:#{e}")
      end
      $r.renamenx("#{$user}:#{old_title}:#{n}", "#{$user}:#{new_title}:#{n}")
    end
    $r.renamenx("#{$user}:#{old_title}", "#{$user}:#{new_title}")
    content_type :json
    JSON.generate({:user => $user, :site => new_title})
  else
    status 400
    body JSON.generate({:user => $user, :site => old_title, :error => "Site #{old_title} does not exist."})
  end
end

def remove_site(title)
  if ($r.exists("#{$user}:#{title}"))
    $r.srem("#{$user}::sites", title)
    $r.keys("#{$user}:#{title}*").each do |x|
      $r.del(x)
    end
    content_type :json
    JSON.generate({:user => $user, :message => "Site #{title} has been successfully removed."})
  else
    status 400
    body JSON.generate({:user => $user, :error => "Site #{title} does not exist."})
  end
end

def show_site(title)
  if ($r.exists("#{$user}:#{title}"))
    site = $r.hgetall("#{$user}:#{title}")
    site['user'] = $user
    if $r.exists("#{$user}:#{title}::tags")
      site['tags'] = $r.smembers("#{$user}:#{title}::tags").join(", ")
    end
    content_type :json
    JSON.generate(site)
  end
end 

def create_node(site, title)
  if ($r.exists("#{$user}:#{site}"))
    $r.sadd("#{$user}:#{site}::nodes", title)
    $r.hset("#{$user}:#{site}:#{title}", "title", title)
    $r.hset("#{$user}:#{site}:#{title}", "site", site)
    $r.hset("#{$user}:#{site}:#{title}", "entries", 0)
    content_type :json
    JSON.generate({:user => $user, :site => site, :node => title})
  end
end

def rename_node(site, old_title, new_title)
  if ($r.exists("#{$user}:#{site}"))
    $r.srem("#{$user}:#{site}::nodes", old_title)
    $r.sadd("#{$user}:#{site}::nodes", new_title)
    $r.smembers("#{$user}:#{site}:#{old_title}::entries").each do |e|
      $r.renamenx("#{$user}:#{site}:#{old_title}:#{e}", "#{$user}:#{site}:#{new_title}:#{e}")
    end
    $r.renamenx("#{$user}:#{site}:#{old_title}::entries", "#{$user}:#{site}:#{new_title}::entries")
    $r.renamenx("#{$user}:#{site}:#{old_title}", "#{$user}:#{site}:#{new_title}")
    content_type :json
    JSON.generate({:user => $user, :site => site, :node => new_title})
  end
end

def remove_node(site, title)
  if ($r.exists("#{$user}:#{site}:#{title}"))
    $r.srem("#{$user}:#{site}::nodes", title)
    $r.keys("#{$user}:#{site}:#{title}*").each do |x|
      $r.del(x)
    end
    content_type :json
    JSON.generate({:user => $user, :site => site, :node => title})
  else
    status 400
    JSON.generate({:user => $user, :error => "Node #{title} does not exist."})
  end
end

def show_node(site, title)
  puts "#{$user}:#{site}:#{title}"
  if ($r.exists("#{$user}:#{site}:#{title}"))
    node = $r.hgetall("#{$user}:#{site}:#{title}")
    node['site'] = site
    node['user'] = $user
    if $r.exists("#{$user}:#{site}:#{title}::tags")
      node['tags'] = $r.smembers("#{$user}:#{site}:#{title}::tags").join(", ")
    end
    content_type :json
    JSON.generate(node)
  end
end

def show_tagged_sites(tag)
  if ($r.exists("#{$user}::tag:#{tag}::sites"))
    sites = $r.smembers("#{$user}::tag:#{tag}::sites")
    content_type :json
    JSON.generate(sites)
  end
end

def show_tagged_nodes(tag)
  if ($r.exists("#{$user}::tag:#{tag}::nodes"))
    nodes = $r.smembers("#{$user}::tag:#{tag}::nodes")
    content_type :json
    JSON.generate(nodes)
  end
end

def show_tagged_node_entries(tag)
  if ($r.exists("#{$user}::tag:#{tag}::entries"))
    entries = $r.smembers("#{$user}::tag:#{tag}::entries")
    content_type :json
    JSON.generate(entries)
  end
end

def show_node_attribute(site, node, attribute)
  if ($r.hexists("#{$user}:#{site}:#{node}", attribute))
    shown = Hash.new
    shown['user'] = $user
    shown['site'] = site
    shown['node'] = node
    shown[attribute] = $r.hget("#{$user}:#{site}:#{node}", attribute)
    content_type :json
    JSON.generate(shown)
  end
end

def set_node_attribute(site, node, attribute, content)
  if ($r.exists("#{$user}:#{site}:#{node}"))
    $r.hset("#{$user}:#{site}:#{node}", attribute, content)
    content_type :json
    show_node(site, node)
  end
end

def remove_node_attribute(site, node, attribute)
  if ($r.exists("#{$user}:#{site}:#{node}"))
    $r.hdel("#{$user}:#{site}:#{node}", attribute)
    show_node(@current_site, @current_node)
  end
end

def show_entry(site, node, entry_name)
  if ($r.exists("#{$user}:#{site}:#{node}:#{entry_name}"))
    entry = $r.hgetall("#{$user}:#{site}:#{node}:#{entry_name}")
    puts "#{$user}:#{site}:#{node}:#{entry_name}::tags"
    if $r.exists("#{$user}:#{site}:#{node}:#{entry_name}::tags")
      entry['tags'] = $r.smembers("#{$user}:#{site}:#{node}:#{entry_name}::tags").join(", ")
    end
    content_type :json
    JSON.generate(entry)
  end
end

def create_node_entry(site, node, entry, content)
  if ($r.exists("#{$user}:#{site}:#{node}"))
    $r.sadd("#{$user}:#{site}:#{node}::entries", entry)
    $r.hset("#{$user}:#{site}:#{node}:#{entry}", "name", entry)
    $r.hset("#{$user}:#{site}:#{node}:#{entry}", "created", Time.now)
    $r.hset("#{$user}:#{site}:#{node}:#{entry}", "updated", Time.now)
    $r.hset("#{$user}:#{site}:#{node}:#{entry}", "body", content)
    $r.hincrby("#{$user}:#{site}:#{node}", "entries", 1)
    show_entry(site, node, entry)
  end
end

def edit_node_entry(site, node, entry, content)
  if ($r.exists("#{$user}:#{site}:#{node}:#{entry}"))
    $r.hset("#{$user}:#{site}:#{node}:#{entry}", "updated", Time.now)
    $r.hset("#{$user}:#{site}:#{node}:#{entry}", "body", content)
    show_entry(site, node, entry)
  end
end

def rename_node_entry(site, node, old_entry_name, new_entry_name)
  if ($r.exists("#{$user}:#{site}:#{node}:#{old_entry_name}"))
    $r.srem("#{$user}:#{site}:#{node}::entries", old_entry_name)
    $r.sadd("#{$user}:#{site}:#{node}::entries", new_entry_name)
    $r.hset("#{$user}:#{site}:#{node}:#{old_entry_name}", "name", new_entry_name)
    $r.rename("#{$user}:#{site}:#{node}:#{old_entry_name}", "#{$user}:#{site}:#{node}:#{new_entry_name}")
    show_entry(site, node, new_entry_name)
  end
end

def remove_node_entry(site, node, entry)
  if ($r.exists("#{$user}:#{site}:#{node}:#{entry}"))
    $r.srem("#{$user}:#{site}:#{node}::entries", entry)
    $r.del("#{$user}:#{site}:#{node}:#{entry}")
    $r.hincrby("#{$user}:#{site}:#{node}", "entries", -1)
  end
end

def create_rel(subject_site, subject_node, predicate, object_user, object_site, object_node)
  if ($r.exists("#{$user}:#{subject_site}:#{subject_node}"))
    $r.sadd("#{$user}:#{subject_site}::relationships", "#{predicate}")
    $r.sadd("#{$user}:#{subject_site}::relationship:#{predicate}", "#{object_user}:#{object_site}:#{object_node}")
  end
end

def edit_rel(subject_site, subject_node, old_predicate, object_user, object_site, object_node, new_predicate)
  if ($r.exists("#{$user}:#{subject_site}:#{subject_node}"))
    $r.sadd("#{$user}:#{subject_site}::relationships", "#{new_predicate}")
    $r.srem("#{$user}:#{subject_site}::relationship:#{old_predicate}", "#{object_user}:#{object_site}:#{object_node}")
    if ($r.scard("#{$user}:#{subject_site}::relationship:#{old_predicate}") == 0)
      $r.srem("#{$user}:#{subject_site}::relationships", "#{old_predicate}")
    end
    $r.sadd("#{$user}:#{subject_site}::relationship:#{new_predicate}", "#{object_user}:#{object_site}:#{object_node}")
  end
end

def remove_rel(subject_site, subject_node, predicate, object_user, object_site, object_node)
  if ($r.exists("#{$user}:#{subject_site}:#{subject_node}::relationship:#{predicate}"))
    $r.srem("#{$user}:#{subject_site}::relationship:#{predicate}", "#{object_user}:#{object_site}:#{object_node}")
    $r.srem("#{$user}:#{subject_site}::relationships", "#{predicate}")
  end
end

def tag_site(site, tags)
  if ($r.exists("#{$user}:#{site}"))
    $r.sadd("#{$user}::tagged:sites", site)
    tags.each do |tag|
      $r.sadd("#{$user}:#{site}::tags", tag)
      $r.sadd("#{$user}::tag:#{tag}::sites", site)
    end
    show_site(site)
  end
end

def untag_site(site, tags)
  if ($r.exists("#{$user}:#{site}::tags"))
    tags.each do |tag|
      puts tag
      $r.srem("#{$user}:#{site}::tags", tag)
      $r.srem("#{$user}::tag:#{tag}::sites", site)
    end
    if ($r.scard("#{$user}:#{site}::tags") == 0)
      $r.srem("#{$user}::tagged:sites", site)
      $r.del("#{$user}:#{site}::tags")
    end
    show_site(site)
  end
end

def tag_node(site, node, tags)
  if ($r.exists("#{$user}:#{site}:#{node}"))
    $r.sadd("#{$user}::tagged:nodes", "#{site}:#{node}")
    $r.sadd("#{$user}:#{site}::tagged:nodes", "#{site}:#{node}")
    tags.each do |tag|
      $r.sadd("#{$user}:#{site}:#{node}::tags", tag)
      $r.sadd("#{$user}::tag:#{tag}::nodes", "#{site}:#{node}")
    end
    show_node(site, node)
  end
end

def untag_node(site, node, tags)
  if ($r.exists("#{$user}:#{site}:#{node}::tags"))
    tags.each do |tag|
      $r.srem("#{$user}:#{site}:#{node}::tags", tag)
      $r.srem("#{$user}::tag:#{tag}::nodes", "#{site}:#{node}")
    end
    if ($r.scard("#{$user}:#{site}:#{node}::tags") == 0)
      $r.srem("#{$user}::tagged::nodes", "#{site}:#{node}")
      $r.srem("#{$user}:#{site}::tagged::nodes", "#{site}:#{node}")
      $r.del("#{$user}:#{site}:#{node}::tags")
    end
    show_node(site, node)
  end
end

def tag_node_entry(site, node, entry, tags)
  if ($r.exists("#{$user}:#{site}:#{node}:#{entry}"))
    $r.sadd("#{$user}::tagged:entries", "#{site}:#{node}:#{entry}")
    $r.sadd("#{$user}:#{site}:#{node}::tagged:entries", entry)
    tags.each do |tag|
      $r.sadd("#{$user}:#{site}:#{node}:#{entry}::tags", tag)
      $r.sadd("#{$user}::tag:#{tag}::entries", "#{site}:#{node}:#{entry}")
    end
    show_entry(site, node, entry)
  end
end

def untag_node_entry(site, node, entry, tags)
  if ($r.exists("#{$user}:#{site}:#{node}:#{entry}::tags"))
    tags.each do |tag|
      $r.srem("#{$user}:#{site}:#{node}:#{entry}::tags", tag)
      $r.srem("#{$user}::tag:#{tag}::entries", "#{site}:#{node}:#{entry}")
    end
    if ($r.scard("#{$user}:#{site}:#{node}:#{entry}::tags") == 0)
      $r.srem("#{$user}::tagged:entries", "#{site}:#{node}:#{entry}")
      $r.srem("#{$user}:#{site}:#{node}::tagged:entries", entry)
      $r.del("#{$user}:#{site}:#{node}:#{entry}::tags")
    end
    show_entry(site, node, entry)
  end
end

def tag_rel(subject_site, subject_node, predicate, object_site, object_node, tags)
  # I really gotta find a nicer way to outline relationships. OH WELL. HACK AWAY.
  if ($r.exists("#{$user}:#{subject_site}:#{subject_node}:#{predicate}:#{object_site}:#{object_node}"))
    $r.sadd("#{$user}::tagged:relationships",  "#{$user}:#{subject_site}:#{subject_node}:#{predicate}:#{object_site}:#{object_node}")
    $r.sadd("#{$user}:#{subject_site}:#{subject_node}::tagged:relationships", "#{$user}:#{subject_site}:#{subject_node}:#{predicate}:#{object_site}:#{object_node}")
    tags.each do |tag|
      $r.sadd("#{$user}:#{subject_site}:#{subject_node}:#{predicate}:#{object_site}:#{object_node}::tags", tag)
      $r.sadd("#{$user}::tag:#{tag}::relationships", "#{$user}:#{subject_site}:#{subject_node}:#{predicate}:#{object_site}:#{object_node}")
    end
  end
end

def untag_rel(subject_site, subject_node, predicate, object_site, object_node, tags)
  if ($r.exists("#{$user}:#{subject_site}:#{subject_node}:#{predicate}:#{object_site}:#{object_node}::tags"))
    tags.each do |tag|
      $r.srem("#{$user}:#{subject_site}:#{subject_node}:#{predicate}:#{object_site}:#{object_node}::tags", tag)
      $r.srem("#{$user}::tag:#{tag}::relationships", "#{$user}:#{subject_site}:#{subject_node}:#{predicate}:#{object_site}:#{object_node}")
    end
    if ($r.scard("#{$user}:#{subject_site}:#{subject_node}:#{predicate}:#{object_site}:#{object_node}::tags") == 0)
      $r.srem("#{$user}::tagged:relationships",  "#{$user}:#{subject_site}:#{subject_node}:#{predicate}:#{object_site}:#{object_node}")
      $r.srem("#{$user}:#{subject_site}:#{subject_node}::tagged:relationships", "#{$user}:#{subject_site}:#{subject_node}:#{predicate}:#{object_site}:#{object_node}")
      $r.del("#{$user}:#{subject_site}:#{subject_node}:#{predicate}:#{object_site}:#{object_node}::tags")
    end
  end
end


require 'sinatra'
require 'redis'
require 'json'
require 'date'

require_relative 'config'
                                                          
before do
    $r = Redis.new(:host => RedisHost, :port => RedisPort) if !$r
    # stand-in user variable until authentication is added
    $user = "test"
end

get '/' do
end

# new site
post '/:site_id/new' do
  @current_site = params["site_id"]
  create_site(@current_site)
end

# new node
# creates a new node with an initial entry
post '/:site_id/:node_id/new' do
  @current_site = params["site_id"]
  @current_node = params["node_id"]
  @entry_title = params["name"]
  @entry_body = params["body"]
  create_node(@current_site, @current_node)
  create_node_entry(@current_site, @current_node, @entry_title, @entry_body)
end

# new entry
post '/:site_id/:node_id/new_entry' do
  @current_site = params["site_id"]
  @current_node = params["node_id"]
  @entry_title = params["name"]
  @entry_body = params["body"]
  create_node_entry(@current_site, @current_node, @entry_title, @entry_body)
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
    content_type :json
    JSON.generate(node)
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
    content_type :json
    show_node(site, node)
  end
end

def show_entry(site, node, entry)
  if ($r.exists("#{$user}:#{site}:#{node}:#{entry}"))
    entry = $r.hgetall("#{$user}:#{site}:#{node}:#{entry}")
    content_type :json
    JSON.generate(entry)
  end
end

def create_node_entry(site, node, entry, content)
  if ($r.exists("#{$user}:#{site}:#{node}"))
    $r.sadd("#{$user}:#{site}:#{node}::entries", entry)
    $r.hset("#{$user}:#{site}:#{node}:#{entry}", "name", entry)
    $r.hset("#{$user}:#{site}:#{node}:#{entry}", "created", Date.now)
    $r.hset("#{$user}:#{site}:#{node}:#{entry}", "updated", Date.now)
    $r.hset("#{$user}:#{site}:#{node}:#{entry}", "body", content)
    $r.hincrby("#{$user}:#{site}:#{node}", "entries", 1)
    show_entry(site, node, entry)
  end
end

def edit_node_entry(site, node, entry, content)
  if ($r.exists("#{$user}:#{site}:#{node}:#{entry}"))
    $r.hset("#{$user}:#{site}:#{node}:#{entry}", "content", content)
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

def remove_node_entry(site, node, entry, name)
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
    $r.sadd("#{$user}:#{site}::relationships", "#{new_predicate}")
    $r.srem("#{$user}:#{subject_site}::relationship:#{old_predicate}", "#{object_user}:#{object_site}:#{object_node}")
    if ($r.scard("#{$user}:#{subject_site}::relationship:#{old_predicate}") == 0)
      $r.srem("#{$user}:#{site}::relationships", "#{old_predicate}")
    end
    $r.sadd("#{$user}:#{subject_site}::relationship:#{new_predicate}", "#{object_user}:#{object_site}:#{object_node}")
  end
end

def remove_rel(subject_site, subject_node, predicate, object_user, object_site, object_node)
  if ($r.exists("#{$user}:#{subject_site}:#{subject_node}::relationship:#{predicate}"))
    $r.srem("#{$user}:#{site}::relationship:#{predicate}", "#{object_user}:#{object_site}:#{object_node}")
    $r.srem("#{$user}:#{site}::relationships", "#{predicate}")
  end
end

def tag_site(site, *tags)
  if ($r.exists("#{$user}:#{site}"))
    $r.sadd("#{$user}::tagged:sites", site)
    tags.each do |tag|
      $r.sadd("#{$user}:#{site}::tags", tag)
    end
  end
end

def untag_site(site, *tags)
  if ($r.exists("#{$user}:#{site}::tags"))
    tags.each do |tag|
      $r.srem("#{$user}:#{site}::tags", tag)
    end
    if ($r.zcard("#{$user}:#{site}::tags") == 0)
      $r.srem("#{$user}::tagged:sites", site)
      $r.del("#{$user}:#{site}::tags")
    end
  end
end

def tag_node(site, node, *tags)
  if ($r.exists("#{$user}:#{site}:#{node}"))
    $r.sadd("#{$user}::tagged:nodes", "#{site}:#{node}")
    $r.sadd("#{$user}:#{site}::tagged:nodes", node)
    tags.each do |tag|
      $r.sadd("#{$user}:#{site}:#{node}::tags", tag)
    end
  end
end

def untag_node(site, node, *tags)
  if ($r.exists("#{$user}:#{site}:#{node}::tags"))
    tags.each do |tag|
      $r.srem("#{$user}:#{site}:#{node}::tags", tag)
    end
    if ($r.zcard("#{$user}:#{site}:#{node}::tags") == 0)
      $r.srem("#{$user}::tagged:nodes", "#{site}:#{node}")
      $r.srem("#{$user}:#{site}::tagged:nodes", node)
      $r.del("#{$user}:#{site}:#{node}::tags")
    end
  end
end

def tag_entry(site, node, entry, *tags)
  if ($r.exists("#{$user}:#{site}:#{node}:#{entry}"))
    $r.sadd("#{$user}::tagged:entries", "#{site}:#{node}:#{entry}")
    $r.sadd("#{$user}:#{site}:#{node}::tagged:entries", entry)
    tags.each do |tag|
      $r.sadd("#{$user}:#{site}:#{node}:#{entry}::tags", tag)
    end
  end
end

def untag_entry(site, node, *tags)
  if ($r.exists("#{$user}:#{site}:#{node}:#{entry}::tags"))
    tags.each do |tag|
      $r.srem("#{$user}:#{site}:#{node}::tags", tag)
    end
    if ($r.zcard("#{$user}:#{site}:#{node}:#{entry}::tags") == 0)
      $r.srem("#{$user}::tagged:entries", "#{site}:#{node}:#{entry}")
      $r.srem("#{$user}:#{site}:#{node}::tagged:entries", entry)
      $r.del("#{$user}:#{site}:#{node}:#{entry}::tags")
    end
  end
end

def tag_rel(subject_site, subject_node, predicate, object_site, object_node, *tags)
  if ($r.exists("#{$user}:#{site}:#{node}:#{entry}"))
    $r.sadd("#{$user}::tagged:entries", "#{site}:#{node}:#{entry}")
    $r.sadd("#{$user}:#{site}:#{node}::tagged:entries", entry)
    tags.each do |tag|
      $r.sadd("#{$user}:#{site}:#{node}:#{entry}::tags", tag)
    end
  end
end

def untag_rel(subject_site, subject_node, predicate, object_site, object_node, *tags)
  if ($r.exists("#{$user}:#{site}:#{node}:#{entry}::tags"))
    tags.each do |tag|
      $r.srem("#{$user}:#{site}:#{node}::tags", tag)
    end
    if ($r.zcard("#{$user}:#{site}:#{node}:#{entry}::tags") == 0)
      $r.srem("#{$user}::tagged:entries", "#{site}:#{node}:#{entry}")
      $r.srem("#{$user}:#{site}:#{node}::tagged:entries", entry)
      $r.del("#{$user}:#{site}:#{node}:#{entry}::tags")
    end
  end
end

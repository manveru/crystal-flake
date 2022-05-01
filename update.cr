#!/usr/bin/env crystal

require "json"
require "http/client"
require "levenshtein"

class Release
  include JSON::Serializable
  property assets : Array(Asset)
  property tag_name : String

  class Asset
    include JSON::Serializable
    property browser_download_url : String
  end
end

def update_crystal
  meta = JSON.parse(`nix flake metadata --json`)
  nodes = meta["locks"]["nodes"]

  mapping = {
    "x86_64-darwin" => "darwin-x86_64",
    "x86_64-linux"  => "linux-x86_64",
    "i686-linux"    => "linux-i686",
  }

  response = HTTP::Client.get("https://api.github.com/repos/crystal-lang/crystal/releases/latest")
  release = Release.from_json(response.body)

  puts "latest release is #{release.tag_name}"

  old_source = begin
    o = nodes["crystal-src"]["original"]
    "#{o["type"]}:#{o["owner"]}/#{o["repo"]}/#{o["ref"]}"
  end
  new_source = "github:crystal-lang/crystal/#{release.tag_name}"

  replacements = {
    old_source                  => new_source,
    /crystalVersion = "[^"]+";/ => %(crystalVersion = "#{release.tag_name}";),
  }

  mapping.each do |nix_arch, crystal_arch|
    old_url = nodes["crystal-#{nix_arch}"]["locked"]["url"].as_s
    new_url = Levenshtein.find(old_url) do |l|
      release.assets.each do |asset|
        l.test asset.browser_download_url
      end
    end

    replacements[old_url] = new_url if new_url
  end

  replacements.reject! { |old, new| old == new }

  flake = File.read("flake.nix")

  any = false
  replacements.each do |old, new|
    copy = flake.gsub(old) { new }
    any = true if copy != flake
    flake = copy
  end

  if any
    File.write("flake.nix", flake)
    status = Process.run("nix", args: %w[
      flake lock
      --update-input crystal-i686-linux
      --update-input crystal-x86_64-darwin
      --update-input crystal-x86_64-linux
    ])
    raise "failed to update the flake.lock: #{status.exit_status}" unless status.success?
  else
    puts "no replacements done"
  end
end

def update_crystalline
  meta = JSON.parse(`nix flake metadata --json`)
  nodes = meta["locks"]["nodes"]

  response = HTTP::Client.get("https://api.github.com/repos/elbywan/crystalline/releases/latest")
  release = Release.from_json(response.body)

  puts "latest crystalline release is #{release.tag_name}"

  old_source = begin
    o = nodes["crystalline-src"]["original"]
    "#{o["type"]}:#{o["owner"]}/#{o["repo"]}/#{o["ref"]}"
  end

  new_source = "github:elbywan/crystalline/#{release.tag_name}"

  replacements = {
    old_source                      => new_source,
    /crystallineVersion = "[^"]+";/ => %(crystallineVersion = "#{release.tag_name.gsub(/^v/, "")}";),
  }

  replacements.reject! { |old, new| old == new }

  flake = File.read("flake.nix")

  any = false
  replacements.each do |old, new|
    copy = flake.gsub(old) { new }
    any = true if copy != flake
    flake = copy
  end

  if any
    File.write("flake.nix", flake)
    status = Process.run("nix", args: %w[
      flake lock --update-input crystalline-src
    ])
    raise "failed to update the flake.lock: #{status.exit_status}" unless status.success?
  else
    puts "no replacements done"
  end
end

def update_bdwgc
  meta = JSON.parse(`nix flake metadata --json`)
  nodes = meta["locks"]["nodes"]

  response = HTTP::Client.get("https://api.github.com/repos/ivmai/bdwgc/releases")
  releases = Array(Release).from_json(response.body)
  release = releases.first

  puts "latest bdwgc release is #{release.tag_name}"

  old_source = begin
    o = nodes["bdwgc-src"]["original"]
    "#{o["type"]}:#{o["owner"]}/#{o["repo"]}/#{o["ref"]}"
  end

  new_source = "github:ivmai/bdwgc/#{release.tag_name}"

  replacements = {
    old_source                => new_source,
    /bdwgcVersion = "[^"]+";/ => %(bdwgcVersion = "#{release.tag_name.gsub(/^v/, "")}";),
  }

  replacements.reject! { |old, new| old == new }

  flake = File.read("flake.nix")

  any = false
  replacements.each do |old, new|
    copy = flake.gsub(old) { new }
    any = true if copy != flake
    flake = copy
  end

  if any
    File.write("flake.nix", flake)
    status = Process.run("nix", args: %w[
      flake lock --update-input bdwgc-src
    ])
    raise "failed to update the flake.lock: #{status.exit_status}" unless status.success?
  else
    puts "no replacements done"
  end
end

def update_ameba
  meta = JSON.parse(`nix flake metadata --json`)
  nodes = meta["locks"]["nodes"]

  response = HTTP::Client.get("https://api.github.com/repos/crystal-ameba/ameba/releases/latest")
  release = Release.from_json(response.body)

  puts "latest ameba release is #{release.tag_name}"

  old_source = begin
    o = nodes["ameba-src"]["original"]
    "#{o["type"]}:#{o["owner"]}/#{o["repo"]}/#{o["ref"]}"
  end

  new_source = "github:crystal-ameba/ameba/#{release.tag_name}"

  replacements = {
    old_source                => new_source,
    /amebaVersion = "[^"]+";/ => %(amebaVersion = "#{release.tag_name.gsub(/^v/, "")}";),
  }

  replacements.reject! { |old, new| old == new }

  flake = File.read("flake.nix")

  any = false
  replacements.each do |old, new|
    copy = flake.gsub(old) { new }
    any = true if copy != flake
    flake = copy
  end

  if any
    File.write("flake.nix", flake)
    status = Process.run("nix", args: %w[
      flake lock --update-input ameba-src
    ])
    raise "failed to update the flake.lock: #{status.exit_status}" unless status.success?
  else
    puts "no replacements done"
  end
end

update_crystal
update_crystalline
update_bdwgc
update_ameba

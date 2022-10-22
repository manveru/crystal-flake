#!/usr/bin/env crystal

require "json"
require "http/client"
require "levenshtein"
require "string_scanner"

# A partial parser of the netrc format
# No support for default, account, or macdef)
class Netrc
  def self.parse
    s = StringScanner.new(File.exists?(file) ? File.read(file) : "")
    machines = {} of String => Hash(String, String)
    machine = ""

    until s.eos?
      if s.scan(/(default|macdef)\s*/)
        raise "Unsupported token '#{s[1]}' in .netrc"
      end

      if s.scan(/machine\s+(\S+)/)
        machine = s[1]
        machines[machine] = {} of String => String
      end

      if s.scan(/(\S+)\s+(\S+)/)
        raise "Unexpected token '#{s[1]}' in .netrc, expected machine" if machine == ""
        machines[machine][s[1]] = s[2]
      end

      s.scan(/\s*/)
    end

    machines
  end

  private def self.file
    File.expand_path("~/.netrc", home: true)
  end
end

class Release
  include JSON::Serializable
  property assets : Array(Asset)
  property tag_name : String

  class Asset
    include JSON::Serializable
    property browser_download_url : String
  end
end

enum Recency
  Latest
  Newest
end

NETRC = Netrc.parse

def update(org : String, repo : String, recency = Recency::Latest)
  meta = JSON.parse(`nix flake metadata --json`)
  nodes = meta["locks"]["nodes"]

  url = URI.parse("https://api.github.com")
  client = HTTP::Client.new(url)
  client.basic_auth(NETRC.dig?(url.host.to_s, "login"), NETRC.dig?(url.host.to_s, "password"))

  release =
    case recency
    in Recency::Latest
      response = client.get("/repos/#{org}/#{repo}/releases/latest")
      Release.from_json(response.body)
    in Recency::Newest
      response = client.get("/repos/#{org}/#{repo}/releases")
      Array(Release).from_json(response.body).first
    end

  old_source = begin
    o = nodes["#{repo}-src"]["original"]
    "#{o["type"]}:#{o["owner"]}/#{o["repo"]}/#{o["ref"]}"
  end

  new_source = "github:#{org}/#{repo}/#{release.tag_name}"

  return if old_source == new_source
  puts "updating #{old_source} -> #{new_source}"

  replacements = {
    old_source                  => new_source,
    /#{repo}Version = "[^"]+";/ => %(#{repo}Version = "#{release.tag_name.gsub(/^v/, "")}";),
  }

  if repo == "crystal"
    mapping = [
      "x86_64-darwin",
      "x86_64-linux",
      "i686-linux",
    ]

    mapping.each do |arch|
      old_url = nodes["crystal-#{arch}"]["locked"]["url"].as_s
      new_url = Levenshtein.find(old_url) do |l|
        release.assets.each do |asset|
          l.test asset.browser_download_url
        end
      end

      replacements[old_url] = new_url if new_url
    end
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
    status = Process.run("nix", args: ["flake", "lock", "--update-input", "#{repo}-src"])
    raise "failed to update the flake.lock: #{status.exit_status}" unless status.success?
  end

  puts "Building .##{repo}"
  Process.run("nix", args: ["build", ".##{repo}"])
end

update org: "ivmai", repo: "bdwgc", recency: Recency::Newest
update org: "crystal-lang", repo: "crystal"
update org: "crystal-ameba", repo: "ameba"
update org: "elbywan", repo: "crystalline"

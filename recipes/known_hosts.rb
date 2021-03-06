#
# Cookbook Name:: ssh_known_hosts
# Recipe:: default
#
# Author:: Ken-ichi TANABE (<nabeken@tknetworks.org>)
# Author:: Scott M. Likens (<scott@likens.us>)
# Author:: Joshua Timberman (<joshua@opscode.com>)
#
# Copyright 2009, Adapp, Inc.
# Copyright 2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
require 'resolv'
r = Resolv.new
nodes = []

if !Chef::Config[:solo] || defined?(ChefSpec)
  nodes += search(:node, "keys_ssh:* NOT name:#{node.name}")
end

begin
  other_hosts = data_bag('ssh_known_hosts')
rescue
  Chef::Log.info("Could not load data bag 'ssh_known_hosts', this is optional, moving on...")
end

addr2keys = {}
ssh_pubkeys = {}

if other_hosts
  other_hosts.each do |h|
    begin
      host = data_bag_item('ssh_known_hosts', h).to_hash
      # if ipaddresses found
      host['ipaddress'] ||= r.getaddresses(host['fqdn'])

      if host['ipaddress'].is_a?(String)
        ssh_pubkeys["#{host['fqdn']},#{host['ipaddress']}"] = host['rsa']
        addr2keys[host['ipaddress'].downcase] = host['rsa']
      else
        host['ipaddress'].each do |ipaddr|
          ssh_pubkeys["#{host['fqdn']},#{ipaddr}"] = host['rsa']
          addr2keys[ipaddr.downcase] = host['rsa']
        end
      end
    rescue
      Chef::Log.info("failed to get data_bag_item")
    end
  end
end

private_ipaddress_and_loopback = [
  /^10\./,
  /^172\.(?:1[6-9]|2\d|3[01])\./,
  /^192\.168\./,
  /^127\./
]

nodes.each do |s|
  s['network']['interfaces'].each do |int, props|
    Chef::Log.debug("interface: #{int}, props: #{props.inspect}")
    next unless props.has_key?("addresses")
    props['addresses'].each do |addr, addr_props|
      Chef::Log.debug("addr: #{addr}, props: #{addr_props.inspect}")
      # remove private IPv4 and lookback addresses
      next if private_ipaddress_and_loopback.any? { |mask| mask.match(addr) }
      if addr_props['family'] == "inet" ||
         (addr_props['family'] == "inet6" && addr_props['scope'] == "Global")
        ssh_pubkeys["#{s['fqdn']},#{addr}"] = s['keys']['ssh']['host_rsa_public']
        addr2keys[addr.downcase] = s['keys']['ssh']['host_rsa_public']
      end
    end
  end
end

node['ssh']['known_hosts']['aliases'].each_pair do |from, to|
  if to.nil?
    r.getaddresses(from).each do |addr|
      addr.downcase!
      if addr2keys.has_key?(addr)
        ssh_pubkeys["#{from},#{addr}"] = addr2keys[addr]
      end
    end
  else
    n = nodes.find { |_node| _node.name == to }
    if n
      Chef::Log.info("Add alias #{from} as #{to}")
      ssh_pubkeys[from] = n['keys']['ssh']['host_rsa_public']
    else
      Chef::Log.info("#{to} is not found")
    end
  end
end

template "/etc/ssh/ssh_known_hosts" do
  source "known_hosts.erb"
  mode 0444
  owner "root"
  group node['etc']['passwd']['root']['gid']
  backup false
  variables :pubkeys => ssh_pubkeys
end

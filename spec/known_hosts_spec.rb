require 'chefspec'
require 'resolv'

describe 'ssh::known_hosts' do
  it 'should create system-wide known_hosts from search' do
    chef_run = ChefSpec::ChefRunner.new do |node|
      node.set['etc']['passwd']['root']['gid'] = 0
    end
    Chef::Recipe.any_instance.stub(:search).with(:node, "keys_ssh:* NOT name:chefspec.local").and_return([
      {
        'name' => 'chefspec1.example.org',
        'fqdn' => 'chefspec1.example.org',
        'ipaddress' => '1.1.1.1',
        'keys' => {
          'ssh' => {
            'host_rsa_public' =>'chefspec1RSAKEY'
          }
        },
        'network' => {
          'interfaces' => {
            'eth0' => {
              'addresses' => {
                'fe80::1' => {
                  'family' => 'inet6',
                  'prefixlen' => '64',
                  'scope' => 'Link'
                },
                '2001:db8::1' => {
                  'family' => 'inet6',
                  'prefixlen' => '64',
                  'scope' => 'Global'
                },
                '1.1.1.1' => {
                  'family' => 'inet',
                },
                '172.23.1.1' => {
                  'family' => 'inet',
                },
                '192.168.1.1' => {
                  'family' => 'inet',
                },
                '10.1.1.1' => {
                  'family' => 'inet',
                }
              }
            }
          }
        }
      },
      {
        'name' => 'chefspec2.example.org',
        'fqdn' => 'chefspec2.example.org',
        'ipaddress' => '1.1.1.2',
        'keys' => {
          'ssh' => {
            'host_rsa_public' =>'chefspec2RSAKEY'
          }
        },
        'network' => {
          'interfaces' => {
            'eth0' => {
              'addresses' => {
                'fe80::2' => {
                  'family' => 'inet6',
                  'prefixlen' => '64',
                  'scope' => 'Link'
                },
                '2001:db8::2' => {
                  'family' => 'inet6',
                  'prefixlen' => '64',
                  'scope' => 'Global'
                },
                '1.1.1.2' => {
                  'family' => 'inet',
                },
                '172.23.1.2' => {
                  'family' => 'inet',
                },
                '192.168.1.2' => {
                  'family' => 'inet',
                },
                '10.1.1.2' => {
                  'family' => 'inet',
                }
              }
            }
          }
        }
      }
    ])
    chef_run.converge 'ssh::known_hosts'
    chef_run.should create_file '/etc/ssh/ssh_known_hosts'
    [
      "chefspec1.example.org,1.1.1.1 ssh-rsa chefspec1RSAKEY",
      "chefspec1.example.org,2001:db8::1 ssh-rsa chefspec1RSAKEY",
      "chefspec2.example.org,1.1.1.2 ssh-rsa chefspec2RSAKEY",
      "chefspec2.example.org,2001:db8::2 ssh-rsa chefspec2RSAKEY"
    ].each do |l|
      chef_run .should create_file_with_content '/etc/ssh/ssh_known_hosts', l
     end
  end

  it 'should create system-wide known_hosts from data_bag' do
    pending 'pending'
  end
end

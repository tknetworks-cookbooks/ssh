require 'chefspec'
require 'resolv'

describe 'ssh::known_hosts' do
  let(:chef_run) {
    ChefSpec::ChefRunner.new do |node|
      node.set['etc']['passwd']['root']['gid'] = 0
    end
  }
  it 'should create system-wide known_hosts from search' do
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
                '127.0.0.1' => {
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
                '127.0.0.2' => {
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

    [
      "chefspec1.example.org,fe80::1 ssh-rsa chefspec1RSAKEY",
      "chefspec1.example.org,172.23.1.1 ssh-rsa chefspec1RSAKEY",
      "chefspec1.example.org,192.168.1.1 ssh-rsa chefspec1RSAKEY",
      "chefspec1.example.org,10.1.1.1 ssh-rsa chefspec1RSAKEY",
      "chefspec1.example.org,127.1.1.1 ssh-rsa chefspec1RSAKEY",
      "chefspec2.example.org,fe80::2 ssh-rsa chefspec2RSAKEY",
      "chefspec2.example.org,172.23.1.2 ssh-rsa chefspec2RSAKEY",
      "chefspec2.example.org,192.168.1.2 ssh-rsa chefspec2RSAKEY",
      "chefspec2.example.org,10.1.1.2 ssh-rsa chefspec2RSAKEY",
      "chefspec2.example.org,127.1.1.2 ssh-rsa chefspec1RSAKEY",
    ].each do |l|
      chef_run .should_not create_file_with_content '/etc/ssh/ssh_known_hosts', l
     end
  end

  it 'should create system-wide known_hosts from data_bag and aliases' do
    Chef::Recipe.any_instance.stub(:search).with(:node, "keys_ssh:* NOT name:chefspec.local").and_return([
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
                '127.0.0.2' => {
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
      }])
    Chef::Recipe.any_instance.stub(:data_bag).with('ssh_known_hosts').and_return(
      %w{chefspec1 chefspec2})
    Chef::Recipe.any_instance.stub(:data_bag_item).with('ssh_known_hosts', 'chefspec1').and_return(
      {
        'name' => 'chefspec1.example.org',
        'fqdn' => 'chefspec1.example.org',
        'ipaddress' => '1.1.1.1',
        'rsa' =>'chefspec1RSAKEY'
      })
    Chef::Recipe.any_instance.stub(:data_bag_item).with('ssh_known_hosts', 'chefspec2').and_return(
      {
        'name' => 'chefspec2.example.org',
        'fqdn' => 'chefspec2.example.org',
        'ipaddress' => '172.16.1.2',
        'rsa' =>'chefspec2RSAKEY'
      })
    Resolv.any_instance.stub(:getaddresses).with('chefspec1a.example.org').and_return(%w{1.1.1.1})
    chef_run.node.set['ssh']['known_hosts']['aliases']['chefspec1a.example.org'] = nil
    chef_run.node.set['ssh']['known_hosts']['aliases']['172.16.1.3'] = 'chefspec2.example.org'

    chef_run.converge 'ssh::known_hosts'
    chef_run.should create_file '/etc/ssh/ssh_known_hosts'
    [
      'chefspec1a.example.org,1.1.1.1 ssh-rsa chefspec1RSAKEY',
      'chefspec1.example.org,1.1.1.1 ssh-rsa chefspec1RSAKEY',
      'chefspec2.example.org,172.16.1.2 ssh-rsa chefspec2RSAKEY',
      '172.16.1.3 ssh-rsa chefspec2RSAKEY'
    ].each do |l|
      chef_run.should create_file_with_content '/etc/ssh/ssh_known_hosts', l
    end
  end
end

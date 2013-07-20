#
# Author:: Ken-ichi TANABE (<nabeken@tknetworks.org>)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'spec_helper'

describe 'ssh::sshd' do
  context 'on openbsd' do
    before do
      chef_run.converge('ssh::sshd')
    end

    include_context 'openbsd'

    it 'should create sshd_config' do
      expect(chef_run).to create_file '/etc/ssh/sshd_config'
      conf = chef_run.template('/etc/ssh/sshd_config')
      expect(conf).to be_owned_by('root', 0)
      expect(conf.mode).to eq(0644)
    end

    it 'should enable/start sshd' do
      expect(chef_run).to enable_service 'sshd'
      expect(chef_run).to start_service 'sshd'
    end

    it 'should disable password authentication' do
      expect(chef_run).to create_file_with_content '/etc/ssh/sshd_config', 'PasswordAuthentication no'
    end
  end
end

# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-dashboard::horizon' do
  describe 'redhat' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) do
      runner.converge('openstack-dashboard::server')
    end

    include_context 'dashboard_stubs'
    include_context 'redhat_stubs'

    it 'installs packages' do
      expect(chef_run).to upgrade_package('openstack-dashboard')
      expect(chef_run).to upgrade_package('MySQL-python')
    end

    describe 'local_settings' do
      let(:file) { chef_run.template('/etc/openstack-dashboard/local_settings') }

      it 'creates local_settings' do
        expect(chef_run).to create_template(file.name).with(
          user: 'root',
          group: 'apache',
          mode: 0640
        )
      end

      it 'has urls set' do
        [
          %r{^LOGIN_URL = '/auth/login/'$},
          %r{^LOGOUT_URL = '/auth/logout/'$},
          %r{^LOGIN_REDIRECT_URL = '/'$}
        ].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has policy file path set' do
        expect(chef_run).to render_file(file.name)
          .with_content(%r{^POLICY_FILES_PATH = '/etc/openstack-dashboard'$})
      end
    end

    it 'does not remove openstack-dashboard-ubuntu-theme package' do
      expect(chef_run).not_to purge_package('openstack-dashboard-ubuntu-theme')
    end
  end
end

# encoding: UTF-8
#
# Cookbook Name:: openstack-dashboard
# Recipe:: neutron-lbaas-dashboard
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

include_recipe 'openstack-dashboard::horizon'

django_path = node['openstack']['dashboard']['django_path']
policy_file_path = node['openstack']['dashboard']['policy_files_path']

pyenv_dir = '/usr/local/pyenv/neutron-fwaas-dashboard'
python_virtualenv pyenv_dir do
  pip_version '18.0'
  options :system
end

# Queens version is 1.3.0 (https://releases.openstack.org/queens/index.html)
neutron_fwaas_dashboard_version = '1.3.0'

python_package 'neutron-fwaas-dashboard' do
  version neutron_fwaas_dashboard_version
  notifies :run, 'execute[openstack-dashboard collectstatic]'
end

link '/usr/local/lib/python2.7/dist-packages/neutron_fwaas_dashboard' do
  to "#{pyenv_dir}/lib/python2.7/site-packages/neutron_fwaas_dashboard"
end

distinfo_dir = "neutron_fwaas_dashboard-#{neutron_fwaas_dashboard_version}.dist-info"

link "/usr/local/lib/python2.7/dist-packages/#{distinfo_dir}" do
  to "#{pyenv_dir}/lib/python2.7/site-packages/#{distinfo_dir}"
end

%w(_7010_project_firewalls_common _7011_project_firewalls_panel _7012_project_firewalls_v2_panel).each do |name|
  link "/usr/share/openstack-dashboard/openstack_dashboard/local/enabled/#{name}.py" do
    to "#{pyenv_dir}/lib/python2.7/site-packages/neutron_fwaas_dashboard/enabled/#{name}.py"
  end
end

file '/usr/local/lib/python2.7/dist-packages/neutron_fwaas_dashboard/__init__.py' do
  owner 'root'
  group 'root'
  mode '0644'
  content ''
end

remote_file "#{policy_file_path}/neutron-fwaas-policy.json" do
  source 'https://raw.githubusercontent.com/openstack/neutron-fwaas-dashboard/stable/queens/etc/neutron-fwaas-policy.json'
  owner 'root'
  mode 0o0644
#  notifies :run, 'execute[neutron-fwaas-dashboard compilemessages]'
#  notifies :run, 'execute[openstack-dashboard collectstatic]'
  notifies :restart, 'service[apache2]', :delayed
end

#execute 'neutron-fwaas-dashboard compilemessages' do
#  cwd django_path
#  environment 'PYTHONPATH' => "/etc/openstack-dashboard:#{django_path}:$PYTHONPATH"
#  command 'python manage.py compilemessages'
#  action :nothing
#end

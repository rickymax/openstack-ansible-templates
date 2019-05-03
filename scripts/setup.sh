#!/bin/bash
OPENSTACK_RC=/opt/spacex/scripts/openrc.sh
OPENSTACK_CLI_VIRTUALENV=/home/ubuntu/.virtualenvs/os_cli/bin/activate
ANSIBLE_VARS=/opt/spacex/playbooks/group_vars/all.yml
TERRAFORM_VARS=/opt/spacex/init-openstack/terraform.tfvars
ANSIBLE_BOSH_WORKSPACE=/opt/spacex/tf/bosh-init
ANSIBLE_CF_WORKSPACE=/opt/spacex/tf/cf-init

# export openstack password
sed -i "/read -sr OS_PASSWORD_INPUT/c OS_PASSWORD_INPUT=`bosh int $ANSIBLE_VARS --path /openstack_password`" $OPENSTACK_RC
sed -i "/OS_PASSWORD_INPUT=/c OS_PASSWORD_INPUT=`bosh int $ANSIBLE_VARS --path /openstack_password`" $OPENSTACK_RC
sed -i "/Please enter your OpenStack Password/d" $OPENSTACK_RC

source $OPENSTACK_RC
source $OPENSTACK_CLI_VIRTUALENV

# check is openrc.sh exists or not
if [ ! -f "$OPENSTACK_RC" ]; then
    echo "$OPENSTACK_RC not found."
    exit 1
fi

identity_endpoint=`grep 'http' $OPENSTACK_RC | awk -F 'OS_AUTH_URL=' '{print $NF}'`

net_id_mgmt=`openstack network show -f value -c id mgmt`
net_id_public=`openstack network show -f value -c id public`
router_id_router04=`openstack router show -f value -c id router04`

openstack_domain_name=`bosh int $ANSIBLE_VARS --path /openstack_domain_name`
openstack_user_name=`bosh int $ANSIBLE_VARS --path /openstack_user_name`
openstack_password=`bosh int $ANSIBLE_VARS --path /openstack_password`
openstack_tenant_name=`bosh int $ANSIBLE_VARS --path /openstack_tenant_name`
openstack_region_name=`bosh int $ANSIBLE_VARS --path /openstack_region_name`
ext_net_name=`bosh int $ANSIBLE_VARS --path /ext_net_name`
use_fuel_deploy=`bosh int $ANSIBLE_VARS --path /use_fuel_deploy`

dns=`bosh int $ANSIBLE_VARS --path /dns`

az1=`grep 'az1' $ANSIBLE_VARS | awk -F ': ' '{print $NF}'`
az2=`grep 'az2' $ANSIBLE_VARS | awk -F ': ' '{print $NF}'`
az3=`grep 'az3' $ANSIBLE_VARS | awk -F ': ' '{print $NF}'`

# ansible variables
echo identity_endpoint: $identity_endpoint >> $ANSIBLE_VARS
echo net_id_mgmt: $net_id_mgmt >> $ANSIBLE_VARS
echo net_id_public: $net_id_public >> $ANSIBLE_VARS

# terraform variables
echo auth_url = \"$identity_endpoint\" >> $TERRAFORM_VARS
echo domain_name = \"$openstack_domain_name\" >> $TERRAFORM_VARS
echo user_name = \"$openstack_user_name\" >> $TERRAFORM_VARS
echo password = \"$openstack_password\" >> $TERRAFORM_VARS
echo tenant_name = \"$openstack_tenant_name\" >> $TERRAFORM_VARS
echo region_name = \"$openstack_region_name\" >> $TERRAFORM_VARS
echo availability_zones = [\"$az1\",\"$az2\",\"$az3\"] >> $TERRAFORM_VARS
echo ext_net_name = \"$ext_net_name\" >> $TERRAFORM_VARS
echo ext_net_id = \"$net_id_public\" >> $TERRAFORM_VARS
echo use_fuel_deploy = \"$use_fuel_deploy\" >> $TERRAFORM_VARS
echo dns_nameservers = $dns >> $TERRAFORM_VARS
echo bosh_router_id = \"$router_id_router04\" >> $TERRAFORM_VARS

cp $TERRAFORM_VARS $ANSIBLE_BOSH_WORKSPACE
cp $TERRAFORM_VARS $ANSIBLE_CF_WORKSPACE

exit 0

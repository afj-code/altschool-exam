## Overview

This documentation provides a step-by-step guide for setting up a Vagrant environment with two VMs (master and slave) and deploying a web server and related components using Ansible.

### Prerequisites ###

Before starting, ensure you have the following:

- [Vagrant](https://www.vagrantup.com/)
- [VirtualBox](https://www.virtualbox.org/)
- [Git](https://git-scm.com/)
- [Ansible](https://www.ansible.com/)

## Step 1: Project Setup

**1.1 Create Project Directory**

- Create a project directory where all the configuration and script files will be stored. In this example, we use `/altschool_exam/`.

**1.2 Initialize Vagrant**

- Open a terminal and navigate to your project directory.
- Run `vagrant init` to initialize the project with a default Vagrantfile.

**1.3 Verify Directory Structure**

- Verify that your project directory structure looks like this:

  ```
  /altschool_exam/
  ├── Vagrantfile
  ```

## Step 2: Vagrant Configuration

**2.1 Custom Vagrant Configuration**

- Open the `Vagrantfile` using a text editor.
- Customize the Vagrant configuration according to your needs. In this example, two VMs (master and slave) are configured with specific settings.

![Screenshot](path_to_screenshot.png)

**2.2 Start VMs**

- Run `vagrant up` to start the VMs.

## Step 3: Master Node Setup

**3.1 SSH into the Master Node**

- Run `vagrant ssh master` to access the master node.

**3.2 Create Deployment Script**

- Create a deployment script (`deploy.sh`) that installs and configures various components on the master node.

![Screenshot](path_to_screenshot.png)

**3.3 Make Script Executable**

- Run `sudo chmod 755 deploy.sh` to make the script executable.

**3.4 Execute Deployment Script**

- Run `sh deploy.sh` to execute the deployment script.

## Step 4: Slave Node Setup

**4.1 Retrieve Slave Node IP Address**

- Run `vagrant ssh slave -c "ip a show enp0s8 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'" | tr -d '\r'` to get the IP address of the slave node.

**4.2 Copy Public Key to Slave**

- Run `vagrant ssh master -c "cat ~/.ssh/id_rsa.pub" | vagrant ssh slave -c "cat >> ~/.ssh/authorized_keys"` to copy the public key to the slave's authorized keys.

## Step 5: Ansible Configuration

**5.1 Create Inventory File**

- Create an inventory file (`host-inventory`) and add the IP address of the slave node.

![Screenshot](path_to_screenshot.png)

**5.2 Test Connection**

- Run `ansible all -i host-inventory -m ping` to verify the initial server connection.

**5.3 Write Ansible Playbook**

- Create an Ansible playbook (`myansible.yml`) to copy and execute the deployment script on the slave node.

![Screenshot](path_to_screenshot.png)

**5.4 Execute Ansible Playbook**

- Run `ansible-playbook myansible.yml -i host-inventory` to execute the Ansible playbook.

---

This documentation provides a structured guide for setting up your Vagrant environment and deploying software components on VMs using Ansible. You can include screenshots at each step to enhance the clarity of your documentation.

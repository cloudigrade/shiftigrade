***********
shiftigrade
***********

|license| |Build Status|


What is shiftigrade?
====================

**shiftigrade** is a set of deployment instructions for **cloudigrade** and friends.


Running cloudigrade
===================

If you'd like to run **cloudigrade** locally, follow the instructions below.

macOS dependencies
~~~~~~~~~~~~~~~~~~

We encourage macOS developers to use `homebrew <https://brew.sh/>`_ to install and manage these dependencies. The following commands should install everything you need:

.. code-block:: bash

    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    brew update
    brew tap tazjin/kontemplate https://github.com/tazjin/kontemplate
    brew install socat kontemplate
    # We need to install a specific version of docker since newer ones have a bug around the builtin proxy
    brew cask install https://raw.githubusercontent.com/caskroom/homebrew-cask/61f1d33be340e27b91f2a5c88da0496fc24904d3/Casks/docker.rb

After installing Docker, open it, navigate to Preferences -> General and uncheck ``Automatically check for updates`` if it is checked, then navigate to Preferences -> Daemon. There add ``172.30.0.0/16`` to the list of insecure registries, then click ``Apply and Restart``.

We currently use Openshift 3.7.X in production, so we need a matching openshift client.

.. code-block:: bash

    brew install https://raw.githubusercontent.com/Homebrew/homebrew-core/9d190ab350ce0b0d00d4968fed4b9fbe68a318ef/Formula/openshift-cli.rb
    brew pin openshift-cli

Linux dependencies
~~~~~~~~~~~~~~~~~~

We recommend developing on the latest version of Fedora. Follow the following commands to install the dependencies:

.. code-block:: bash

    # DNF Install AWS-CLI, Docker, and gettext
    sudo dnf install docker -y
    # Install an appropriate version of the OpenShift Client
    wget -O oc.tar.gz https://github.com/openshift/origin/releases/download/v3.7.2/openshift-origin-client-tools-v3.7.2-282e43f-linux-64bit.tar.gz
    tar -zxvf oc.tar.gz
    cp openshift-origin-client-tools-v3.7.2-282e43f-linux-64bit/oc ~/bin
    # Allow interaction with Docker without root
    sudo groupadd docker && sudo gpasswd -a ${USER} docker
    newgrp docker
    # Configure Insecure-Registries in Docker
    sudo cat > /etc/docker/daemon.json <<EOF
    {
       "insecure-registries": [
         "172.30.0.0/16"
       ]
    }
    EOF
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    # Configure firewalld
    sudo sysctl -w net.ipv4.ip_forward=1
    sudo firewall-cmd --permanent --new-zone dockerc
    sudo firewall-cmd --permanent --zone dockerc --add-source $(docker network inspect -f "{{range .IPAM.Config }}{{ .Subnet }}{{end}}" bridge)
    sudo firewall-cmd --permanent --zone dockerc --add-port 8443/tcp
    sudo firewall-cmd --permanent --zone dockerc --add-port 53/udp
    sudo firewall-cmd --permanent --zone dockerc --add-port 8053/udp
    sudo firewall-cmd --reload

Please also fetch the latest release of ``kontemplate`` from `here <https://github.com/tazjin/kontemplate/releases>`_ and place it somewhere where it's in your ``$PATH``.


Developer Environment
---------------------

Please check the `cloudigrade repo <https://github.com/cloudigrade/cloudigrade#developer-environment>`_ for an up to date list of dev requirements.


Configure AWS account credentials
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you haven't already, create an `Amazon Web Services <https://aws.amazon.com/>`_ account for **cloudigrade** to use for its AWS API calls. You will need the AWS access key ID, AWS secret access key, and region name where the account operates.

Use the AWS CLI to save that configuration to your local system:

.. code-block:: bash

    aws configure

You can verify that settings were stored correctly by checking the files it created in your ``~/.aws/`` directory.

AWS access for running **cloudigrade** inside Docker must be enabled via environment variables. Set the following variables in your local environment *before* you start running in Docker containers. Values for these variables can be found in the files in your ``~/.aws/`` directory.

-  ``AWS_ACCESS_KEY_ID``
-  ``AWS_SECRET_ACCESS_KEY``
-  ``AWS_DEFAULT_REGION``
-  ``AWS_SQS_ACCESS_KEY_ID``
-  ``AWS_SQS_SECRET_ACCESS_KEY``
-  ``AWS_SQS_REGION``
-  ``AWS_SQS_QUEUE_NAME_PREFIX``

The values for ``AWS_`` keys and region may be reused for the ``AWS_SQS_`` variables. ``AWS_SQS_QUEUE_NAME_PREFIX`` should be set to something unique to your environment like ``${USER}-``.


Common commands
===============


Running Locally in OpenShift
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To start the local cluster run the following:

.. code-block:: bash

    make oc-up

That will start a barebones OpenShift cluster that will persist configuration between restarts.

If you'd like to start the cluster, and deploy Cloudigrade along with supporting services run the following:

.. code-block:: bash

    # When deploying cloudigrade make sure you have AWS_ACCESS_KEY_ID and
    # AWS_SECRET_ACCESS_KEY set in your environment or the deployment will fail
    make oc-up-all

This will create the **ImageStream** to track **PostgreSQL:9.6**, deploy **PostgreSQL** locally, and finally use the templates to create all the objects necessary to deploy **cloudigrade** and the supporting services. There is a chance that the deployment for **cloudigrade** will fail due to the db not being ready before the mid-deployment hook pod is being run. Simply run the following command to trigger a redemployment for **cloudigrade**:

.. code-block:: bash

    oc rollout latest cloudigrade

To stop the local cluster run the following:

.. code-block:: bash

    make oc-down

Since all cluster information is preserved, you are then able to start the cluster back up with ``make oc-up`` and resume right where you have left off.

If you'd like to remove all your saved settings for your cluster, you can run the following:

.. code-block:: bash

    make oc-clean

There are also other make targets available to deploy just the queue, db, or the project by itself, along with installing the templates and the ImageStream object.


Testing
-------

If you want to verify that your templates are syntactically correct, you can run the following command:

.. code-block:: bash

        kontemplate template <your-config-file> | oc apply --dry-run -f -

This will template your files and run them through ``oc`` with the ``--dry-run`` flag. FWIW, I've seen ``--dry-run`` say everything was fine, but a real execution would fail, so please do also test your changes against a local cluster.

Troubleshooting the local OpenShift Cluster
-------------------------------------------

Occasionally when first deploying a cluster the PostgreSQL deployment will fail and crash loop, an easy way to resolve that is to kick off a new deployment of PostgreSQL with the following command:

.. code-block:: bash

    oc rollout latest dc/postgresql

If the cloudigrade deployment also failed because the database was not available when the migration midhook ran, you can retry that deployment with the following command:

.. code-block:: bash

    oc rollout retry dc/cloudigrade


.. |license| image:: https://img.shields.io/github/license/cloudigrade/shiftigrade.svg
   :target: https://github.com/cloudigrade/shiftigrade/blob/master/LICENSE
.. |Build Status| image:: https://travis-ci.org/cloudigrade/shiftigrade.svg?branch=master
   :target: https://travis-ci.org/cloudigrade/shiftigrade

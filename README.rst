***********
shiftigrade
***********

What is shiftigrade?
====================

**shiftigrade** is a set of deployment instructions for **cloudigrade** and friends.


Our Environments
~~~~~~~~~~~~~~~~

.. csv-table::
    :header: "Environments", "CORS", "Database", "URL", "Notes"

    "Production", "Strict", "RDS", "https://www.cloudigra.de/ or https://cloudigrade-prod.1b13.insights.openshiftapps.com/", "Deployed from tagged docker image in GitLab."
    "Stage", "Strict", "RDS", "https://stage.cloudigra.de/ or https://cloudigrade-stage.1b13.insights.openshiftapps.com/", "Deployed from tagged docker image in GitLab."
    "Test", "Strict", "RDS", "https://test.cloudigra.de/ or https://cloudigrade-test.1b13.insights.openshiftapps.com/", "Deployed from tagged docker image in GitLab."
    "Review", "Relaxed", "Ephemeral Postgres", "https://cloudireview-${BRANCH_NAME}.1b13.insights.openshiftapps.com/", "Built from branch inside the OSD cluster."
    "Local", "Relaxed", "Persistent Postgres", "http://127.0.0.1.nip.io/", "Built and run in local OCP cluster."

How do automated deployments work?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Production, Stage, and Test are considered our `production-like` environments.

Deployment to test starts as soon as anything in `cloudigrade` or `frontigrade` repos land on master, after tests pass and docker images are built, the docker image tagged with that commit sha will be deployed to test.

Deployment to stage, and in turn prod, is a little more manual. To deploy code to stage you have to create a tag in either the `cloudigrade` or `frontigrade` repo, depending on which one is being deployed. As before, CI will run, `tagged` docker images will be built and pushed to the registry, and a deployment to stage will be maid using the tagged image. Once the code in stage is ready to be promoted to production, simply press play on the `Deploy to Production` step in the respective GitLab CI pipeline page, this will kick off the deployment to production.

Review environments are a little different, they are created when a new branch is created and pushed to GitLab. They also do not use GitLab built images, but instead build images themselves in the OSD cluster where they are deployed. To stop an environment, simply activate the `Clean-Up-Review` job in the branch pipeline. If you are working on both `Cloudigrade` and `Frontigrade` and want them both to be able to interact with each other, make sure that your branches are called the same thing in both repos, as that dictates how they get deployed and named. As part of the cloudigrade review deployment, a user will be created with the login name `admin@example.com` and the password that is the same as the guest WiFI password.

The local environment is the one that runs on your own machine, deployed by you, using the instructions below.

There is also a second flavor of a review environment, one that deploys the master branch into the same conditions as a regular review branch. How do I get one of these environments? Two ways. First is via our handy `Cloudigrade Bot` that lives in our Slack. To deploy Cloudigrade, simply say `/cloudigrade run Review-Master <unique-name>`, eg `/cloudigrade run Review-Master taters`, and to deploy Frontigrade simply do `/frontigrade run Review-Master <unique-name>`, eg `/frontigrade run Review-Master taters`. Much like normal review environments, if both are named the same, both will work together. Don't be surprised if the bot seems quiet, if your message posts in chat, the job is started. Once the deployment is complete, the bot will respond with more information. To clean them up simply use `/[cloudigrade,frontigrade] run Clean-up-master <unique-name>`.

The other method of deploying is via `gitlab triggers <https://docs.gitlab.com/ee/ci/triggers/#triggering-a-pipeline>`_, make sure to specify the name of the deployment with the `CHAT_INPUT` variable name. If you'd like to clean up the deployment, just run the `Clean up master review` job from the pipeline page.

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

We currently use Openshift 3.9.X in production, so we need a matching openshift client.

.. code-block:: bash

    brew install openshift-cli

Linux dependencies
~~~~~~~~~~~~~~~~~~

We recommend developing on the latest version of Fedora. Follow the following commands to install the dependencies:

.. code-block:: bash

    # DNF Install AWS-CLI, Docker, and gettext
    sudo dnf install docker -y
    # Install an appropriate version of the OpenShift Client
    wget -O oc.tar.gz https://github.com/openshift/origin/releases/download/v3.9.0/openshift-origin-client-tools-v3.9.0-191fece-linux-64bit.tar.gz
    tar -zxvf oc.tar.gz
    cp openshift-origin-client-tools-v3.9.0-191fece-linux-64bit/oc ~/bin
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
-  ``DEPLOYMENT_PREFIX``
-  ``HOUNDIGRADE_ECS_CLUSTER_NAME``
-  ``HOUNDIGRADE_AWS_AUTOSCALING_GROUP_NAME``
-  ``HOUNDIGRADE_AWS_AVAILABILITY_ZONE``
-  ``CLOUDTRAIL_EVENT_URL``

The values for ``AWS_`` keys and region may be reused for the ``AWS_SQS_`` variables. ``DEPLOYMENT_PREFIX`` should be set to something unique to your environment like ``${USER}-``.

Configuring Shiftigrade Test env with PostgreSql RDS
====================================================
.. note:: The PostgreSql instance for the test environment has been set up in aws rds.

#. export the following as environment variables:
    - export DJANGO_DATABASE_USER=$YOUR-USER
    - export DJANGO_DATABASE_PASSWORD=$YOUR-PASSWORD

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

This will deploy **PostgreSQL** locally, and finally use the templates to create all the objects necessary to deploy **cloudigrade** and the supporting services. There is a chance that the deployment for **cloudigrade** will fail due to the db not being ready before the mid-deployment hook pod is being run. Simply run the following command to trigger a redemployment for **cloudigrade**:

.. code-block:: bash

    oc rollout latest cloudigrade

To stop the local cluster run the following:

.. code-block:: bash

    make oc-down

Since all cluster information is preserved, you are then able to start the cluster back up with ``make oc-up`` and resume right where you have left off.

If you'd like to remove all your saved settings for your cluster, you can run the following:

.. code-block:: bash

    make oc-clean

There are also other make targets available to deploy just the queue, db, or the project by itself, along with installing the templates.


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

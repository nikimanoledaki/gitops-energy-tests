# Environment Setup
To setup the test environment, i.e. creating a Minikube cluster, installing the tools, and running a specific test scenario, run the environment-setup.sh script and provide the required parameters.
```bash
chmod +x ./path/to/environment-setup.sh
./path/to/environment-setup.sh ./path/to/kepler/ "GitOps tool" ./path/to/test/scenario.sh
```
If you want to install either Argo CD or Flux CD, you can provide the tool name as a second parameter.

:warning: In order to run the scripts for different scenarios, you must authenticate with your GitHub account as the scripts involve forking repositories and creating a new one.
:warning: In order to install Flux, create a GitHub personal access token and export it as an environment variable.

Examples:
```bash
chmod +x ./path/to/environment-setup.sh
# To install both, Argo CD and Flux CD, and run experiment scenario 1a
./path/to/environment-setup.sh ./path/to/kepler/ "" path/to/experiment-scenario-1a.sh
# To install Argo CD only and run experiment scenario 3
./path/to/environment-setup.sh ./path/to/kepler/ "argo" path/to/experiment-scenario-3.sh
# To install Argo CD only without running any experiment automatically
./path/to/environment-setup.sh ./path/to/kepler/ "argo"
```

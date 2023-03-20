# Energy Benchmarking Experimental Setup for GitOps
This GitHub repository contains energy-related experimental benchmark tests for different GitOps tools and patterns with Kepler. 

## Motivation
GitOps has rapidly gained attraction as a promising software delivery approach that can bring numerous benefits, including faster deployment times, increased reliability, and improved scalability. However, there is currently limited research on the energy consumption of GitOps architectures and tools.

This repository aims to fill this gap by collecting energy-related metrics such as energy consumption that can help to evaluate the energy efficiency of GitOps solutions under various experimental conditions and to identify ways to reduce their environmental impact.

## Contents
The repository includes the following contents:

- docs: This directory contains documentation and instructions on how to run the experiments.
- experiments: This directory contains experimental scripts that can be used to run the benchmark tests.
- images: This directory contains screenshots and other images that are used in this repository.

## Requirements
To run the experimental benchmark tests in this repository, you will need the following:

- [Kubernetes cluster](https://github.com/kubernetes/minikube)
- [Docker](https://docs.docker.com/engine/install/ubuntu)
- [Kepler](https://github.com/sustainable-computing-io/kepler)
- GitOps tools such [Argo CD](https://github.com/argoproj/argo-cd) or [Flux CD](https://github.com/fluxcd/flux2)

Detailed installation and configuration instructions for these tools are provided in the docs directory.

## Running the Experiments
To run the benchmark tests, follow these steps:

- Install the required tools and configure the environment as described in the docs directory.
- Clone this repository to your local machine.
- Navigate to the experiments directory.
- Run the experimental scripts using the commands provided in the docs directory.

## License
This repository is licensed under the Apache-2.0 License. See the [LICENSE](LICENSE) file for more details.

## Acknowledgments
This repository was inspired by the work of the GitOps & Environmental Sustainability Subgroup. We would like to thank the members of the community for their contributions and support.

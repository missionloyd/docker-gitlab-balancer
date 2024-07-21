<p align="center">
    <h1 align="center">GitLab Load Balancer + Runner</h1>
</p>
<p align="center">
	<a href="https://skillicons.dev">
		<img src="https://skillicons.dev/icons?i=bash,gitlab,nginx,docker&theme=dark">
	</a></p>

<br><!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary><br>

- [ Overview](#-overview)
- [ Features](#-features)
- [ Repository Structure](#-repository-structure)
- [ Modules](#-modules)
- [ Getting Started](#-getting-started)
  - [ Installation](#-installation)
  - [ Usage](#-usage)
  - [ Tests](#-tests)
- [ Project Roadmap](#-project-roadmap)
- [ Contributing](#-contributing)
- [ License](#-license)
- [ Acknowledgments](#-acknowledgments)
</details>
<hr>

##  Overview

This project orchestrates a robust infrastructure for load balancing within a Docker environment. By leveraging Nginx configurations and SSL/TLS encryption, it optimizes HTTP/HTTPS traffic handling and enhances secure communication among service endpoints. The project streamlines the setup of GitLab Runners and ensures efficient traffic routing, making it instrumental for maintaining performance and security in multi-project environments.

---

##  Features

|    |   Feature         | Description |
|----|-------------------|---------------------------------------------------------------|
| ⚙️  | **Architecture**  | Orchestrated by Docker containers using Nginx for load balancing, with service endpoints defined in JSON format. Enhanced by SSL/TLS settings for secure communication. Module-based setup for scalability. |
| 🔩 | **Code Quality**  | Maintains a structured approach with shell scripts for setup and configuration, ensuring consistent code style and readability. Encourages modularity and reusability through script functions. |
| 📄 | **Documentation** | Detailed documentation provided for setup and configuration scripts, Nginx configurations, and SSL/TLS parameters. Contains explanations and usage guidelines for each script and configuration file. |
| 🔌 | **Integrations**  | Dependencies on Docker, Nginx, and shell scripts for orchestration, load balancing, and setup. Utilizes JSON for defining service endpoints and SSL certificates for secure communication. |
| 🧩 | **Modularity**    | Script-based modular approach enables code reusability for repetitive tasks like SSL certificate generation, Nginx server block creation, and dynamic configuration updates. Each module serves a specific function for scalability and maintainability. |
| ⚡️  | **Performance**   | Optimized Nginx configurations for efficient HTTP traffic handling. SSL/TLS parameters enhance security without compromising performance. Docker containers provide a lightweight and scalable infrastructure for resource utilization. |
| 🛡️ | **Security**      | Implements SSL certificates, encryption ciphers, and secure communication protocols to safeguard data integrity and confidentiality. Secure configurations for Nginx, SSL, and proxy handling ensure data protection and secure traffic routing. |
| 📦 | **Dependencies**  | Dependencies include Docker, Nginx, and shell scripts for setup and configuration. External libraries might be used for SSL/TLS support, but not explicitly mentioned in the provided details. |
| 🚀 | **Scalability**   | Modular architecture with Docker containers and Nginx configuration enables horizontal scalability. Capability to add new services, update configurations, and handle increased traffic load efficiently within the balancer architecture. |

---

##  Repository Structure

```sh
└── ./
    ├── README.md
    ├── balancer
    │   ├── Dockerfile
    │   ├── entrypoint.sh
    │   ├── modules
    │   │   ├── create_nginx_server_block.sh
    │   │   ├── generate_certificate.sh
    │   │   ├── generate_certificates_and_nginx_blocks.sh
    │   │   ├── generate_dh_params.sh
    │   │   └── initialize_project_conf.sh
    │   ├── nginx.conf
    │   ├── proxy-params.conf
    │   └── ssl-params.conf
    ├── run_balancer.sh
    ├── run_runner.sh
    └── services
        └── service.exmaple.json
```

---

##  Modules

<details closed><summary>.</summary>

| File                               | Summary                                                                                                                                                                                                                                                                                                              |
| ---                                | ---                                                                                                                                                                                                                                                                                                                  |
| [run_runner.sh](run_runner.sh)     | Loads environment variables, creates Docker network if nonexistent, removes existing GitLab Runner container, and initiates a new GitLab Runner container with specific configurations within the GitLab balancer architecture.                                                                                      |
| [run_balancer.sh](run_balancer.sh) | Executes the Balancer container setup by loading environment variables, checking network existence, creating necessary files, building the image, and running the container with specified configurations for port mapping, volumes, and environment variables to ensure proper functioning within the architecture. |

</details>

<details closed><summary>services</summary>

| File                                                  | Summary                                                                                                                                                                                                    |
| ---                                                   | ---                                                                                                                                                                                                        |
| [service.exmaple.json](services/service.exmaple.json) | Defines service endpoints for dev, prev, and main projects in JSON format. Identifies project names and respective port numbers for communication within the Docker-based service balancer infrastructure. |

</details>

<details closed><summary>balancer</summary>

| File                                            | Summary                                                                                                                                                                                                                                                                  |
| ---                                             | ---                                                                                                                                                                                                                                                                      |
| [nginx.conf](balancer/nginx.conf)               | Defines Nginx server configuration for optimized HTTP traffic handling. Specifies user, worker processes, error logging, connection limits, log formats, static content delivery optimization, and virtual host settings.                                                |
| [ssl-params.conf](balancer/ssl-params.conf)     | Defines SSL parameters for secure communication in the balancer module. Specifies server settings like encryption ciphers, protocols, session caching, and headers. Optimizes SSL/TLS performance with Real-IP header, resolver settings, and Strict-Transport-Security. |
| [proxy-params.conf](balancer/proxy-params.conf) | Defines proxy parameters for load balancing, including timeouts, headers, and error handling. Enhances backend communication while managing large requests. Promotes secure and efficient traffic routing in the projects architecture.                                  |
| [Dockerfile](balancer/Dockerfile)               | Configures a custom Nginx server within a Docker container for load balancing. Installs required packages, sets time zone, removes default configs, copies custom files, exposes ports, and makes scripts executable.                                                    |
| [entrypoint.sh](balancer/entrypoint.sh)         | Establishes service mappings, initializes NGINX configuration, and ensures DNS resolution. Monitors changes, updates NGINX settings, and reloads NGINX. Mitigates DNS failures and enforces fallbacks.                                                                   |

</details>

<details closed><summary>balancer.modules</summary>

| File                                                                                                    | Summary                                                                                                                                                                                                                               |
| ---                                                                                                     | ---                                                                                                                                                                                                                                   |
| [generate_certificate.sh](balancer/modules/generate_certificate.sh)                                     | Generates SSL certificates for domains ensuring secure communication. Uses OpenSSL to create private keys, CSRs, and signed certificates with specified validity. Supports multiple domain extensions and email addresses.            |
| [generate_dh_params.sh](balancer/modules/generate_dh_params.sh)                                         | Generates DHE parameters when generating certificates for domains in the parent repositorys load balancer setup. Triggered only if certificates are needed, enhancing security during SSL/TLS connections.                            |
| [generate_certificates_and_nginx_blocks.sh](balancer/modules/generate_certificates_and_nginx_blocks.sh) | Generates SSL certificates and configures Nginx server blocks for each service in the repository, enhancing security and scalability.                                                                                                 |
| [initialize_project_conf.sh](balancer/modules/initialize_project_conf.sh)                               | Generates dynamic NGINX configuration to route traffic based on defined services and ports. Initializes project.conf with upstream server definitions and hostname mappings for load balancing, along with HTTP to HTTPS redirection. |
| [create_nginx_server_block.sh](balancer/modules/create_nginx_server_block.sh)                           | Implements creating an NGINX server block for a given domain within the balancer module. Configures SSL settings, proxy, and server configurations based on the provided domain.                                                      |

</details>

---

##  Getting Started

**Minimum System Requirements:**

* **Docker**: `20.10.21`
* **Docker Compose**: `v2.13.0`

###  Usage
1. <h4><code>Docker</code> should be running locally.</h4>
2. <h4>Create two files: <code>./.env.local</code> and <code>./services/service.json</code>.</h4>
3. <h4>Make sure to point the container names to a DNS configured subdomain and PORT, i.e.
  - <code>"my-container-name": "sub-domain:exposed-container-port"</code>
  - <code>"main-project": "main-project:9445"</code>.</h4>

<h4>From <code>source</code></h4>

> 1. Spin up the runner first:
> ```console
> $ bash run_runner.sh
> ```
>
> 2. Next, spin up the balancer (you may need to reload if you ran this before spinning up associated staging containers):
> ```console
> $ bash run_balancer.sh
> ```

##  Acknowledgments

- Created by Luke Macy

[**Return**](#-overview)

---

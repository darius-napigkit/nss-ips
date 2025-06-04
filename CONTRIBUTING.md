# Contributing to NSS IPS Repository

Thank you for considering contributing to our infrastructure codebase! Given the critical nature of infrastructure, we have a robust process for changes.

Before you start, please take a moment to review these guidelines.

## Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project, you agree to abide by its terms.

## How Can I Contribute?

### Reporting Issues

If you find an issue with our infrastructure (e.g., a service outage, an incorrect configuration, or a bug in a Terraform module), please open an issue on our GitHub Issues page. Before opening a new issue, please check if a similar issue has already been reported.

When reporting an issue, please include:
- A clear and concise description of the problem.
- Steps to reproduce the behavior (if applicable).
- Expected behavior vs. actual behavior.
- Relevant logs or error messages.
- Environment details (e.g., development, production, specific service).

### Suggesting Enhancements

We welcome suggestions for new infrastructure features or improvements. You can open an issue on our GitHub Issues page with the tag "enhancement".

When suggesting an enhancement, please include:
- A clear and concise description of the enhancement.
- The problem it solves or the benefit it provides.
- Any potential architectural considerations or implications.

### Pull Request Process

Our infrastructure changes follow a strict pull request workflow to ensure stability and prevent regressions.

1.  **Fork the repository:** Click the "Fork" button at the top right of the repository page.
2.  **Clone your forked repository:**
    ```bash
    git clone [https://github.com/darius-napigkit/nss-ips.git](https://github.com/darius-napigkit/nss-ips.git)
    cd nss-ips
    ```
3.  **Create a new branch:**
    ```bash
    git checkout -b feature/add-new-service
    ```
    (For bug fixes, use `bugfix/fix-vpn-config`)
4.  **Make your changes:** Implement your infrastructure changes (e.g., modify `.tf` files, update Ansible playbooks).
5.  **Validate your changes locally:**
    * **Terraform:**
        ```bash
        terraform fmt         # Format your code
        terraform validate    # Validate HCL syntax
        terraform plan        # Review the execution plan carefully
        ```
    * **Ansible:**
        ```bash
        ansible-lint          # Lint your playbooks
        ansible-playbook --syntax-check playbooks/your_playbook.yml
        ```
6.  **Test your changes:**
    * Whenever possible, test your changes in a **dedicated development/staging environment** first. Do not apply untested changes directly to production.
    * Consider using tools like [Terratest](https://terratest.gruntwork.io/) for automated testing of Terraform modules.
7.  **Commit your changes:** Write a clear and concise commit message.
    ```bash
    git commit -m "feat: Provision new S3 bucket for logs"
    # Or "fix: Correct security group rule for web servers"
    ```
    Please follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) for commit messages.
8.  **Push to your branch:**
    ```bash
    git push origin feature/add-new-service
    ```
9.  **Open a Pull Request:** Go to your forked repository on GitHub and click "Compare & pull request".
    * Provide a clear title and detailed description for your pull request, explaining the changes and their impact.
    * Reference any related issues.
    * **Crucially, the CI/CD pipeline will automatically run `terraform plan` (or equivalent) and post the output to the PR.** Review this output carefully for unintended changes.
    * Await review and approval from at least one team member.
    * Once approved, your changes will be merged and deployed via our CI/CD pipeline according to our deployment process.

### Code Style and Best Practices

-   Adhere to our `.editorconfig` settings for consistent formatting.
-   Follow best practices for your chosen IaC tools (e.g., Terraform best practices for module structure, variable usage).
-   Ensure resources are tagged appropriately for cost allocation and management.
-   Avoid hardcoding sensitive information; use secrets management solutions (e.g., AWS Secrets Manager, HashiCorp Vault).
-   Keep pull requests focused on a single logical change.

## Development Setup

No special development setup is usually required beyond installing the IaC tools (Terraform, Ansible, etc.) and configuring your cloud provider credentials.

## Asking Questions

If you have questions about our infrastructure, development setup, or contribution process, please open an issue or reach out to the DevOps team on [e.g., Slack channel, Teams channel].

Thank you for helping us maintain a robust and reliable infrastructure!

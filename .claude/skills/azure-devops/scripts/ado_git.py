#!/usr/bin/env python3
"""
Azure DevOps Git Operations Module

Repository and pull request operations.
"""

from typing import Optional, List, Any


class GitOperations:
    """Git operations for repositories and pull requests"""

    def __init__(self, client):
        """
        Initialize GitOperations

        Args:
            client: AzureDevOpsClient instance
        """
        self.client = client
        self.git_client = client.git_client

    def get_repositories(self, project: Optional[str] = None) -> List[Any]:
        """
        Get all repositories in a project

        Args:
            project: Project name

        Returns:
            List of repository objects
        """
        project = self.client.resolve_project(project)

        return self.git_client.get_repositories(project=project)

    def get_repository(
        self, repository: str, project: Optional[str] = None
    ) -> Any:
        """
        Get repository by name or ID

        Args:
            repository: Repository name or ID
            project: Project name

        Returns:
            Repository object
        """
        project = self.client.resolve_project(project)

        return self.git_client.get_repository(
            repository_id=repository, project=project
        )

    def get_pull_requests(
        self,
        repository: str,
        project: Optional[str] = None,
        status: Optional[str] = None,
    ) -> List[Any]:
        """
        Get pull requests for a repository

        Args:
            repository: Repository name or ID
            project: Project name
            status: Filter by status (active, completed, abandoned, all)

        Returns:
            List of pull request objects

        Example:
            prs = git_ops.get_pull_requests("my-repo", status="active")
            for pr in prs:
                print(f"PR #{pr.pull_request_id}: {pr.title}")
        """
        from azure.devops.v7_1.git.models import GitPullRequestSearchCriteria

        project = self.client.resolve_project(project)

        search_criteria = GitPullRequestSearchCriteria()
        if status:
            search_criteria.status = status

        # Page through results: the API returns at most ~100 PRs per call, so a
        # busy repo (especially status="completed"/"all") would otherwise be
        # silently truncated. Walk skip/top until a short page comes back.
        page_size = 100
        skip = 0
        all_prs: List[Any] = []
        while True:
            page = self.git_client.get_pull_requests(
                repository_id=repository,
                search_criteria=search_criteria,
                project=project,
                top=page_size,
                skip=skip,
            )
            if not page:
                break
            all_prs.extend(page)
            if len(page) < page_size:
                break
            skip += page_size

        return all_prs

    def create_pull_request(
        self,
        repository: str,
        source_branch: str,
        target_branch: str,
        title: str,
        description: str = "",
        project: Optional[str] = None,
    ) -> Any:
        """
        Create a new pull request

        Args:
            repository: Repository name or ID
            source_branch: Source branch name (without refs/heads/)
            target_branch: Target branch name (without refs/heads/)
            title: PR title
            description: PR description
            project: Project name

        Returns:
            Created pull request object

        Example:
            pr = git_ops.create_pull_request(
                "my-repo",
                "feature/new-feature",
                "main",
                "Add new feature",
                "This PR implements..."
            )
        """
        from azure.devops.v7_1.git.models import GitPullRequest

        project = self.client.resolve_project(project)

        # Create PR object
        pr = GitPullRequest()
        pr.source_ref_name = f"refs/heads/{source_branch}"
        pr.target_ref_name = f"refs/heads/{target_branch}"
        pr.title = title
        pr.description = description

        return self.git_client.create_pull_request(
            git_pull_request_to_create=pr,
            repository_id=repository,
            project=project,
        )

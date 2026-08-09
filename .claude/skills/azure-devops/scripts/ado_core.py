#!/usr/bin/env python3
"""
Azure DevOps Core Operations Module

Projects and Teams operations.
"""

from typing import Optional, List, Any


class CoreOperations:
    """Core operations for projects and teams"""

    def __init__(self, client):
        """
        Initialize CoreOperations

        Args:
            client: AzureDevOpsClient instance
        """
        self.client = client
        self.core_client = client.core_client

    def get_projects(self) -> List[Any]:
        """
        Get all projects in the organization

        Returns:
            List of project objects

        Example:
            projects = core_ops.get_projects()
            for project in projects:
                print(f"{project.name} - {project.description}")
        """
        projects = []
        continuation_token = None

        while True:
            response = self.core_client.get_projects(continuation_token=continuation_token)

            # Handle both list response and object with .value attribute
            if isinstance(response, list):
                projects.extend(response)
                break  # List responses don't have continuation tokens
            else:
                projects.extend(response.value)
                if not response.continuation_token:
                    break
                continuation_token = response.continuation_token

        return projects

    def get_project(self, project: Optional[str] = None) -> Any:
        """
        Get project details

        Args:
            project: Project name or ID (uses default if not specified)

        Returns:
            Project object
        """
        project = self.client.resolve_project(project)

        return self.core_client.get_project(project)

    def get_teams(self, project: Optional[str] = None) -> List[Any]:
        """
        Get all teams in a project

        Args:
            project: Project name or ID

        Returns:
            List of team objects
        """
        project = self.client.resolve_project(project)

        # Page through teams ($top defaults to 100) so large projects aren't
        # silently truncated — matching how get_projects handles its paging.
        teams = []
        page_size = 100
        skip = 0
        while True:
            page = self.core_client.get_teams(project, top=page_size, skip=skip)
            if not page:
                break
            teams.extend(page)
            if len(page) < page_size:
                break
            skip += page_size

        return teams

    def get_work_item_types(self, project: Optional[str] = None) -> List[Any]:
        """
        Get all work item types in a project

        Args:
            project: Project name or ID

        Returns:
            List of work item type objects

        Example:
            types = core_ops.get_work_item_types()
            for wit in types:
                print(f"{wit.name} - {wit.description}")
        """
        project = self.client.resolve_project(project)

        return self.client.work_item_tracking_client.get_work_item_types(project)

    def get_work_item_type_categories(self, project: Optional[str] = None) -> List[Any]:
        """
        Get all work item type categories in a project

        Args:
            project: Project name or ID

        Returns:
            List of category objects

        Example:
            categories = core_ops.get_work_item_type_categories()
            for cat in categories:
                print(f"{cat.name}: {cat.default_work_item_type.name}")
        """
        project = self.client.resolve_project(project)

        return self.client.work_item_tracking_client.get_work_item_type_categories(project)

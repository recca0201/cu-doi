#!/usr/bin/env python3
"""
Azure DevOps Client Module

Base connection and client initialization for Azure DevOps operations.
"""

from pathlib import Path
from typing import Optional

from azure.devops.connection import Connection
from msrest.authentication import BasicAuthentication

# Support both direct script execution and package import
try:
    from .ado_utils import get_env_config, build_organization_url
except ImportError:
    from ado_utils import get_env_config, build_organization_url


class AzureDevOpsClient:
    """Base Azure DevOps client with connection and client initialization"""

    def __init__(
        self,
        organization: Optional[str] = None,
        pat: Optional[str] = None,
        project: Optional[str] = None,
        team: Optional[str] = None,
        area_path: Optional[str] = None,
    ):
        """
        Initialize Azure DevOps connection

        Args:
            organization: Organization name (or full URL)
            pat: Personal Access Token
            project: Default project name
            team: Default team name
            area_path: Default area path
        """
        # Load configuration from environment
        env_file = Path(__file__).parent.parent / ".env"
        self.organization, self.pat, self.project, self.team, self.area_path = get_env_config(
            organization, pat, project, team, area_path, env_file if env_file.exists() else None
        )

        # Build organization URL
        self.organization_url = build_organization_url(self.organization)

        # Create connection
        credentials = BasicAuthentication("", self.pat)
        self.connection = Connection(base_url=self.organization_url, creds=credentials)

        # Initialize commonly used clients
        self.core_client = self.connection.clients.get_core_client()
        self.git_client = self.connection.clients.get_git_client()
        self.work_item_tracking_client = self.connection.clients.get_work_item_tracking_client()
        self.work_client = self.connection.clients.get_work_client()

    def resolve_project(self, project: Optional[str] = None) -> str:
        """
        Return the given project, falling back to the configured default.

        Centralizes the "use the passed project or the .env default, else error"
        check that nearly every operation needs, with one helpful message.

        Raises:
            ValueError: if neither an explicit project nor a default is set.
        """
        project = project or self.project
        if not project:
            raise ValueError(
                "Project name or ID required: pass project=... or set "
                "AZURE_DEVOPS_PROJECT in your .env"
            )
        return project

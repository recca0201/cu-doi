#!/usr/bin/env python3
"""
Azure DevOps Helper - Using Official azure-devops Library

This module provides a unified interface for Azure DevOps operations
by composing specialized operation modules.

Installation:
    pip install azure-devops

Documentation:
    https://github.com/microsoft/azure-devops-python-api
"""

import sys
from typing import Optional

# Support both direct script execution and package import
try:
    from .ado_client import AzureDevOpsClient
    from .ado_core import CoreOperations
    from .ado_work_items import WorkItemOperations
    from .ado_git import GitOperations
    from .ado_export import ExportOperations
except ImportError:
    from ado_client import AzureDevOpsClient
    from ado_core import CoreOperations
    from ado_work_items import WorkItemOperations
    from ado_git import GitOperations
    from ado_export import ExportOperations


class AzureDevOpsHelper:
    """
    Unified Azure DevOps helper composing all operation modules

    This class provides a single interface for all Azure DevOps operations
    by delegating to specialized modules.
    """

    def __init__(
        self,
        organization: Optional[str] = None,
        pat: Optional[str] = None,
        project: Optional[str] = None,
        team: Optional[str] = None,
        area_path: Optional[str] = None,
    ):
        """
        Initialize Azure DevOps helper with all operations

        Args:
            organization: Organization name (or full URL)
            pat: Personal Access Token
            project: Default project name
            team: Default team name
            area_path: Default area path
        """
        # Initialize base client
        self.client = AzureDevOpsClient(organization, pat, project, team, area_path)

        # Expose client properties for backward compatibility
        self.organization = self.client.organization
        self.pat = self.client.pat
        self.project = self.client.project
        self.team = self.client.team
        self.area_path = self.client.area_path
        self.organization_url = self.client.organization_url
        self.connection = self.client.connection
        self.core_client = self.client.core_client
        self.git_client = self.client.git_client
        self.work_item_tracking_client = self.client.work_item_tracking_client
        self.work_client = self.client.work_client

        # Initialize operation modules
        self._core_ops = CoreOperations(self.client)
        self._work_item_ops = WorkItemOperations(self.client)
        self._git_ops = GitOperations(self.client)
        self._export_ops = ExportOperations(self._work_item_ops)

    # ============================================================================
    # CORE OPERATIONS - Projects and Teams
    # ============================================================================

    def get_projects(self):
        """Get all projects in the organization"""
        return self._core_ops.get_projects()

    def get_project(self, project: Optional[str] = None):
        """Get project details"""
        return self._core_ops.get_project(project)

    def get_teams(self, project: Optional[str] = None):
        """Get all teams in a project"""
        return self._core_ops.get_teams(project)

    def get_work_item_types(self, project: Optional[str] = None):
        """Get all work item types in a project"""
        return self._core_ops.get_work_item_types(project)

    def get_work_item_type_categories(self, project: Optional[str] = None):
        """Get all work item type categories in a project"""
        return self._core_ops.get_work_item_type_categories(project)

    # ============================================================================
    # WORK ITEM TRACKING
    # ============================================================================

    def get_work_item(self, work_item_id: int, fields: Optional[list] = None):
        """Get work item by ID"""
        return self._work_item_ops.get_work_item(work_item_id, fields)

    def get_child_work_items(
        self,
        parent_id: int,
        work_item_type: Optional[str] = None,
    ):
        """Get all child work items of a parent work item"""
        return self._work_item_ops.get_child_work_items(parent_id, work_item_type)

    def create_work_item(
        self,
        work_item_type: str,
        title: str,
        project: Optional[str] = None,
        parent_id: Optional[int] = None,
        **fields
    ):
        """Create a new work item (optionally as a child of parent_id)"""
        return self._work_item_ops.create_work_item(
            work_item_type, title, project, parent_id=parent_id, **fields
        )

    def update_work_item(self, work_item_id: int, **fields):
        """Update work item fields"""
        return self._work_item_ops.update_work_item(work_item_id, **fields)

    def delete_work_item(
        self,
        work_item_id: int,
        destroy: bool = False,
        project: Optional[str] = None,
    ):
        """Delete a work item (recycle bin by default; destroy=True is permanent)"""
        return self._work_item_ops.delete_work_item(work_item_id, destroy, project)

    def link_work_items(
        self,
        source_id: int,
        target_id: int,
        link_type: str = "related",
        comment: str = "",
    ):
        """Link two work items (link_type: parent/child/related/predecessor/successor/...)"""
        return self._work_item_ops.link_work_items(source_id, target_id, link_type, comment)

    def add_comment(self, work_item_id: int, text: str, project: Optional[str] = None):
        """Add a comment to a work item's discussion"""
        return self._work_item_ops.add_comment(work_item_id, text, project)

    def get_work_item_revisions(self, work_item_id: int, top: Optional[int] = None):
        """Get the revision history of a work item"""
        return self._work_item_ops.get_work_item_revisions(work_item_id, top)

    def query_work_items(self, wiql: str, project: Optional[str] = None):
        """Query work items using WIQL"""
        return self._work_item_ops.query_work_items(wiql, project)

    def get_sprint_items(
        self,
        iteration_path: str,
        project: Optional[str] = None,
        work_item_type: Optional[str] = None,
        exclude_ritual_enablers: bool = False,
    ):
        """Get all work items in a sprint/iteration"""
        return self._work_item_ops.get_sprint_items(
            iteration_path, project, work_item_type, exclude_ritual_enablers
        )

    def get_current_sprint(self, team: str, project: Optional[str] = None):
        """Get the current sprint/iteration for a team"""
        return self._work_item_ops.get_current_sprint(team, project)

    def get_current_sprint_user_stories(
        self,
        team: str,
        project: Optional[str] = None,
        include_child_items: bool = False,
        exclude_ritual_enablers: bool = False,
    ):
        """Get all user stories in the current sprint for a team"""
        return self._work_item_ops.get_current_sprint_user_stories(
            team, project, include_child_items, exclude_ritual_enablers
        )

    def export_work_items_to_markdown(
        self,
        output_file: Optional[str] = None,
        project: Optional[str] = None,
        team: Optional[str] = None,
        sprint_path: Optional[str] = None,
        work_item_ids: Optional[list] = None,
        title: Optional[str] = None,
    ):
        """Export work items to markdown file"""
        return self._export_ops.export_work_items_to_markdown(
            output_file, project, team, sprint_path, work_item_ids, title
        )

    # ============================================================================
    # AIDLC-SPECIFIC METHODS (Bolt terminology)
    # ============================================================================

    def get_current_bolt(self, team: str, project: Optional[str] = None):
        """Get the current bolt (AIDLC term for sprint) for a team"""
        return self._work_item_ops.get_current_bolt(team, project)

    def get_bolt_items(
        self,
        bolt_name: str,
        team: str,
        project: Optional[str] = None,
        work_item_type: Optional[str] = None,
        exclude_ritual_enablers: bool = True,
    ):
        """Get all work items in a specific bolt by name"""
        return self._work_item_ops.get_bolt_items(
            bolt_name, team, project, work_item_type, exclude_ritual_enablers
        )

    def get_current_bolt_items(
        self,
        team: str,
        project: Optional[str] = None,
        work_item_type: Optional[str] = None,
        exclude_ritual_enablers: bool = True,
    ):
        """Get all work items in the current bolt"""
        return self._work_item_ops.get_current_bolt_items(
            team, project, work_item_type, exclude_ritual_enablers
        )

    # ============================================================================
    # GIT OPERATIONS - Repositories
    # ============================================================================

    def get_repositories(self, project: Optional[str] = None):
        """Get all repositories in a project"""
        return self._git_ops.get_repositories(project)

    def get_repository(self, repository: str, project: Optional[str] = None):
        """Get repository by name or ID"""
        return self._git_ops.get_repository(repository, project)

    # ============================================================================
    # GIT OPERATIONS - Pull Requests
    # ============================================================================

    def get_pull_requests(
        self,
        repository: str,
        project: Optional[str] = None,
        status: Optional[str] = None,
    ):
        """Get pull requests for a repository"""
        return self._git_ops.get_pull_requests(repository, project, status)

    def create_pull_request(
        self,
        repository: str,
        source_branch: str,
        target_branch: str,
        title: str,
        description: str = "",
        project: Optional[str] = None,
    ):
        """Create a new pull request"""
        return self._git_ops.create_pull_request(
            repository, source_branch, target_branch, title, description, project
        )


def main():
    """CLI interface for testing"""
    import argparse
    import json

    # Special handling for export_sprint command to preserve flag arguments
    if len(sys.argv) > 1 and sys.argv[1] == "export_sprint":
        try:
            helper = AzureDevOpsHelper()

            # Create parser for export_sprint subcommand
            export_parser = argparse.ArgumentParser(description="Export work items to markdown")
            export_parser.add_argument("command", help="Command name (export_sprint)")
            export_parser.add_argument("--team", help="Team name for current sprint export")
            export_parser.add_argument("--sprint-path", "--sprint", dest="sprint_path", help="Sprint path (e.g., 'AI Initiative\\Sprint 15')")
            export_parser.add_argument("--ids", nargs='+', type=int, help="List of work item IDs")
            export_parser.add_argument("--project", help="Project name (defaults to .env)")
            export_parser.add_argument("--output", help="Output file path")
            export_parser.add_argument("--title", help="Custom title for markdown")

            # Parse arguments
            export_args = export_parser.parse_args()

            # Use default team if not provided
            team = export_args.team or helper.team

            if not (team or export_args.sprint_path or export_args.ids):
                print("Error: Must specify --team, --sprint-path, or --ids (or set AZURE_DEVOPS_TEAM in .env)")
                print("\nExamples:")
                print("  # Export current sprint (uses .env default)")
                print('  python3 ado_helper.py export_sprint')
                print("\n  # Export current sprint (explicit team)")
                print('  python3 ado_helper.py export_sprint --team "AI Initiative Team"')
                print("\n  # Export specific sprint")
                print('  python3 ado_helper.py export_sprint --sprint-path "AI Initiative\\Sprint 15"')
                print("\n  # Export specific work items")
                print("  python3 ado_helper.py export_sprint --ids 14478 14479 14480")
                print("\n  # With custom title and output")
                print('  python3 ado_helper.py export_sprint --ids 14478 14479 --title "Bug Fixes" --output bugs.md')
                sys.exit(1)

            print("Exporting work items...")
            file_path = helper.export_work_items_to_markdown(
                team=team,
                sprint_path=export_args.sprint_path,
                work_item_ids=export_args.ids,
                project=export_args.project,
                output_file=export_args.output,
                title=export_args.title,
            )
            print(f"\n✅ Successfully exported to: {file_path}")
            sys.exit(0)

        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            import traceback
            traceback.print_exc()
            sys.exit(1)

    # Standard command parsing for other commands
    parser = argparse.ArgumentParser(
        description="Azure DevOps Helper using official library"
    )
    parser.add_argument(
        "command",
        choices=[
            "projects",
            "project",
            "teams",
            "work_item_types",
            "work_item_categories",
            "repos",
            "workitem",
            "children",
            "link",
            "comment",
            "delete",
            "prs",
            "query",
            "current_sprint",
            "current_sprint_stories",
            "export_sprint",
            # AIDLC-specific commands
            "current_bolt",
            "bolt_items",
            "current_bolt_items",
        ],
    )
    parser.add_argument("args", nargs="*", help="Command arguments")
    args = parser.parse_args()

    try:
        helper = AzureDevOpsHelper()

        if args.command == "projects":
            result = helper.get_projects()
            result = [
                {"name": p.name, "id": p.id, "description": p.description}
                for p in result
            ]

        elif args.command == "project":
            project = args.args[0] if args.args else None
            result = helper.get_project(project)
            result = {
                "name": result.name,
                "id": result.id,
                "description": result.description,
            }

        elif args.command == "teams":
            project = args.args[0] if args.args else None
            result = helper.get_teams(project)
            result = [{"name": t.name, "id": t.id} for t in result]

        elif args.command == "work_item_types":
            project = args.args[0] if args.args else None
            result = helper.get_work_item_types(project)
            result = [
                {
                    "name": t.name,
                    "description": t.description if hasattr(t, 'description') else '',
                    "color": t.color if hasattr(t, 'color') else '',
                    "icon": t.icon.id if hasattr(t, 'icon') and t.icon else ''
                }
                for t in result
            ]

        elif args.command == "work_item_categories":
            project = args.args[0] if args.args else None
            result = helper.get_work_item_type_categories(project)
            result = [
                {
                    "name": c.name,
                    "referenceName": c.reference_name,
                    "defaultWorkItemType": c.default_work_item_type.name if c.default_work_item_type else None,
                    "workItemTypes": [wit.name for wit in c.work_item_types] if c.work_item_types else []
                }
                for c in result
            ]

        elif args.command == "repos":
            project = args.args[0] if args.args else None
            result = helper.get_repositories(project)
            result = [
                {"name": r.name, "id": r.id, "url": r.web_url} for r in result
            ]

        elif args.command == "workitem":
            if not args.args:
                print("Error: Work item ID required")
                sys.exit(1)
            wi = helper.get_work_item(int(args.args[0]))
            result = {
                "id": wi.id,
                "type": wi.fields.get("System.WorkItemType"),
                "title": wi.fields.get("System.Title"),
                "state": wi.fields.get("System.State"),
                "assignedTo": wi.fields.get("System.AssignedTo"),
            }

        elif args.command == "children":
            if not args.args:
                print("Error: Parent work item ID required")
                print("\nExamples:")
                print("  python3 ado_helper.py children 7728")
                print('  python3 ado_helper.py children 7728 Task')
                print('  python3 ado_helper.py children 7728 Bug')
                sys.exit(1)
            parent_id = int(args.args[0])
            work_item_type = args.args[1] if len(args.args) > 1 else None
            children = helper.get_child_work_items(parent_id, work_item_type)
            result = [
                {
                    "id": wi.id,
                    "type": wi.fields.get("System.WorkItemType"),
                    "title": wi.fields.get("System.Title"),
                    "state": wi.fields.get("System.State"),
                    "assignedTo": wi.fields.get("System.AssignedTo", {}).get("displayName") if isinstance(wi.fields.get("System.AssignedTo"), dict) else str(wi.fields.get("System.AssignedTo", "Unassigned")),
                    "storyPoints": wi.fields.get("Microsoft.VSTS.Scheduling.StoryPoints"),
                }
                for wi in children
            ]

        elif args.command == "link":
            if len(args.args) < 2:
                print("Error: Source and target work item IDs required")
                print("\nExamples:")
                print("  python3 ado_helper.py link 12345 200 parent")
                print("  python3 ado_helper.py link 100 101 related")
                sys.exit(1)
            source_id = int(args.args[0])
            target_id = int(args.args[1])
            link_type = args.args[2] if len(args.args) > 2 else "related"
            updated = helper.link_work_items(source_id, target_id, link_type)
            result = {
                "linked": True,
                "source": source_id,
                "target": target_id,
                "linkType": link_type,
            }

        elif args.command == "comment":
            if len(args.args) < 2:
                print("Error: Work item ID and comment text required")
                print('\nExample:\n  python3 ado_helper.py comment 12345 "Blocked on API team"')
                sys.exit(1)
            wi_id = int(args.args[0])
            text = " ".join(args.args[1:])
            comment = helper.add_comment(wi_id, text)
            result = {"workItemId": wi_id, "commentId": getattr(comment, "id", None)}

        elif args.command == "delete":
            if not args.args:
                print("Error: Work item ID required")
                print("\nExamples:")
                print("  python3 ado_helper.py delete 12345          # to recycle bin")
                print("  python3 ado_helper.py delete 12345 destroy  # permanent")
                sys.exit(1)
            wi_id = int(args.args[0])
            destroy = len(args.args) > 1 and args.args[1].lower() == "destroy"
            helper.delete_work_item(wi_id, destroy=destroy)
            result = {"deleted": wi_id, "permanent": destroy}

        elif args.command == "prs":
            if not args.args:
                print("Error: Repository name required")
                sys.exit(1)
            repo = args.args[0]
            project = args.args[1] if len(args.args) > 1 else None
            prs = helper.get_pull_requests(repo, project)
            result = [
                {
                    "id": pr.pull_request_id,
                    "title": pr.title,
                    "status": pr.status,
                    "createdBy": pr.created_by.display_name,
                }
                for pr in prs
            ]

        elif args.command == "query":
            if not args.args:
                print("Error: WIQL query required")
                sys.exit(1)
            wiql = " ".join(args.args)
            items = helper.query_work_items(wiql)
            result = [
                {
                    "id": wi.id,
                    "type": wi.fields.get("System.WorkItemType"),
                    "title": wi.fields.get("System.Title"),
                    "state": wi.fields.get("System.State"),
                }
                for wi in items
            ]

        elif args.command == "current_sprint":
            team = args.args[0] if args.args else helper.team
            if not team:
                print("Error: Team name required (provide as argument or set AZURE_DEVOPS_TEAM in .env)")
                sys.exit(1)
            project = args.args[1] if len(args.args) > 1 else None
            sprint = helper.get_current_sprint(team, project)
            if sprint:
                result = {
                    "id": sprint.id,
                    "name": sprint.name,
                    "path": sprint.path,
                    "startDate": sprint.attributes.start_date.isoformat() if sprint.attributes.start_date else None,
                    "finishDate": sprint.attributes.finish_date.isoformat() if sprint.attributes.finish_date else None,
                    "timeFrame": sprint.attributes.time_frame,
                }
            else:
                result = {"message": "No current sprint found"}

        elif args.command == "current_sprint_stories":
            team = args.args[0] if args.args else helper.team
            if not team:
                print("Error: Team name required (provide as argument or set AZURE_DEVOPS_TEAM in .env)")
                sys.exit(1)
            project = args.args[1] if len(args.args) > 1 else None
            include_children = args.args[2].lower() == "true" if len(args.args) > 2 else False
            stories = helper.get_current_sprint_user_stories(team, project, include_children)
            result = [
                {
                    "id": wi.id,
                    "type": wi.fields.get("System.WorkItemType"),
                    "title": wi.fields.get("System.Title"),
                    "state": wi.fields.get("System.State"),
                    "assignedTo": wi.fields.get("System.AssignedTo", {}).get("displayName") if isinstance(wi.fields.get("System.AssignedTo"), dict) else str(wi.fields.get("System.AssignedTo", "Unassigned")),
                }
                for wi in stories
            ]

        # AIDLC-specific commands
        elif args.command == "current_bolt":
            team = args.args[0] if args.args else helper.team
            if not team:
                print("Error: Team name required (provide as argument or set AZURE_DEVOPS_TEAM in .env)")
                sys.exit(1)
            project = args.args[1] if len(args.args) > 1 else None
            bolt = helper.get_current_bolt(team, project)
            if bolt:
                result = {
                    "id": bolt.id,
                    "name": bolt.name,
                    "path": bolt.path,
                    "startDate": bolt.attributes.start_date.isoformat() if bolt.attributes.start_date else None,
                    "finishDate": bolt.attributes.finish_date.isoformat() if bolt.attributes.finish_date else None,
                    "timeFrame": bolt.attributes.time_frame,
                }
            else:
                result = {"message": "No current bolt found"}

        elif args.command == "bolt_items":
            if len(args.args) < 2:
                print("Error: Bolt name and team name required")
                print("\nExamples:")
                print('  python3 ado_helper.py bolt_items "Bolt 15" "AI Team"')
                print('  python3 ado_helper.py bolt_items "Sprint 2" "AI Team"')
                sys.exit(1)
            bolt_name = args.args[0]
            team = args.args[1]
            project = args.args[2] if len(args.args) > 2 else None
            items = helper.get_bolt_items(bolt_name, team, project)
            result = [
                {
                    "id": wi.id,
                    "type": wi.fields.get("System.WorkItemType"),
                    "title": wi.fields.get("System.Title"),
                    "state": wi.fields.get("System.State"),
                    "assignedTo": wi.fields.get("System.AssignedTo", {}).get("displayName") if isinstance(wi.fields.get("System.AssignedTo"), dict) else str(wi.fields.get("System.AssignedTo", "Unassigned")),
                }
                for wi in items
            ]

        elif args.command == "current_bolt_items":
            team = args.args[0] if args.args else helper.team
            if not team:
                print("Error: Team name required (provide as argument or set AZURE_DEVOPS_TEAM in .env)")
                print("\nExamples:")
                print('  python3 ado_helper.py current_bolt_items "AI Team"')
                print('  python3 ado_helper.py current_bolt_items  # Uses AZURE_DEVOPS_TEAM from .env')
                sys.exit(1)
            project = args.args[1] if len(args.args) > 1 else None
            items = helper.get_current_bolt_items(team, project)
            result = [
                {
                    "id": wi.id,
                    "type": wi.fields.get("System.WorkItemType"),
                    "title": wi.fields.get("System.Title"),
                    "state": wi.fields.get("System.State"),
                    "assignedTo": wi.fields.get("System.AssignedTo", {}).get("displayName") if isinstance(wi.fields.get("System.AssignedTo"), dict) else str(wi.fields.get("System.AssignedTo", "Unassigned")),
                }
                for wi in items
            ]

        else:
            print(f"Unknown command: {args.command}")
            sys.exit(1)

        print(json.dumps(result, indent=2, ensure_ascii=False))

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        import traceback

        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()

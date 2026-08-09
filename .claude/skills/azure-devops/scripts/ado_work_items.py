#!/usr/bin/env python3
"""
Azure DevOps Work Item Operations Module

All work item tracking operations including CRUD, queries, and sprint management.
"""

from typing import Optional, List, Any
from azure.devops.v7_1.work.models import TeamContext
from azure.devops.v7_1.work_item_tracking.models import JsonPatchOperation, Wiql

# Support both direct script execution and package import
try:
    from .ado_utils import wiql_escape
except ImportError:
    from ado_utils import wiql_escape


class WorkItemOperations:
    """Work item tracking operations"""

    def __init__(self, client):
        """
        Initialize WorkItemOperations

        Args:
            client: AzureDevOpsClient instance
        """
        self.client = client
        self.work_item_tracking_client = client.work_item_tracking_client
        self.work_client = client.work_client

    # Azure DevOps caps get_work_items at ~200 IDs per request (414 URI Too Long).
    _BATCH_SIZE = 200

    def _get_work_items_batched(
        self, ids: List[int], fields: Optional[List[str]] = None
    ) -> List[Any]:
        """
        Fetch full work items for a list of IDs, batching to respect the
        ~200-ID-per-request limit. Shared by every WIQL-backed query so the
        batching logic lives in one place.
        """
        all_items: List[Any] = []
        for i in range(0, len(ids), self._BATCH_SIZE):
            batch_ids = ids[i:i + self._BATCH_SIZE]
            all_items.extend(
                self.work_item_tracking_client.get_work_items(
                    ids=batch_ids, fields=fields
                )
            )
        return all_items

    def _get_hierarchy_child_ids(self, parent_id: int) -> List[int]:
        """
        Return the IDs of direct children of a parent via the Hierarchy-Forward
        link. Centralizes the WorkItemLinks query that was previously duplicated
        across get_child_work_items and the sprint child-items path.
        """
        wiql = f"""
            SELECT [System.Id]
            FROM WorkItemLinks
            WHERE [Source].[System.Id] = {int(parent_id)}
            AND [System.Links.LinkType] = 'System.LinkTypes.Hierarchy-Forward'
            MODE (MustContain)
        """
        result = self.work_item_tracking_client.query_by_wiql(wiql=Wiql(query=wiql))
        if not result.work_item_relations:
            return []
        # rel is None for the source/parent item; keep only the link targets.
        return [
            rel.target.id
            for rel in result.work_item_relations
            if rel.target and rel.rel
        ]

    def get_work_item(self, work_item_id: int, fields: Optional[List[str]] = None) -> Any:
        """
        Get work item by ID

        Args:
            work_item_id: Work item ID
            fields: Optional list of fields to retrieve

        Returns:
            Work item object

        Example:
            work_item = work_item_ops.get_work_item(12345)
            print(f"Title: {work_item.fields['System.Title']}")
            print(f"State: {work_item.fields['System.State']}")
        """
        return self.work_item_tracking_client.get_work_item(
            id=work_item_id, fields=fields
        )

    def get_child_work_items(
        self,
        parent_id: int,
        work_item_type: Optional[str] = None,
    ) -> List[Any]:
        """
        Get all child work items of a parent work item

        Args:
            parent_id: Parent work item ID
            work_item_type: Optional filter by child work item type (e.g., "Task", "Bug")

        Returns:
            List of child work item objects

        Example:
            # Get all children of a User Story
            children = work_item_ops.get_child_work_items(12345)

            # Get only Task children
            tasks = work_item_ops.get_child_work_items(12345, work_item_type="Task")

            # Get only Bug children
            bugs = work_item_ops.get_child_work_items(12345, work_item_type="Bug")
        """
        # Use WorkItemLinks query to find children via Hierarchy-Forward link
        child_ids = self._get_hierarchy_child_ids(int(parent_id))
        if not child_ids:
            return []

        all_children = self._get_work_items_batched(child_ids)

        # Filter by work item type if specified
        if work_item_type:
            all_children = [
                item for item in all_children
                if item.fields.get('System.WorkItemType') == work_item_type
            ]

        return all_children

    def create_work_item(
        self,
        work_item_type: str,
        title: str,
        project: Optional[str] = None,
        parent_id: Optional[int] = None,
        **fields
    ) -> Any:
        """
        Create a new work item

        Args:
            work_item_type: Type (Task, Bug, User Story, Feature, Epic)
            title: Work item title
            project: Project name
            parent_id: Optional parent work item ID — links the new item as a
                child of that parent in one call (common for AIDLC hierarchies)
            **fields: Additional fields as System.FieldName=value

        Returns:
            Created work item object

        Example:
            work_item = work_item_ops.create_work_item(
                "Task",
                "Implement new feature",
                project="My Project",
                parent_id=200,
                **{
                    "System.Description": "Detailed description",
                    "System.AssignedTo": "user@example.com",
                    "System.Tags": "backend; api"
                }
            )
        """
        project = self.client.resolve_project(project)

        # Build JSON patch document
        document = [
            JsonPatchOperation(
                op="add", path="/fields/System.Title", value=title
            )
        ]

        # Add additional fields
        for field_name, value in fields.items():
            document.append(
                JsonPatchOperation(
                    op="add", path=f"/fields/{field_name}", value=value
                )
            )

        # Optionally attach to a parent via the Hierarchy-Reverse relation.
        if parent_id is not None:
            document.append(
                JsonPatchOperation(
                    op="add",
                    path="/relations/-",
                    value={
                        "rel": "System.LinkTypes.Hierarchy-Reverse",
                        "url": f"{self.client.organization_url}/_apis/wit/workItems/{int(parent_id)}",
                    },
                )
            )

        return self.work_item_tracking_client.create_work_item(
            document=document, project=project, type=work_item_type
        )

    def update_work_item(self, work_item_id: int, **fields) -> Any:
        """
        Update work item fields

        Args:
            work_item_id: Work item ID
            **fields: Fields to update as System.FieldName=value

        Returns:
            Updated work item object

        Example:
            work_item = work_item_ops.update_work_item(
                12345,
                **{
                    "System.State": "Active",
                    "System.AssignedTo": "user@example.com"
                }
            )
        """
        # Build JSON patch document. "add" upserts: it sets the field whether or
        # not it already has a value, whereas "replace" can fail on a field that
        # was never set. Using "add" makes updates robust for first-time writes.
        document = []
        for field_name, value in fields.items():
            document.append(
                JsonPatchOperation(
                    op="add", path=f"/fields/{field_name}", value=value
                )
            )

        return self.work_item_tracking_client.update_work_item(
            document=document, id=work_item_id
        )

    # Friendly aliases for the verbose ADO link reference names, so callers can
    # say link_type="parent" instead of "System.LinkTypes.Hierarchy-Reverse".
    _LINK_TYPE_ALIASES = {
        "parent": "System.LinkTypes.Hierarchy-Reverse",
        "child": "System.LinkTypes.Hierarchy-Forward",
        "related": "System.LinkTypes.Related",
        "predecessor": "System.LinkTypes.Dependency-Reverse",
        "successor": "System.LinkTypes.Dependency-Forward",
        "duplicate": "System.LinkTypes.Duplicate-Forward",
        "duplicate-of": "System.LinkTypes.Duplicate-Reverse",
    }

    def delete_work_item(
        self,
        work_item_id: int,
        destroy: bool = False,
        project: Optional[str] = None,
    ) -> Any:
        """
        Delete a work item.

        By default the item goes to the recycle bin and can be restored. Pass
        destroy=True to permanently delete it (irreversible — use with care).

        Args:
            work_item_id: Work item ID to delete
            destroy: If True, permanently destroy instead of recycle-bin
            project: Project name

        Returns:
            The deleted work item reference

        Example:
            work_item_ops.delete_work_item(12345)               # to recycle bin
            work_item_ops.delete_work_item(12345, destroy=True) # permanent
        """
        return self.work_item_tracking_client.delete_work_item(
            id=int(work_item_id), project=project or self.client.project, destroy=destroy
        )

    def link_work_items(
        self,
        source_id: int,
        target_id: int,
        link_type: str = "related",
        comment: str = "",
    ) -> Any:
        """
        Create a link/relation between two work items.

        This is the write side of the hierarchy the read methods already
        traverse — e.g. set a Task's parent, or relate two stories.

        Args:
            source_id: Work item the link is added to
            target_id: Work item the link points at
            link_type: Friendly alias ("parent", "child", "related",
                "predecessor", "successor", "duplicate", "duplicate-of") or a
                full reference name like "System.LinkTypes.Related"
            comment: Optional comment stored on the link

        Returns:
            Updated source work item object

        Example:
            # Make 200 the parent of task 12345
            work_item_ops.link_work_items(12345, 200, link_type="parent")
            # Relate two stories
            work_item_ops.link_work_items(100, 101, link_type="related")
        """
        rel = self._LINK_TYPE_ALIASES.get(link_type.lower(), link_type)
        target_url = (
            f"{self.client.organization_url}/_apis/wit/workItems/{int(target_id)}"
        )
        relation = {"rel": rel, "url": target_url}
        if comment:
            relation["attributes"] = {"comment": comment}

        document = [
            JsonPatchOperation(op="add", path="/relations/-", value=relation)
        ]
        return self.work_item_tracking_client.update_work_item(
            document=document, id=int(source_id)
        )

    def add_comment(
        self,
        work_item_id: int,
        text: str,
        project: Optional[str] = None,
    ) -> Any:
        """
        Add a comment to a work item's discussion.

        Args:
            work_item_id: Work item ID
            text: Comment body (supports HTML)
            project: Project name

        Returns:
            The created comment object

        Example:
            work_item_ops.add_comment(12345, "Blocked on the API team.")
        """
        from azure.devops.v7_1.work_item_tracking.models import CommentCreate

        project = self.client.resolve_project(project)

        return self.work_item_tracking_client.add_comment(
            request=CommentCreate(text=text),
            project=project,
            work_item_id=int(work_item_id),
        )

    def get_work_item_revisions(
        self,
        work_item_id: int,
        top: Optional[int] = None,
    ) -> List[Any]:
        """
        Get the revision history of a work item (each field change is a revision).

        Args:
            work_item_id: Work item ID
            top: Optional cap on number of revisions returned

        Returns:
            List of work item revision objects, oldest first

        Example:
            revisions = work_item_ops.get_work_item_revisions(12345)
            for rev in revisions:
                print(rev.rev, rev.fields.get("System.State"))
        """
        return self.work_item_tracking_client.get_revisions(
            id=int(work_item_id), top=top
        )

    def query_work_items(self, wiql: str, project: Optional[str] = None) -> List[Any]:
        """
        Query work items using WIQL

        Args:
            wiql: WIQL query string
            project: Project name

        Returns:
            List of work item objects with full details

        Example:
            wiql = '''
                SELECT [System.Id], [System.Title], [System.State]
                FROM WorkItems
                WHERE [System.WorkItemType] = 'Task'
                AND [System.State] = 'Active'
            '''
            items = work_item_ops.query_work_items(wiql)
        """
        project = self.client.resolve_project(project)

        # Execute the flat WorkItems query, then hydrate full field values
        # (query_by_wiql only returns IDs/the SELECT columns).
        result = self.work_item_tracking_client.query_by_wiql(wiql=Wiql(query=wiql))
        if not result.work_items:
            return []

        ids = [item.id for item in result.work_items]
        return self._get_work_items_batched(ids)

    def get_sprint_items(
        self,
        iteration_path: str,
        project: Optional[str] = None,
        work_item_type: Optional[str] = None,
        exclude_ritual_enablers: bool = False,
    ) -> List[Any]:
        """
        Get all work items in a sprint/iteration

        Args:
            iteration_path: Full iteration path (e.g., "Project\\Sprint 1")
            project: Project name
            work_item_type: Optional filter by type
            exclude_ritual_enablers: If True, exclude Enabler work items (used for rituals)

        Returns:
            List of work item objects

        Example:
            items = work_item_ops.get_sprint_items("MyProject\\Sprint 1")
            items = work_item_ops.get_sprint_items("MyProject\\Sprint 1", exclude_ritual_enablers=True)
        """
        project = self.client.resolve_project(project)

        # Build WIQL query (escape values to avoid breakage/injection on
        # iteration paths or types that contain apostrophes).
        wiql = f"""
            SELECT [System.Id], [System.Title], [System.State], [System.AssignedTo]
            FROM WorkItems
            WHERE [System.IterationPath] = '{wiql_escape(iteration_path)}'
        """

        if work_item_type:
            wiql += f" AND [System.WorkItemType] = '{wiql_escape(work_item_type)}'"

        if exclude_ritual_enablers:
            wiql += " AND [System.WorkItemType] <> 'Enabler'"

        return self.query_work_items(wiql, project)

    def get_current_sprint(
        self,
        team: str,
        project: Optional[str] = None,
    ) -> Optional[Any]:
        """
        Get the current sprint/iteration for a team

        Args:
            team: Team name or ID
            project: Project name

        Returns:
            Current iteration object or None if no current sprint

        Example:
            sprint = work_item_ops.get_current_sprint("My Team")
            if sprint:
                print(f"Current sprint: {sprint.name}")
                print(f"Start: {sprint.attributes.start_date}")
                print(f"Finish: {sprint.attributes.finish_date}")
        """
        project = self.client.resolve_project(project)

        # Get team iterations with current timeframe filter
        team_context = TeamContext(project=project, team=team)
        iterations = self.work_client.get_team_iterations(
            team_context=team_context,
            timeframe="current"
        )

        # Return the first current iteration (there should typically be only one)
        return iterations[0] if iterations else None

    def get_current_sprint_user_stories(
        self,
        team: str,
        project: Optional[str] = None,
        include_child_items: bool = False,
        exclude_ritual_enablers: bool = False,
    ) -> List[Any]:
        """
        Get all user stories in the current sprint for a team

        Args:
            team: Team name or ID
            project: Project name
            include_child_items: If True, also include child tasks/bugs
            exclude_ritual_enablers: If True, exclude Enabler work items (used for rituals)

        Returns:
            List of user story work item objects

        Example:
            stories = work_item_ops.get_current_sprint_user_stories("My Team")
            for story in stories:
                print(f"US #{story.id}: {story.fields['System.Title']}")
                print(f"State: {story.fields['System.State']}")
                print(f"Assigned: {story.fields.get('System.AssignedTo', {}).get('displayName', 'Unassigned')}")
        """
        project = self.client.resolve_project(project)

        # Get current sprint
        current_sprint = self.get_current_sprint(team, project)
        if not current_sprint:
            return []

        # Build WIQL query for user stories
        wiql = f"""
            SELECT [System.Id], [System.Title], [System.State], [System.AssignedTo]
            FROM WorkItems
            WHERE [System.IterationPath] = '{wiql_escape(current_sprint.path)}'
            AND [System.WorkItemType] = 'User Story'
        """

        if exclude_ritual_enablers:
            wiql += " AND [System.WorkItemType] <> 'Enabler'"

        # Get user stories
        user_stories = self.query_work_items(wiql, project)

        if not include_child_items:
            return user_stories

        # Collect children across all stories. Gather IDs first so we batch-fetch
        # once (avoids an N+1 query per story) and dedupe against the stories and
        # each other (a child shared by two parents must not appear twice).
        all_items = list(user_stories)
        seen_ids = {story.id for story in user_stories}
        child_ids: List[int] = []
        for story in user_stories:
            for cid in self._get_hierarchy_child_ids(story.id):
                if cid not in seen_ids:
                    seen_ids.add(cid)
                    child_ids.append(cid)

        if child_ids:
            all_items.extend(self._get_work_items_batched(child_ids))
        return all_items

    # ============================================================================
    # AIDLC-SPECIFIC METHODS (Bolt = Sprint in AIDLC terminology)
    # ============================================================================

    def get_current_bolt(
        self,
        team: str,
        project: Optional[str] = None,
    ) -> Optional[Any]:
        """
        Get the current bolt (AIDLC term for sprint) for a team

        This is an alias for get_current_sprint() using AIDLC terminology.

        Args:
            team: Team name or ID
            project: Project name

        Returns:
            Current bolt/iteration object or None if no current bolt

        Example:
            bolt = work_item_ops.get_current_bolt("AI Team")
            if bolt:
                print(f"Current bolt: {bolt.name}")
        """
        return self.get_current_sprint(team, project)

    def get_bolt_items(
        self,
        bolt_name: str,
        team: str,
        project: Optional[str] = None,
        work_item_type: Optional[str] = None,
        exclude_ritual_enablers: bool = True,
    ) -> List[Any]:
        """
        Get all work items in a specific bolt (AIDLC sprint) by bolt name

        Args:
            bolt_name: Bolt name (e.g., "Bolt 15", "Sprint 2")
            team: Team name (needed to resolve full iteration path)
            project: Project name
            work_item_type: Optional filter by type
            exclude_ritual_enablers: If True, exclude Enabler work items (default: True)

        Returns:
            List of work item objects

        Example:
            items = work_item_ops.get_bolt_items("Bolt 15", "AI Team")
            items = work_item_ops.get_bolt_items("Bolt 15", "AI Team", exclude_ritual_enablers=False)
        """
        project = self.client.resolve_project(project)

        # Get all team iterations to find the one matching bolt_name
        team_context = TeamContext(project=project, team=team)
        iterations = self.work_client.get_team_iterations(team_context=team_context)

        # Match the bolt name tolerant of surrounding whitespace and case.
        target = bolt_name.strip().casefold()
        matching_iteration = next(
            (it for it in iterations if (it.name or "").strip().casefold() == target),
            None,
        )

        if not matching_iteration:
            available = ", ".join(it.name for it in iterations) or "(none)"
            raise ValueError(
                f"Bolt '{bolt_name}' not found for team '{team}'. "
                f"Available iterations: {available}"
            )

        # Use get_sprint_items with the iteration path
        return self.get_sprint_items(
            matching_iteration.path,
            project,
            work_item_type,
            exclude_ritual_enablers
        )

    def get_current_bolt_items(
        self,
        team: str,
        project: Optional[str] = None,
        work_item_type: Optional[str] = None,
        exclude_ritual_enablers: bool = True,
    ) -> List[Any]:
        """
        Get all work items in the current bolt (AIDLC current sprint)

        Args:
            team: Team name or ID
            project: Project name
            work_item_type: Optional filter by type
            exclude_ritual_enablers: If True, exclude Enabler work items (default: True)

        Returns:
            List of work item objects

        Example:
            items = work_item_ops.get_current_bolt_items("AI Team")
            stories = work_item_ops.get_current_bolt_items("AI Team", work_item_type="User Story")
            all_items = work_item_ops.get_current_bolt_items("AI Team", exclude_ritual_enablers=False)
        """
        project = self.client.resolve_project(project)

        # Get current bolt
        current_bolt = self.get_current_bolt(team, project)
        if not current_bolt:
            return []

        # Use get_sprint_items with the bolt path
        return self.get_sprint_items(
            current_bolt.path,
            project,
            work_item_type,
            exclude_ritual_enablers
        )

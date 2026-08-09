#!/usr/bin/env python3
"""
Azure DevOps Export Module

Work item export functionality to markdown.
"""

import html
import os
import re
import requests
import subprocess
from datetime import datetime
from typing import Optional, List
from urllib.parse import quote

# Support both direct script execution and package import
try:
    from .ado_utils import html_to_markdown, wiql_escape
except ImportError:
    from ado_utils import html_to_markdown, wiql_escape


class ExportOperations:
    """Export operations for work items"""

    def __init__(self, work_item_ops):
        """
        Initialize ExportOperations

        Args:
            work_item_ops: WorkItemOperations instance
        """
        self.work_item_ops = work_item_ops

    @staticmethod
    def find_project_root(start_path=None):
        """
        Find the project root directory by looking for git root.

        Args:
            start_path: Path to start searching from (defaults to current directory)

        Returns:
            Path to project root or current directory if not found
        """
        if start_path is None:
            start_path = os.getcwd()

        try:
            # Try to find git root
            result = subprocess.run(
                ['git', 'rev-parse', '--show-toplevel'],
                cwd=start_path,
                capture_output=True,
                text=True,
                check=True
            )
            return result.stdout.strip()
        except (subprocess.CalledProcessError, FileNotFoundError):
            # If git command fails or git is not installed, fall back to current directory
            return start_path

    def download_images_from_html(self, html_content, image_folder, work_item_id):
        """
        Extract image URLs from HTML, download them, and update HTML with local paths

        Args:
            html_content: HTML content containing image tags
            image_folder: Folder to save downloaded images
            work_item_id: Work item ID for naming images

        Returns:
            Updated HTML content with local image references
        """
        if not html_content or html_content == 'No description':
            return html_content

        # Extract all img src URLs from HTML
        img_pattern = r'<img[^>]+src="([^"]+)"'
        matches = re.findall(img_pattern, html_content)

        if not matches:
            return html_content

        # Create image folder if it doesn't exist
        os.makedirs(image_folder, exist_ok=True)

        updated_html = html_content
        for idx, img_url in enumerate(matches):
            # Skip if not an Azure DevOps attachment URL
            if 'visualstudio.com' not in img_url and 'dev.azure.com' not in img_url:
                continue

            try:
                # Download image with authentication
                # Use PAT with basic auth (empty username, PAT as password)
                import base64
                pat = self.work_item_ops.client.pat
                auth_string = base64.b64encode(f':{pat}'.encode()).decode()
                headers = {
                    'Authorization': f'Basic {auth_string}'
                }
                response = requests.get(img_url, headers=headers, timeout=10)
                response.raise_for_status()

                # Detect file extension from content type or URL
                content_type = response.headers.get('Content-Type', '').lower()
                ext = ''
                if 'png' in content_type:
                    ext = '.png'
                elif 'jpeg' in content_type or 'jpg' in content_type:
                    ext = '.jpg'
                elif 'gif' in content_type:
                    ext = '.gif'
                elif 'svg' in content_type:
                    ext = '.svg'
                else:
                    # Try to get extension from URL query params or default to .png
                    if 'fileName=' in img_url:
                        filename_match = re.search(r'fileName=([^&]+)', img_url)
                        if filename_match:
                            _, ext = os.path.splitext(filename_match.group(1))
                    if not ext or ext == '':
                        ext = '.png'  # Default to .png

                # Generate unique filename with work item ID
                local_filename = f"wi{work_item_id}_image-{idx + 1}{ext}"
                local_path = os.path.join(image_folder, local_filename)

                # Save image
                with open(local_path, 'wb') as f:
                    f.write(response.content)

                # Update HTML with relative path and remove size restrictions
                relative_path = os.path.join(os.path.basename(image_folder), local_filename)
                
                # Find the complete img tag for this URL
                img_tag_pattern = rf'<img[^>]*src="{re.escape(img_url)}"[^>]*>'
                img_matches = re.findall(img_tag_pattern, updated_html)
                
                if img_matches:
                    for img_tag in img_matches:
                        # Create new img tag with relative path and larger display size
                        # Remove width/height attributes and set max-width for better display
                        new_img_tag = f'<img src="{relative_path}" alt="Image" style="max-width:600px;">'
                        updated_html = updated_html.replace(img_tag, new_img_tag)
                else:
                    # Fallback: just replace the URL
                    updated_html = updated_html.replace(img_url, relative_path)

                print(f"  ✓ Downloaded image: {local_filename}")

            except Exception as e:
                print(f"  ⚠ Failed to download image from {img_url}: {e}")
                # Keep original URL if download fails

        return updated_html

    @staticmethod
    def format_priority(priority_value):
        """
        Convert numeric priority to High/Medium/Low format

        Args:
            priority_value: Priority value (1-4 or string)

        Returns:
            Formatted priority string (High, Medium, Low, or N/A)
        """
        if not priority_value or priority_value == 'N/A':
            return 'N/A'

        try:
            priority = int(priority_value)
            if priority == 1:
                return 'High'
            elif priority == 2:
                return 'Medium'
            elif priority in (3, 4):
                return 'Low'
            else:
                return f'Priority {priority}'
        except (ValueError, TypeError):
            return str(priority_value)

    def export_work_items_to_markdown(
        self,
        output_file: Optional[str] = None,
        project: Optional[str] = None,
        team: Optional[str] = None,
        sprint_path: Optional[str] = None,
        work_item_ids: Optional[List[int]] = None,
        title: Optional[str] = None,
    ) -> str:
        """
        Export work items to markdown file with full details including acceptance criteria

        Flexible export supporting multiple scenarios:
        - Current sprint: Specify team name
        - Specific sprint: Specify sprint_path
        - Specific work items: Specify work_item_ids list

        Args:
            output_file: Output file path (auto-generated if not provided)
            project: Project name
            team: Team name (for current sprint export)
            sprint_path: Specific sprint path (e.g., "AI Initiative\\Sprint 15")
            work_item_ids: List of work item IDs to export
            title: Custom title for the markdown file

        Returns:
            Path to the generated markdown file

        Examples:
            # Export current sprint
            file_path = export_ops.export_work_items_to_markdown(team="My Team")

            # Export specific sprint
            file_path = export_ops.export_work_items_to_markdown(
                sprint_path="AI Initiative\\Sprint 15"
            )

            # Export specific work items
            file_path = export_ops.export_work_items_to_markdown(
                work_item_ids=[123, 456, 789],
                title="Critical Bug Fixes"
            )
        """
        project = self.work_item_ops.client.resolve_project(project)

        # Determine what to export
        sprint_info = None

        if team:
            # Export current sprint for team
            current_sprint = self.work_item_ops.get_current_sprint(team, project)
            if not current_sprint:
                raise ValueError(f"No current sprint found for team: {team}")
            sprint_path = current_sprint.path
            sprint_info = current_sprint
            if not title:
                title = f"Sprint {current_sprint.name} - Work Items"

        if sprint_path and not team:
            # Export specific sprint by path
            if not title:
                sprint_name = sprint_path.split('\\')[-1]
                title = f"Sprint {sprint_name} - Work Items"

        if work_item_ids:
            # Export specific work items
            if not title:
                title = "Work Items Export"

        # Build query based on input
        if work_item_ids:
            # Query specific work items by ID (coerce to int to keep WIQL safe)
            ids_str = ', '.join(str(int(id)) for id in work_item_ids)
            wiql = f"""
                SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType]
                FROM WorkItems
                WHERE [System.Id] IN ({ids_str})
                ORDER BY [System.WorkItemType], [System.Id]
            """
        elif sprint_path:
            # Query by sprint path (exclude Tasks). Escape the path so apostrophes
            # don't break the query or allow injection.
            wiql = f"""
                SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType]
                FROM WorkItems
                WHERE [System.IterationPath] = '{wiql_escape(sprint_path)}'
                AND [System.WorkItemType] <> 'Task'
                ORDER BY [System.WorkItemType], [System.Id]
            """
        else:
            raise ValueError("Must specify team, sprint_path, or work_item_ids")

        work_items = self.work_item_ops.query_work_items(wiql, project)

        if not work_items:
            print(f"Warning: No work items found")

        # Generate output filename if not provided
        if not output_file:
            # Find project root (git root)
            project_root = self.find_project_root()

            # Default export directory at project root
            default_export_dir = os.path.join(project_root, "aidlc-docs", "story-artifacts")

            # Create directory if it doesn't exist
            os.makedirs(default_export_dir, exist_ok=True)

            timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
            if sprint_info:
                filename = f"{sprint_info.name.lower().replace(' ', '-')}-{timestamp}.md"
            elif work_item_ids:
                filename = f"work-items-{timestamp}.md"
            else:
                filename = f"export-{timestamp}.md"

            output_file = os.path.join(default_export_dir, filename)

        # Create image folder based on output filename
        base_name = os.path.splitext(output_file)[0]
        image_folder = f"{base_name}_images"

        # Process work items
        stories_data = []
        print(f"Processing {len(work_items)} work items...")
        for item in work_items:
            fields = item.fields

            # Extract key fields
            wi_title = fields.get('System.Title', 'No Title')
            state = fields.get('System.State', 'Unknown')
            assigned_to = fields.get('System.AssignedTo', {})
            assigned_name = assigned_to.get('displayName', 'Unassigned') if isinstance(assigned_to, dict) else str(assigned_to)
            description = fields.get('System.Description', 'No description')
            acceptance_criteria = fields.get('Microsoft.VSTS.Common.AcceptanceCriteria', 'No acceptance criteria defined')
            requirement = fields.get('Custom.Requirement', None)
            priority = fields.get('Microsoft.VSTS.Common.Priority', 'N/A')
            story_points = fields.get('Microsoft.VSTS.Scheduling.StoryPoints', 'N/A')
            tags = fields.get('System.Tags', 'None')
            work_item_type = fields.get('System.WorkItemType', 'Unknown')

            # Extract related ADO and Jira fields (custom fields)
            related_ado = fields.get('Custom.RelatedADO', None) or fields.get('Custom.ADOLink', None)
            related_jira = fields.get('Custom.RelatedJira', None) or fields.get('Custom.JiraLink', None)

            # Construct Azure DevOps web URL instead of API URL
            # URL-encode the project name to handle spaces
            organization_url = self.work_item_ops.client.organization_url
            encoded_project = quote(project, safe='')
            web_url = f"{organization_url}/{encoded_project}/_workitems/edit/{item.id}"

            # Render rich-text HTML fields. ADO stores these as HTML fragments,
            # so we download any embedded images first (the <img> tags must still
            # be present), then convert the HTML to clean Markdown for output.
            description = html.unescape(description) if description else ''
            description = self.download_images_from_html(description, image_folder, item.id)
            description = html_to_markdown(description) or 'No description'

            acceptance_criteria = html.unescape(acceptance_criteria) if acceptance_criteria else ''
            acceptance_criteria = self.download_images_from_html(acceptance_criteria, image_folder, item.id)
            acceptance_criteria = html_to_markdown(acceptance_criteria) or 'No acceptance criteria defined'

            if requirement:
                requirement = html.unescape(requirement)
                requirement = self.download_images_from_html(requirement, image_folder, item.id)
                requirement = html_to_markdown(requirement) or None

            stories_data.append({
                'id': item.id,
                'type': work_item_type,
                'title': wi_title,
                'state': state,
                'assigned_to': assigned_name,
                'description': description,
                'acceptance_criteria': acceptance_criteria,
                'requirement': requirement,
                'priority': priority,
                'story_points': story_points,
                'tags': tags,
                'url': web_url,
                'related_ado': related_ado,
                'related_jira': related_jira
            })

        # Write markdown file
        with open(output_file, 'w', encoding='utf-8') as f:
            # Header
            f.write(f"# {title}\n\n")

            if team:
                f.write(f"**Team:** {team}  \n")

            if sprint_path:
                f.write(f"**Sprint Path:** {sprint_path}  \n")

            if sprint_info and sprint_info.attributes:
                if sprint_info.attributes.start_date:
                    f.write(f"**Start Date:** {sprint_info.attributes.start_date.strftime('%Y-%m-%d')}  \n")
                if sprint_info.attributes.finish_date:
                    f.write(f"**Finish Date:** {sprint_info.attributes.finish_date.strftime('%Y-%m-%d')}  \n")

            if work_item_ids:
                f.write(f"**Work Item IDs:** {', '.join(str(id) for id in work_item_ids)}  \n")

            f.write(f"**Project:** {project}  \n")
            f.write(f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  \n")
            f.write(f"**Total Items:** {len(stories_data)}\n\n")
            f.write("---\n\n")

            # Group by work item type
            feature_items = [s for s in stories_data if s['type'] == 'Feature']
            story_items = [s for s in stories_data if s['type'] in ['User Story', 'Product Backlog Item']]
            task_items = [s for s in stories_data if s['type'] == 'Task']
            bug_items = [s for s in stories_data if s['type'] == 'Bug']
            other_items = [s for s in stories_data if s['type'] not in ['Feature', 'User Story', 'Product Backlog Item', 'Task', 'Bug']]

            # Summary section
            f.write("## Summary\n\n")
            if feature_items:
                f.write(f"- **Features:** {len(feature_items)}\n")
            if story_items:
                f.write(f"- **User Stories:** {len(story_items)}\n")
            if task_items:
                f.write(f"- **Tasks:** {len(task_items)}\n")
            if bug_items:
                f.write(f"- **Bugs:** {len(bug_items)}\n")
            if other_items:
                f.write(f"- **Other:** {len(other_items)}\n")

            # Add detailed work items list
            f.write("\n### Work Items List\n\n")
            f.write("| ID | Type | Title | State |\n")
            f.write("|---:|:-----|:------|:------|\n")
            for item in stories_data:
                # Escape pipe characters in title to prevent table breaking
                title_escaped = item['title'].replace('|', '\\|')
                f.write(f"| {item['id']} | {item['type']} | {title_escaped} | {item['state']} |\n")

            f.write("\n---\n\n")

            # Write sections for each type
            self._write_work_item_section(f, "Features", feature_items, include_story_points=False)
            self._write_work_item_section(f, "User Stories", story_items, include_story_points=True)
            self._write_work_item_section(f, "Tasks", task_items, is_task=True)
            self._write_work_item_section(f, "Bugs", bug_items, include_story_points=False)
            self._write_work_item_section(f, "Other Items", other_items, include_story_points=False)

        return output_file

    def _write_work_item_section(self, f, section_name: str, items: List, include_story_points: bool = False, is_task: bool = False):
        """Helper to write a section of work items to markdown file"""
        if not items:
            return

        f.write(f"## {section_name} ({len(items)})\n\n")

        for idx, item in enumerate(items, 1):
            # Use new format for User Stories
            if section_name == "User Stories":
                f.write(f"### US-{item['id']}: {item['title']}\n\n")

                # Extract user story format from description or requirement if it exists
                # Format: As a [role], I want [feature], so that [benefit]
                user_story_text = self._extract_user_story(item['description'])
                # If not found in description, try requirement field
                if not user_story_text and item.get('requirement'):
                    user_story_text = self._extract_user_story(item['requirement'])
                if user_story_text:
                    f.write(f"**User Story**: {user_story_text}\n\n")

                # Add Related ADO and Jira fields if they exist
                if item.get('related_ado'):
                    f.write(f"**Related ADO** (optional, sync only): {item['related_ado']}\n\n")

                if item.get('related_jira'):
                    f.write(f"**Related Jira** (optional, sync only): {item['related_jira']}\n\n")

                # Add reference to the current work item ID
                f.write(f"**Related ADO**: #{item['id']}  \n")

                # Format priority as High/Medium/Low
                priority_formatted = self.format_priority(item['priority'])
                f.write(f"**Priority**: {priority_formatted}  \n")
                f.write(f"**State**: {item['state']}  \n")
                f.write(f"**Assigned To**: {item['assigned_to']}  \n")
                f.write(f"**Story Points**: {item['story_points']}  \n")
                f.write(f"**Tags**: {item['tags']}\n\n")

            else:
                # Use original format for other work item types
                f.write(f"### {idx}. [{item['id']}] {item['title']}\n\n")

                if not is_task:
                    f.write(f"**Type:** {item['type']}  \n")
                f.write(f"**State:** {item['state']}  \n")
                f.write(f"**Assigned To:** {item['assigned_to']}  \n")

                if not is_task:
                    f.write(f"**Priority:** {item['priority']}  \n")

                if include_story_points:
                    f.write(f"**Story Points:** {item['story_points']}  \n")

                f.write(f"**Tags:** {item['tags']}  \n\n")

            # Description section (same for all types)
            f.write("#### Description\n\n")
            f.write(f"{item['description']}\n\n")

            if item.get('requirement'):
                f.write("#### Requirement\n\n")
                f.write(f"{item['requirement']}\n\n")

            if not is_task and item.get('acceptance_criteria') and item['acceptance_criteria'] != 'No acceptance criteria defined':
                f.write("#### Acceptance Criteria\n\n")
                f.write(f"{item['acceptance_criteria']}\n\n")

            f.write(f"**Link:** {item['url']}\n\n")
            f.write("---\n\n")

    @staticmethod
    def _extract_user_story(description):
        """
        Extract user story format from description if it exists

        Looks for patterns like:
        - As a [role], I want [feature], so that [benefit]
        - As a [role] I want [feature] so that [benefit]

        Args:
            description: Work item description text

        Returns:
            Extracted user story text or None
        """
        if not description:
            return None

        import re

        # Strip HTML tags to get clean text for pattern matching
        clean_text = re.sub(r'<[^>]+>', ' ', description)
        # Normalize whitespace
        clean_text = re.sub(r'\s+', ' ', clean_text).strip()

        # Pattern to match user story format
        # Use non-greedy matching and look for "I want" and "so that" as delimiters
        pattern = r'As\s+a\s+(.+?),?\s+I\s+want\s+(.+?),?\s+so\s+that\s+(.+?)(?:\.|$)'
        match = re.search(pattern, clean_text, re.IGNORECASE | re.DOTALL)

        if match:
            role = match.group(1).strip()
            feature = match.group(2).strip()
            benefit = match.group(3).strip()
            # Remove trailing punctuation from benefit
            benefit = benefit.rstrip('.,;:!? ')
            return f"As a {role}, I want {feature}, so that {benefit}"

        return None

#\!/usr/bin/env python3
"""
N8N Workflow Importer - Direct Docker Container Method
Import workflows directly using the n8n container
"""

import json
import subprocess
import sys
from pathlib import Path
from typing import List, Dict, Any


class WorkflowImporter:
    """Import n8n workflows using Docker container."""

    def __init__(self, workflows_dir: str = "workflows"):
        self.workflows_dir = Path(workflows_dir)
        self.imported_count = 0
        self.failed_count = 0
        self.errors = []

    def validate_workflow(self, file_path: Path) -> bool:
        """Validate workflow JSON before import."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)

            if not isinstance(data, dict):
                return False

            required_fields = ['nodes', 'connections']
            for field in required_fields:
                if field not in data:
                    return False

            return True
        except (json.JSONDecodeError, FileNotFoundError, PermissionError):
            return False

    def import_workflow(self, file_path: Path) -> bool:
        """Import a single workflow file using Docker container."""
        try:
            if not self.validate_workflow(file_path):
                self.errors.append(f"Invalid JSON: {file_path.name}")
                return False

            # Copy file to container and import
            container_path = f"/tmp/{file_path.name}"

            # Copy file to container
            copy_cmd = [
                'docker', 'cp', str(file_path),
                f'n8n-n8n-1:{container_path}'
            ]

            result = subprocess.run(copy_cmd, capture_output=True, text=True, timeout=30)
            if result.returncode != 0:
                self.errors.append(f"Failed to copy {file_path.name} to container")
                return False

            # Import workflow in container
            import_cmd = [
                'docker', 'exec', 'n8n-n8n-1',
                'n8n', 'import:workflow',
                f'--input={container_path}'
            ]

            result = subprocess.run(import_cmd, capture_output=True, text=True, timeout=60)

            if result.returncode == 0:
                print(f"✅ Imported: {file_path.name}")
                return True
            else:
                error_msg = result.stderr.strip() or result.stdout.strip()
                self.errors.append(f"Import failed for {file_path.name}: {error_msg}")
                print(f"❌ Failed: {file_path.name} - {error_msg}")
                return False

        except subprocess.TimeoutExpired:
            self.errors.append(f"Timeout importing {file_path.name}")
            print(f"⏰ Timeout: {file_path.name}")
            return False
        except Exception as e:
            self.errors.append(f"Error importing {file_path.name}: {str(e)}")
            print(f"❌ Error: {file_path.name} - {str(e)}")
            return False

    def get_workflow_files(self) -> List[Path]:
        """Get all workflow JSON files."""
        if not self.workflows_dir.exists():
            print(f"❌ Workflows directory not found: {self.workflows_dir}")
            return []

        json_files = list(self.workflows_dir.glob("*.json"))
        if not json_files:
            print(f"❌ No JSON files found in: {self.workflows_dir}")
            return []

        return sorted(json_files)

    def check_docker_container(self) -> bool:
        """Check if n8n container is running."""
        try:
            result = subprocess.run(
                ['docker', 'ps', '--filter', 'name=n8n-n8n-1', '--format', '{{.Names}}'],
                capture_output=True, text=True, timeout=10
            )
            return 'n8n-n8n-1' in result.stdout
        except:
            return False

    def import_all(self) -> Dict[str, Any]:
        """Import all workflow files."""
        if not self.check_docker_container():
            print("❌ n8n container 'n8n-n8n-1' is not running")
            print("   Please make sure n8n is running: cd /opt/n8n && docker compose up -d")
            return {"success": False, "message": "Container not running"}

        workflow_files = self.get_workflow_files()
        total_files = len(workflow_files)

        if total_files == 0:
            return {"success": False, "message": "No workflow files found"}

        print(f"🚀 Starting import of {total_files} workflows...")
        print("-" * 50)

        for i, file_path in enumerate(workflow_files, 1):
            print(f"[{i}/{total_files}] Processing {file_path.name}...")

            if self.import_workflow(file_path):
                self.imported_count += 1
            else:
                self.failed_count += 1

        # Summary
        print("\n" + "=" * 50)
        print(f"📊 Import Summary:")
        print(f"✅ Successfully imported: {self.imported_count}")
        print(f"❌ Failed imports: {self.failed_count}")
        print(f"📁 Total files: {total_files}")

        if self.errors:
            print(f"\n❌ Errors encountered:")
            for error in self.errors[:10]:
                print(f"   • {error}")
            if len(self.errors) > 10:
                print(f"   ... and {len(self.errors) - 10} more errors")

        return {
            "success": self.failed_count == 0,
            "imported": self.imported_count,
            "failed": self.failed_count,
            "total": total_files,
            "errors": self.errors
        }


def main():
    """Main entry point."""
    print("🔧 N8N Workflow Importer (Direct Docker Method)")
    print("=" * 50)

    importer = WorkflowImporter()
    result = importer.import_all()

    sys.exit(0 if result["success"] else 1)


if __name__ == "__main__":
    main()
#!/usr/bin/env python3
"""
N8N Workflow Importer - Improved Error Handling
Import workflows with detailed error reporting
"""

import json
import subprocess
import sys
from pathlib import Path
from typing import List, Dict, Any


class WorkflowImporter:
    """Import n8n workflows using Docker container with detailed error handling."""
    
    def __init__(self, workflows_dir: str = "workflows"):
        self.workflows_dir = Path(workflows_dir)
        self.imported_count = 0
        self.failed_count = 0
        self.errors = []

    def validate_workflow(self, file_path: Path) -> dict:
        """Validate workflow JSON and return detailed validation info."""
        validation_info = {
            "valid": False,
            "errors": [],
            "warnings": []
        }
        
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            
            if not isinstance(data, dict):
                validation_info["errors"].append("Root element must be a JSON object")
                return validation_info
            
            # Check required fields
            required_fields = ["nodes", "connections"]
            for field in required_fields:
                if field not in data:
                    validation_info["errors"].append(f"Missing required field: {field}")
            
            # Check important optional fields
            if "name" not in data or not data["name"]:
                validation_info["warnings"].append("Missing or empty name field")
            
            if "id" not in data or not data["id"]:
                validation_info["warnings"].append("Missing or empty id field")
            
            # Check nodes structure
            if "nodes" in data and isinstance(data["nodes"], list):
                if len(data["nodes"]) == 0:
                    validation_info["warnings"].append("Workflow has no nodes")
                else:
                    for i, node in enumerate(data["nodes"]):
                        if not isinstance(node, dict):
                            validation_info["errors"].append(f"Node {i} is not a valid object")
                        elif "name" not in node:
                            validation_info["errors"].append(f"Node {i} missing name field")
                        elif "type" not in node:
                            validation_info["errors"].append(f"Node {i} missing type field")
            
            validation_info["valid"] = len(validation_info["errors"]) == 0
            
        except json.JSONDecodeError as e:
            validation_info["errors"].append(f"Invalid JSON syntax: {str(e)}")
        except FileNotFoundError:
            validation_info["errors"].append("File not found")
        except PermissionError:
            validation_info["errors"].append("Permission denied reading file")
        except Exception as e:
            validation_info["errors"].append(f"Unexpected error: {str(e)}")
        
        return validation_info

    def import_workflow(self, file_path: Path) -> bool:
        """Import a single workflow file using Docker container with detailed error reporting."""
        try:
            # Validate workflow format
            validation = self.validate_workflow(file_path)
            
            if not validation["valid"]:
                error_msg = "; ".join(validation["errors"])
                self.errors.append(f"Validation failed for {file_path.name}: {error_msg}")
                print(f"❌ Validation failed: {file_path.name}")
                print(f"   Errors: {error_msg}")
                return False
            
            # Show warnings if any
            if validation["warnings"]:
                print(f"⚠️  Warnings for {file_path.name}:")
                for warning in validation["warnings"]:
                    print(f"   - {warning}")
            
            # Copy file to container and import
            container_path = f"/tmp/{file_path.name}"
            
            # Copy file to container
            copy_cmd = [
                "docker", "cp", str(file_path), 
                f"n8n-n8n-1:{container_path}"
            ]
            
            result = subprocess.run(copy_cmd, capture_output=True, text=True, timeout=30)
            if result.returncode != 0:
                error_msg = f"Failed to copy to container: {result.stderr.strip() or result.stdout.strip()}"
                self.errors.append(f"Copy failed for {file_path.name}: {error_msg}")
                print(f"❌ Copy failed: {file_path.name}")
                print(f"   Error: {error_msg}")
                return False
            
            # Import workflow in container
            import_cmd = [
                "docker", "exec", "n8n-n8n-1",
                "n8n", "import:workflow",
                f"--input={container_path}"
            ]
            
            result = subprocess.run(import_cmd, capture_output=True, text=True, timeout=60)
            
            # Check for success - n8n may return 0 even on failure
            success_indicators = ["Successfully imported"]
            error_indicators = ["An error occurred", "violates not-null constraint"]
            
            has_success = any(indicator in result.stdout for indicator in success_indicators)
            has_error = any(indicator in result.stdout or indicator in result.stderr for indicator in error_indicators)
            
            if result.returncode == 0 and has_success and not has_error:
                print(f"✅ Imported: {file_path.name}")
                return True
            else:
                # Parse and clean n8n error output
                error_output = result.stderr.strip() or result.stdout.strip()
                
                # Extract meaningful error messages
                error_lines = [line.strip() for line in error_output.split("\n") if line.strip()]
                meaningful_errors = []
                
                for line in error_lines:
                    # Skip common noise
                    if any(skip in line for skip in ["Permissions", "deprecation", "N8N_RUNNERS_ENABLED"]):
                        continue
                    
                    # Look for specific error patterns
                    if "violates not-null constraint" in line:
                        if "name" in line:
                            meaningful_errors.append("Missing workflow name field")
                        elif "id" in line:
                            meaningful_errors.append("Missing workflow ID field")
                        else:
                            meaningful_errors.append(f"Database constraint: {line}")
                    elif "duplicate key value" in line:
                        meaningful_errors.append("Workflow already exists (duplicate ID)")
                    elif "An error occurred" in line:
                        meaningful_errors.append("n8n import failed - check workflow format")
                    elif len(line) > 20:  # Avoid very short messages
                        meaningful_errors.append(line)
                
                if meaningful_errors:
                    error_msg = meaningful_errors[0]  # Show the most relevant error
                    if len(meaningful_errors) > 1:
                        error_msg += f" (and {len(meaningful_errors) - 1} more errors)"
                else:
                    if has_error:
                        error_msg = "n8n import failed - likely missing required fields"
                    else:
                        error_msg = f"Import failed with exit code {result.returncode}"
                
                self.errors.append(f"Import failed for {file_path.name}: {error_msg}")
                print(f"❌ Import failed: {file_path.name}")
                print(f"   Error: {error_msg}")
                return False
                
        except subprocess.TimeoutExpired:
            error_msg = "Import operation timed out"
            self.errors.append(f"Timeout for {file_path.name}: {error_msg}")
            print(f"⏰ Timeout: {file_path.name}")
            print(f"   Error: {error_msg}")
            return False
        except Exception as e:
            error_msg = f"Unexpected error: {str(e)}"
            self.errors.append(f"Error importing {file_path.name}: {error_msg}")
            print(f"❌ Unexpected error: {file_path.name}")
            print(f"   Error: {error_msg}")
            return False

    def get_workflow_files(self) -> List[Path]:
        """Get all workflow JSON files."""
        if not self.workflows_dir.exists():
            print(f"❌ Workflows directory not found: {self.workflows_dir}")
            return []
        
        json_files = list(self.workflows_dir.glob("*.json"))
        # Exclude backup files
        json_files = [f for f in json_files if not f.name.endswith(".backup")]
        
        if not json_files:
            print(f"❌ No JSON files found in: {self.workflows_dir}")
            return []
        
        return sorted(json_files)

    def check_docker_container(self) -> bool:
        """Check if n8n container is running."""
        try:
            result = subprocess.run(
                ["docker", "ps", "--filter", "name=n8n-n8n-1", "--format", "{{.Names}}"],
                capture_output=True, text=True, timeout=10
            )
            return "n8n-n8n-1" in result.stdout
        except:
            return False

    def import_all(self) -> Dict[str, Any]:
        """Import all workflow files with detailed reporting."""
        if not self.check_docker_container():
            print("❌ n8n container 'n8n-n8n-1' is not running")
            print("   Please make sure n8n is running: cd /opt/n8n && docker compose up -d")
            return {"success": False, "message": "Container not running"}
        
        workflow_files = self.get_workflow_files()
        total_files = len(workflow_files)
        
        if total_files == 0:
            return {"success": False, "message": "No workflow files found"}
        
        print(f"🚀 Starting import of {total_files} workflows...")
        print("=" * 60)
        
        for i, file_path in enumerate(workflow_files, 1):
            print(f"\n[{i}/{total_files}] Processing: {file_path.name}")
            print("-" * 40)
            
            if self.import_workflow(file_path):
                self.imported_count += 1
            else:
                self.failed_count += 1
        
        # Summary
        print("\n" + "=" * 60)
        print(f"📊 Import Summary:")
        print(f"✅ Successfully imported: {self.imported_count}")
        print(f"❌ Failed imports: {self.failed_count}")
        print(f"📁 Total files processed: {total_files}")
        
        if self.failed_count > 0:
            print(f"\n❌ Failed imports details:")
            for i, error in enumerate(self.errors, 1):
                print(f"   {i}. {error}")
        
        return {
            "success": self.failed_count == 0,
            "imported": self.imported_count,
            "failed": self.failed_count,
            "total": total_files,
            "errors": self.errors
        }


def main():
    """Main entry point."""
    print("🔧 N8N Workflow Importer - Improved Error Handling")
    print("=" * 60)
    
    importer = WorkflowImporter()
    result = importer.import_all()
    
    if result["success"]:
        print(f"\n🎉 All workflows imported successfully!")
    else:
        print(f"\n⚠️  Import completed with {result['failed']} failures")
    
    sys.exit(0 if result["success"] else 1)


if __name__ == "__main__":
    main()
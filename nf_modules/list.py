#!/usr/bin/env python3
"""
list.py - List available NextFlow modules
"""
import sys
import urllib.request
import tarfile
import tempfile
import os
import re
import yaml

def parse_module_file(content):
    """Parse a NextFlow module file to extract module_version and tool version"""
    module_version = None
    tool_version = None
    
    # Parse module_version
    module_version_match = re.search(r'def\s+module_version\s*=\s*["\']([^"\']+)["\']', content)
    if module_version_match:
        module_version = module_version_match.group(1)
    
    # Parse tool version from container line
    # Find the container line with the ternary operator, handling both single and double quotes
    container_match = re.search(r'container\s*["\']?\$\{\s*[^}]+\?\s*([^:]+):\s*([^"\']+)["\']?', content, re.MULTILINE | re.DOTALL)
    
    if container_match:
        singularity_container = container_match.group(1).strip()
        docker_container = container_match.group(2).strip()
        
        # Clean up quotes and trailing } from docker_container
        docker_container = re.sub(r'["\']?\s*\}.*$', '', docker_container).strip().strip("'\"")
        
        # Extract version from the docker container path after the last colon
        if ':' in docker_container:
            tool_version = docker_container.split(':')[-1]
        else:
            # If no colon, try to get from conda line
            conda_match = re.search(r'conda\s*["\']bioconda::([^=]+)=([^"\']+)["\']', content)
            if conda_match:
                tool_version = conda_match.group(2)
    
    return module_version, tool_version

def list_modules(args):
    """List all available modules in the repository"""
    tag = getattr(args, 'tag', 'main')
    repository_url = f"https://api.github.com/repos/jolespin/nf-modules/tarball/{tag}"
    
    try:
        print(f"Fetching module list from tag '{tag}'...", file=sys.stderr)
        
        with tempfile.NamedTemporaryFile(suffix='.tar.gz', delete=False) as temporary_file:
            with urllib.request.urlopen(repository_url) as response:
                # Only read headers first to get content length for progress
                total_size = int(response.headers.get('content-length', 0))
                downloaded = 0
                
                while True:
                    chunk = response.read(8192)
                    if not chunk:
                        break
                    temporary_file.write(chunk)
                    downloaded += len(chunk)
                    
                    if total_size > 0:
                        percent = (downloaded / total_size) * 100
                        print(f"\rDownloading: {percent:.1f}%", end='', flush=True, file=sys.stderr)
                
            temporary_file_path = temporary_file.name
        
        print("\nExtracting module information...", file=sys.stderr)
        
        # Extract and find all module directories and their main.nf files
        modules_info = {}
        with tarfile.open(temporary_file_path, 'r:gz') as tarball:
            for member in tarball.getmembers():
                if member.name.endswith("/main.nf") and "/modules/" in member.name:
                    # Extract module name from path
                    path_parts = member.name.split('/')
                    if len(path_parts) >= 3:
                        modules_idx = None
                        for i, part in enumerate(path_parts):
                            if part == "modules":
                                modules_idx = i
                                break
                        
                        if modules_idx is not None and modules_idx + 1 < len(path_parts):
                            module_name = path_parts[modules_idx + 1]
                            if module_name and not module_name.startswith('.'):
                                # Extract and read the main.nf file content
                                try:
                                    extracted_file = tarball.extractfile(member)
                                    if extracted_file:
                                        content = extracted_file.read().decode('utf-8')
                                        module_version, tool_version = parse_module_file(content)
                                        modules_info[module_name] = {
                                            'module_version': module_version,
                                            'tool_version': tool_version
                                        }
                                except Exception as e:
                                    # If we can't parse the file, just add the module name
                                    modules_info[module_name] = {
                                        'module_version': None,
                                        'tool_version': None
                                    }
        
        # Apply filter if specified
        if hasattr(args, 'filter') and args.filter:
            filtered_modules = {k: v for k, v in modules_info.items() if args.filter.lower() in k.lower()}
            modules_info = filtered_modules
        
        if modules_info:
            format_type = getattr(args, 'format', 'list-name')
            
            if format_type == 'list-name':
                for module_name in sorted(modules_info.keys()):
                    print(module_name)
            
            elif format_type == 'yaml':
                yaml_data = {
                    'name': 'nf-modules',
                    'dependencies': []
                }
                
                for module_name in sorted(modules_info.keys()):
                    info = modules_info[module_name]
                    tool_ver = info['tool_version'] or 'unknown'
                    module_ver = info['module_version'] or 'unknown'
                    yaml_data['dependencies'].append(f"{module_name}={tool_ver}[{module_ver}]")
                
                print("# Generated by nf-modules list --format yaml")
                print(yaml.dump(yaml_data, default_flow_style=False, sort_keys=False))
        else:
            if hasattr(args, 'filter') and args.filter:
                print(f"No modules found matching filter '{args.filter}'", file=sys.stderr)
            else:
                print("No modules found in repository", file=sys.stderr)
        
    except Exception as exception:
        print(f"\nError: {exception}", file=sys.stderr)
        sys.exit(1)
    
    finally:
        # Clean up temp file
        try:
            os.unlink(temporary_file_path)
        except:
            pass
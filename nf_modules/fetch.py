#!/usr/bin/env python3
"""
fetch.py - Fetch NextFlow modules
"""
import sys
import os
import urllib.request
import tarfile
import tempfile
import shutil

def fetch_modules(args):
    """Fetch one or more modules from the repository"""
    module_names = args.modules
    output_directory = args.output_directory
    tag = args.tag
    force = args.force
    
    # Check if any module directories already exist
    existing_modules = []
    for module_name in module_names:
        module_path = os.path.join(output_directory, module_name)
        if os.path.exists(module_path):
            existing_modules.append(module_name)
    
    # If modules exist and --force not specified, error out
    if existing_modules and not force:
        print(f"Error: The following module(s) already exist in '{output_directory}':")
        for module in existing_modules:
            print(f"  - {module}")
        print("\nUse --force to overwrite existing modules.")
        sys.exit(1)
    
    # Warn user if overwriting
    if existing_modules and force:
        print(f"Warning: Overwriting {len(existing_modules)} existing module(s): {', '.join(existing_modules)}")
    
    # Create output directory if it doesn't exist
    os.makedirs(output_directory, exist_ok=True)
    
    # Download and extract
    repository_url = f"https://api.github.com/repos/jolespin/nf-modules/tarball/{tag}"
    
    try:
        print(f"Downloading {len(module_names)} module(s) from tag '{tag}': {', '.join(module_names)}")
        
        with tempfile.NamedTemporaryFile(suffix='.tar.gz', delete=False) as temporary_file:
            with urllib.request.urlopen(repository_url) as response:
                shutil.copyfileobj(response, temporary_file)
            temporary_file_path = temporary_file.name
        
        # Extract modules
        with tarfile.open(temporary_file_path, 'r:gz') as tarball:
            found_modules = set()
            
            for module_name in module_names:
                # Remove existing module directory if force is enabled
                module_path = os.path.join(output_directory, module_name)
                if force and os.path.exists(module_path):
                    shutil.rmtree(module_path)
                
                # Find the module directory in the tarball
                members = [member for member in tarball.getmembers() if f"/modules/{module_name}/" in member.name]
                
                if not members:
                    print(f"Warning: Module '{module_name}' not found in repository")
                    continue
                
                found_modules.add(module_name)
                
                for member in members:
                    # Strip the repository prefix and modules/ prefix
                    path_parts = member.name.split('/')
                    if len(path_parts) >= 3:  # repo-name/modules/module-name/...
                        new_path = '/'.join(path_parts[2:])  # module-name/...
                        member.path = os.path.join(output_directory, new_path)
                        tarball.extract(member, path="")
            
            if found_modules:
                print(f"Successfully downloaded modules to '{output_directory}': {', '.join(sorted(found_modules))}")
            
            missing_modules = set(module_names) - found_modules
            if missing_modules:
                print(f"Failed to find modules: {', '.join(sorted(missing_modules))}")
                sys.exit(1)
        
    except Exception as exception:
        print(f"Error: {exception}")
        sys.exit(1)
    
    finally:
        # Clean up temp file
        try:
            os.unlink(temporary_file_path)
        except:
            pass
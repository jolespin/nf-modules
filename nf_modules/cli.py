#!/usr/bin/env python3
"""
cli.py - Main CLI entry point
"""
import sys
import argparse

COMMANDS = {
    "fetch": {
        "module": "fetch",
        "function": "fetch_modules",
        "description": "Download modules from the repository"
    },
    "list": {
        "module": "list", 
        "function": "list_modules",
        "description": "List all available modules in the repository"
    }
}

def main():
    # Create main parser
    parser = argparse.ArgumentParser(
        prog='nf-modules',
        description='NextFlow bioinformatics modules management tool',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    # Create subparsers for commands
    subparsers = parser.add_subparsers(
        dest='command',
        help='Available commands',
        metavar='<command>'
    )
    
    # Add subparsers for each command
    for cmd, info in COMMANDS.items():
        subparser = subparsers.add_parser(
            cmd,
            help=info['description'],
            description=info['description']
        )
        
        # Add command-specific arguments
        if cmd == 'fetch':
            subparser.add_argument(
                '-o', '--output-directory',
                default='modules/local/nf-modules/',
                help='Output directory to download modules (default: modules/local/nf-modules/)'
            )
            subparser.add_argument(
                '-t', '--tag',
                default='main',
                help='Git tag or branch to fetch from (default: main)'
            )
            subparser.add_argument(
                '-f', '--force',
                action='store_true',
                help='Overwrite existing module directories'
            )
            subparser.add_argument(
                'modules',
                nargs='+',
                help='One or more module names to fetch'
            )
        elif cmd == 'list':
            subparser.add_argument(
                '-f', '--format',
                choices=['list-name', 'yaml'],
                default='list-name',
                help='Output format (default: list-name)'
            )
            subparser.add_argument(
                '--filter',
                help='Filter modules by name pattern (case-insensitive substring match)'
            )
            subparser.add_argument(
                '-t', '--tag',
                default='main',
                help='Git tag or branch to list from (default: main)'
            )
    
    # Parse arguments
    args = parser.parse_args()
    
    # If no command provided, show help
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    # Execute the appropriate command with parsed arguments
    if args.command in COMMANDS:
        cmd_info = COMMANDS[args.command]
        # Fix: Import from nf_modules package, not relative import
        module = __import__(f"nf_modules.{cmd_info['module']}", fromlist=[cmd_info['function']])
        function = getattr(module, cmd_info['function'])
        function(args)  # Pass the parsed arguments
    else:
        print(f"Unknown command: {args.command}")
        print(f"Available commands: {', '.join(COMMANDS.keys())}")
        sys.exit(1)

if __name__ == "__main__":
    main()
#!/usr/bin/env python
import sys, os, argparse
from typing import OrderedDict
import pandas as pd


__program__ = os.path.split(sys.argv[0])[-1]
__version__ = "2025.9.18"

def parse_compleasm_output(file_handle):
    """Parse compleasm output and return structured data"""
    sections = []
    current_section = None
    
    for line in file_handle:
        line = line.strip()
        if not line:
            continue
            
        if line.startswith("## lineage:"):
            # Start new section
            lineage = line.split(":", 1)[1].strip()
            current_section = {
                'lineage': lineage,
                'data': {}
            }
            sections.append(current_section)
        elif current_section is not None and ":" in line:
            # Parse data line like "S:93.80%, 121" or "N:129"
            key, values = line.split(":", 1)
            key = key.strip()
            values = values.strip()
            
            if "," in values:
                # Has both percentage and count
                pct_str, count_str = values.split(",", 1)
                pct = float(pct_str.strip().rstrip("%"))
                count = int(count_str.strip())
            else:
                # Only count (for N)
                if values.isdigit():
                    pct = None
                    count = int(values)
                else:
                    # Only percentage
                    pct = float(values.strip().rstrip("%"))
                    count = None
            
            current_section['data'][key] = {'percentage': pct, 'count': count}
    
    return sections

def create_summary_line(data):
    """Create the one_line_summary format like C:91.5%[S:91.5%,D:0.0%],F:4.7%,M:3.9%,n:129"""
    s_pct = data.get('S', {}).get('percentage', 0.0)
    d_pct = data.get('D', {}).get('percentage', 0.0)
    f_pct = data.get('F', {}).get('percentage', 0.0)
    m_pct = data.get('M', {}).get('percentage', 0.0)
    n_count = data.get('N', {}).get('count', 0)
    
    complete_pct = s_pct + d_pct
    
    summary = f"C:{complete_pct:.1f}%[S:{s_pct:.1f}%,D:{d_pct:.1f}%],F:{f_pct:.1f}%,M:{m_pct:.1f}%,n:{n_count}"
    return summary

def extract_domain(lineage):
    """Extract domain from lineage name (remove _odb12 suffix)"""
    if "_odb" in lineage:
        return lineage.split("_odb")[0]
    return lineage

def create_output_row(section_data, domain):
    """Create a row of output data for a section"""
    data = section_data['data']
    
    s_pct = data.get('S', {}).get('percentage', 0.0)
    s_count = data.get('S', {}).get('count', 0)
    d_pct = data.get('D', {}).get('percentage', 0.0)
    d_count = data.get('D', {}).get('count', 0)
    f_pct = data.get('F', {}).get('percentage', 0.0)
    f_count = data.get('F', {}).get('count', 0)
    m_pct = data.get('M', {}).get('percentage', 0.0)
    m_count = data.get('M', {}).get('count', 0)
    n_count = data.get('N', {}).get('count', 0)
    
    complete_pct = s_pct + d_pct
    complete_count = s_count + d_count
    
    return {
        'one_line_summary': create_summary_line(data),
        'Complete percentage': complete_pct,
        'Complete BUSCOs': complete_count,
        'Single copy percentage': s_pct,
        'Single copy BUSCOs': s_count,
        'Multi copy percentage': d_pct,
        'Multi copy BUSCOs': d_count,
        'Fragmented percentage': f_pct,
        'Fragmented BUSCOs': f_count,
        'Missing percentage': m_pct,
        'Missing BUSCOs': m_count,
        'n_markers': n_count,
        'avg_identity': "",
        'domain': domain,
        'internal_stop_codon_count': 0,
        'internal_stop_codon_percent': 0
    }

def main(args=None):
    # Path info
    script_directory  =  os.path.dirname(os.path.abspath( __file__ ))
    script_filename = __program__
    # Path info
    description = """
    Running: {} v{} via Python v{} | {}""".format(__program__, __version__, sys.version.split(" ")[0], sys.executable)
    usage = "{} -i <summary.txt> -o <summary.tsv>".format(__program__)
    epilog = "Copyright 2021 Josh L. Espinoza (jol.espinoz@gmail.com)"

    # Parser
    parser = argparse.ArgumentParser(description=description, usage=usage, epilog=epilog, formatter_class=argparse.RawTextHelpFormatter)

    # Pipeline
    parser.add_argument("-i","--input", type=str, default="stdin", help = "path/to/compleasm/summary.txt [Default: stdin]")
    parser.add_argument("-o","--output", type=str, help = "path/to/output.tsv [Default: stdout]", default="stdout")
    parser.add_argument("-n","--name", type=str, help = "Genome identifier", required=True)

    # Options
    opts = parser.parse_args()
    opts.script_directory  = script_directory
    opts.script_filename = script_filename
    
    # Handle input
    if opts.input == "stdin":
        input_handle = sys.stdin
    else:
        input_handle = open(opts.input, 'r')
    
    # Parse the data
    sections = parse_compleasm_output(input_handle)
    
    if opts.input != "stdin":
        input_handle.close()
    
    if not sections:
        print("Error: No data found in input", file=sys.stderr)
        sys.exit(1)
    
    # Create output data with multi-index columns
    output_data = {}
    
    if len(sections) == 1:
        # Single section - use 'generic' as first level
        section = sections[0]
        domain = extract_domain(section['lineage'])
        row_data = create_output_row(section, domain)
        
        for col_name, value in row_data.items():
            output_data[('generic', col_name)] = value
            
    elif len(sections) == 2:
        # Two sections - use 'generic' and 'specific'
        for i, section in enumerate(sections):
            level = 'generic' if i == 0 else 'specific'
            domain = extract_domain(section['lineage'])
            row_data = create_output_row(section, domain)
            
            for col_name, value in row_data.items():
                output_data[(level, col_name)] = value
    else:
        print(f"Error: Expected 1 or 2 sections, found {len(sections)}", file=sys.stderr)
        sys.exit(1)
    
    # Create DataFrame with multi-index columns
    df_data = {opts.name: output_data}
    df = pd.DataFrame(df_data).T
    
    # Handle output
    if opts.output == "stdout":
        df.to_csv(sys.stdout, sep='\t')
    else:
        df.to_csv(opts.output, sep='\t')


if __name__ == "__main__":
    main()
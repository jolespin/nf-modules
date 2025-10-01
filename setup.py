from setuptools import setup, find_packages

# Read version from __init__.py
with open("nf_modules/__init__.py", "r") as f:
    for line in f:
        if line.startswith("__version__"):
            version = line.split("=")[-1].strip().strip('"\'')
            break
    else:
        raise RuntimeError("Could not find version in nf_modules/__init__.py")

# Read requirements from requirements.txt
with open("requirements.txt", "r") as f:
    requirements = [line.strip() for line in f if line.strip() and not line.startswith('#')]

setup(
    name="nf-modules",
    version=version,
    description="Nextflow bioinformatics modules",
    author="Josh L. Espinoza",
    packages=find_packages(),
    install_requires=requirements,
    entry_points={
        "console_scripts": [
            "nf-modules=nf_modules.cli:main",
            "compile-reads-table=nf_modules.compile_reads_table:main",
        ],
    },
    python_requires=">=3.6",
)
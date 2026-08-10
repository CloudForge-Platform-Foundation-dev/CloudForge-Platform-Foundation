# CloudForge Security Policies
# Evaluated by Open Policy Agent (OPA) in CI/CD pipelines

package cloudforge.security

import future.keywords.if
import future.keywords.in

# Deny if repository is missing required security files
deny[msg] if {
    not input.files["SECURITY.md"]
    msg := "Repository must include SECURITY.md"
}

deny[msg] if {
    not input.files[".github/workflows/security-scan.yml"]
    msg := "Repository must include security scanning workflow"
}

# Deny if hardcoded secrets detected in source files
deny[msg] if {
    some file in input.source_files
    contains(file.content, "AKIA")  # AWS Access Key pattern
    msg := sprintf("Potential hardcoded AWS key in file: %s", [file.path])
}

deny[msg] if {
    some file in input.source_files
    regex.match(`password\s*=\s*["'][^"']+["']`, file.content)
    msg := sprintf("Potential hardcoded password in file: %s", [file.path])
}

# Deny if container image uses 'latest' tag
deny[msg] if {
    some file in input.source_files
    file.path == "Dockerfile"
    contains(file.content, "FROM")
    contains(file.content, ":latest")
    msg := "Dockerfile must not use ':latest' tag; use specific version"
}

# Deny if HTTP is used instead of HTTPS
deny[msg] if {
    some file in input.source_files
    regex.match(`http://(?!localhost|127\.0\.0\.1)`, file.content)
    msg := sprintf("Insecure HTTP URL found in file: %s", [file.path])
}

# Warn if no dependency scanning configured
warn[msg] if {
    not input.files[".github/workflows/dependency-scan.yml"]
    msg := "Consider adding dependency scanning workflow"
}

# Allow if no deny rules triggered
allow := true if {
    count(deny) == 0
}

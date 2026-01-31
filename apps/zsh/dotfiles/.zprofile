# .zprofile - executed for login shells
# Note: For login interactive shells, both .zprofile and .zshrc run
# Keep this minimal to avoid duplicate initialization

# Add mise shims to PATH for GUI applications and non-interactive shells
# This ensures tools like yq are available in terminals launched from GUI apps
if command -v mise &> /dev/null; then
  export PATH="$HOME/.local/share/mise/shims:$PATH"
fi

#!/bin/bash
# McRitchie Studio — Quick Setup (single-app bundle + DB only)
#
# For full ecosystem setup across all 5 repos on a fresh Mac, use:
#   bin/ecosystem-build
# (See docs/agents/system/house-burn-down.md for the canonical recovery flow.)
#
# This script only handles the gem install + DB seed for THIS one repo.
# Run from the mcritchie_studio directory.

set -e

echo "=== McRitchie Studio Setup (single-app) ==="
echo "For full ecosystem (5 repos + toolchain), run bin/ecosystem-build instead."
echo ""

# Install dependencies
echo "Installing gems..."
bundle install

# Create and migrate database
echo "Setting up database..."
bin/rails db:create db:migrate db:seed

echo ""
echo "=== Setup Complete ==="
echo "Admin login: alex@mcritchie.studio / pass"
echo "Start server: bin/rails server"
echo "Visit: http://localhost:3000"

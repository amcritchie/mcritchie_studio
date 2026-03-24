#!/bin/bash
# McRitchie Studio — Quick Setup
# Run from the mcritchie_studio directory

set -e

echo "=== McRitchie Studio Setup ==="

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

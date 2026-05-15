#!/bin/bash
CURRENT_DIR="$(pwd)"
RPM_DIR="$CURRENT_DIR/rpmbuild"

tar czf "$RPM_DIR/SOURCES/fedora-overhaul.tar.gz" -C "$CURRENT_DIR" "./rpm-src/"
rpmbuild --define "_topdir $RPM_DIR" -bb "$RPM_DIR/SPECS/fedora-overhaul.spec"
mv "$RPM_DIR/RPMS/noarch/fedora-overhaul-1.0-1.noarch.rpm" "$CURRENT_DIR/docs/fedora-overhaul.rpm"

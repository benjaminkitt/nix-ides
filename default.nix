# This file provides backward compatibility for non-flake-enabled Nix
(import (
  fetchTarball {
    url = "https://github.com/edolstra/flake-compat/archive/master.tar.gz";
    sha256 = "0m6nmi1fw34c8qb6n3vrrb5r2saqmw1cj2wx7vp7c6qmlqnwgyjj"; # Replace with the actual hash
  }
) {
  src = ./.;
}).defaultNix

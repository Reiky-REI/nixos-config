# Legacy single-user view retained for existing scripts. New configuration
# should import users.nix and select an explicit user ID.
let
  user = (import ./users.nix).reiky;
in {
  inherit (user) username fullName githubHandle;
}

let
  user_name = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMY282QEpZWkXv8oTomNEKt0snDqDYitvBSpY7TdlH5c Reiky-REI@cook";
in {
  "ai_api_key.age".publicKeys = [user_name];
}

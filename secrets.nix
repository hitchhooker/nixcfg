let
  alice = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOqvYP5qw5cBB4c518QBzdfpiYKBERZptdTxa1JgRMqM";
  allKeys = [alice];
in
{
  "wifi-networks.age" = {
    publicKeys = allKeys;
  };
  "alice-hash.age" = {
    publicKeys = allKeys;
  };
}

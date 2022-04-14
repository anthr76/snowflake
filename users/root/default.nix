{ ... }:
# recommend using `hashedPassword`
{
  users.mutableUsers = false;
  users.users.root.password = "";
  users.users.temp = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    password = "password";
  };
}

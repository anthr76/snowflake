{ ... }:
# recommend using `hashedPassword`
{
  users.mutableUsers = true;
  users.users.root.openssh.authorizedKeys.keys = (builtins.filter builtins.isString
    (builtins.split "\n" (builtins.readFile (builtins.fetchurl {
      url = "https://github.com/anthr76.keys";
      sha256 = "ac89c011ed2105c9437c8ab055c1eb5796b842d6b04869d150fb6ef26b3e2bfd";
    }))));
}

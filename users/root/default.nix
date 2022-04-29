{ ... }:
# recommend using `hashedPassword`
{
  users.mutableUsers = true;

  users.users.root.openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBE0SaE3DjA8TkonMthpFvud67S1wJe+XhN0pueHccwF4iDWkAUHA0wLObGORucoO//aR5o7HZGiqPSUbjIS/GwY= pyubi"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCZL5c1Nbk1mqAUlcuqrWtqIlF0PHPjO36RwsYCFnhVP9JTEHZvQT7+1q7Ki2RH3rmGLTIISZAi2Eb3dCbHHnvGZzrr5wFeMjDfoqV5hxvO/u9xWXTHXveZ3IHaP+NN0Bky9niIHYvjrfO9rN1OcQaRn97a6DLKtFN5DciuSd032vpgXtbVkRyFprKo9DKcMQd6QXvxKUYXRuLk7fybiixD5w4GTJH2IPxKG5ES0ponjfg8QCxWlPqdqtQjjO/aTExjdKZT+eRZO37Aw5bQUtDbUGGU2L2ZGBkkkZyfkeOuktU/jcBhDqjvraG7+fmSgZ9+knBxbcTABmPVjz4uqOP ppyubi"
    ];
}

{ 
    programs.starship = { 
        enable = true;
        kubernetes = {
            disabled = false;
            contexts = [
                {
                context_pattern = "^teleport\.[\w\.]+-(?P<cluster>[\w-]+)$";
                context_alias = "$cluster";
                }
            ];
        };
    }; 
}

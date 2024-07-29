{ 
    programs.starship = { 
        enable = true;
        settings.kubernetes = {
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

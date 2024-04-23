_: {
  genExtensionsConfig =
    exts:
    (builtins.listToAttrs (
      map (x: {
        name = x.extid;
        value = {
          installation_mode = "force_installed";
          install_url = "file://${x}/${x.extid}.xpi";
        };
      }) exts
    ));
}

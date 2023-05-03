{ pkgs }: {modules ? [], ... }@attrs:

with pkgs.lib;

let
  module = removeAttrs attrs [ "pkgs" "modules" ];
  
  prefixPath = prefix: path: (remove "" (splitString "." prefix) ++ ["defaults"] ++ (splitString "." path));
  optionsPath = prefixPath "options";
  outputsPath = prefixPath "options.outputs";
  configOutputsPath = prefixPath "config.outputs";
  valuePath = prefixPath "";

  mkMacOSDefaultsValueOption = {
    path,
    type,
    description,
    support,
    example ? null,
    default
  }: setAttrByPath (optionsPath path) (mkOption {
    inherit description example default;
    internal = false;
    visible = true;
    readOnly = false;
    type = types.nullOr type;
  });

  mkMacOSDefaultsOutputOption = {
    path,
    domain,
    key
  }: setAttrByPath (outputsPath path) (mkOption {
    default = null;
    internal = true;
    visible = false;
    readOnly = false;
    description = "Output value for use in defaults write call when ${path} is set";
    type = types.nullOr types.str;
  });

  mkMacOSDefaultsOutputsConfig = {
    config,
    path,
    domain,
    key,
  }: setAttrByPath
    (configOutputsPath path)
    (mkIf
      ((attrByPath (valuePath path) null config) != null)
      (formatter domain key (attrByPath (valuePath path) null config)));
  
  mkMacOSDefaultsOption = {
    path,
    config ? {},
    domain ? path,
    default ? null,
    example ? null,
    key,
    type,
    description,
    support ? [ "Monterey" "Big Sur" "Catalina" "Mojave" ]
  }: foldl recursiveUpdate {} [
    (mkMacOSDefaultsValueOption { inherit path type description support default example; })
    (mkMacOSDefaultsOutputOption { inherit path domain key; })
    (mkMacOSDefaultsOutputsConfig { inherit path domain key config; })
  ];

  formatter = domain: key: value:
    let
      formattedValue =
        if isBool value then "-bool ${boolValue value}" else
        if isInt value then "-int ${toString value}" else
        if isFloat value then "-float ${strings.floatToString value}" else
        if isString value then "-string '${value}'" else
        throw "invalid value type";
    in "defaults write ${domain} '${key}' ${formattedValue}";

   defaultsModule = { lib, pkgs, config, ...}: 
    foldl
      (prev: curr: recursiveUpdate (mkMacOSDefaultsOption (curr // { inherit config; })) prev)
      {}
      defaults;

  defaults = [
    {
      path = "dock.position";
      description = "Set the Dock position";
      default = null;
      domain = "com.apple.dock";
      key = "orientation";
      type = types.enum [ "left" "bottom" "right" ];
      example = "bottom";
    }

    {
      path = "dock.iconSize";
      description = "Set the icon size of Dock items in pixels";
      default = null;
      domain = "com.apple.dock";
      key = "tilesize";
      type = types.int;
      example = 32;
    }

    {
      path = "dock.autohide";
      description = "Autohides the Dock";
      default = null;
      domain = "com.apple.dock";
      key = "autohide";
      type = types.bool;
      example = false;
    }

    {
      path = "dock.autohide.time";
      description = "Change the Dock opening and closing animation times";
      default = null;
      domain = "com.apple.dock";
      key = "tilesize";
      type = types.float;
      example = 0.5;
    }

    {
      path = "dock.autohide.delay";
      description = "Change the Dock opening delay";
      default = null;
      domain = "com.apple.dock";
      key = "tilesize";
      type = types.float;
      example = 0.5;
    }

    {
      path = "dock.showRecents";
      description = "Show recently used apps in a separate section of the Dock";
      default = null;
      domain = "com.apple.dock";
      key = "show-recents";
      type = types.bool;
      example = true;
    }

    {
      path = "dock.minimizeAnimationEffect";
      description = "Change the Dock minimize animation";
      default = null;
      domain = "com.apple.dock";
      key = "mineffect";
      type = types.enum [ "genie" "scale" "suck" ];
      example = "genie";
    }

    {
      path = "dock.activeApplicationsOnly";
      description = "Set the icon size of Dock items in pixels";
      default = null;
      domain = "com.apple.dock";
      key = "static-only";
      type = types.bool;
      example = false;
    }

    {
      path = "screenshots.disableShadow";
      description = "Disable screenshot shadow when capturing an application";
      default = null;
      domain = "com.apple.screencapture";
      key = "disable-shadow";
      type = types.bool;
      example = false;
    }

    {
      path = "screenshots.includeDate";
      description = "Include date and time in screenshot filenames";
      default = null;
      domain = "com.apple.screencapture";
      key = "include-date";
      type = types.bool;
      example = false;
    }

    {
      path = "screenshots.location";
      description = "Set default screenshot location";
      default = null;
      domain = "com.apple.screencapture";
      key = "location";
      type = types.str;
      example = "~/Pictures";
    }

    {
      path = "screenshots.showThumbnail";
      description = "Choose whether to display a thumbnail after taking a screenshot";
      default = null;
      domain = "com.apple.screencapture";
      key = "show-thumbnail";
      type = types.bool;
      example = false;
    }

    {
      path = "screenshots.format";
      description = "Choose the screenshots image format";
      default = null;
      domain = "com.apple.screencapture";
      key = "type";
      type = types.enum [ "png" "jpg" "pdf" "psd" "gif" "tga" "tiff" "bmp" ];
      example = "png";
    }

    {
      path = "safari.showFullURL";
      description = "Show full website address";
      default = null;
      domain = "com.apple.safari";
      key = "ShowFullURLInSmartSearchField";
      type = types.bool;
      example = true;
    }
  ];
in (evalModules {
  modules = [defaultsModule] ++ modules ++ [module];
}).config
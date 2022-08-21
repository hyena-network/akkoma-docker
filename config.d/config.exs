import Config
# For additional configuration outside of environmental variables
# Configure Akkoma Frontends
config :pleroma, :frontends,
  primary: %{
    "name" => "pleroma-fe",
    "ref" => "stable"
  },
  admin: %{
    "name" => "admin-fe",
    "ref" => "stable"
  }
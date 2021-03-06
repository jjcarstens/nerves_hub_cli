defmodule Mix.Tasks.NervesHub.Product do
  use Mix.Task

  import Mix.NervesHubCLI.Utils

  alias Mix.NervesHubCLI.Shell

  @shortdoc "Manages your products"

  @moduledoc """
  Manages your products.

  ## create

  Create a new NervesHub product. The shell will prompt for information about the
  product. This information can be passed by specifying one or all of the command
  line options.

    mix nerves_hub.product create

  ### Command-line options

    * `--name` - (Optional) The product name

  ## list

    mix nerves_hub.product list

  ## delete

    mix nerves_hub.firmware delete [product_name]

  ## update

  Update product metadata.

  Call `list` to retrieve product names and metadata keys

  ### Examples

  Change product name

    mix nerves_hub.product update example name example_new
  """

  @switches [
    org: :string,
    name: :string
  ]

  def run(args) do
    Application.ensure_all_started(:nerves_hub_cli)

    {opts, args} = OptionParser.parse!(args, strict: @switches)

    show_api_endpoint()
    org = org(opts)

    case args do
      ["list"] ->
        list(org)

      ["create"] ->
        create(org, opts)

      ["delete", product_name] ->
        delete(org, product_name)

      ["update", product, key, value] ->
        update(org, product, key, value)

      _ ->
        render_help()
    end
  end

  @spec render_help() :: no_return()
  def render_help() do
    Shell.raise("""
    Invalid arguments to `mix nerves_hub.product`.

    Usage:
      mix nerves_hub.product list
      mix nerves_hub.product create
      mix nerves_hub.product delete PRODUCT_NAME
      mix nerves_hub.product update PRODUCT_NAME KEY VALUE

    Run `mix help nerves_hub.product` for more information.
    """)
  end

  def list(org) do
    auth = Shell.request_auth()

    case NervesHubUserAPI.Product.list(org, auth) do
      {:ok, %{"data" => []}} ->
        Shell.info("No products have been created.")

      {:ok, %{"data" => products}} ->
        Shell.info("")
        Shell.info("Products:")

        Enum.each(products, fn params ->
          Shell.info("------------")

          render_product(params)
          |> String.trim_trailing()
          |> Shell.info()
        end)

        Shell.info("")

      error ->
        Shell.render_error(error)
    end
  end

  def create(org, opts) do
    config = Mix.Project.config()

    name = opts[:name] || config[:name] || config[:app] || Shell.prompt("Product name:")

    Shell.info("")
    Shell.info("Creating product '#{name}'...")

    auth = Shell.request_auth()

    case NervesHubUserAPI.Product.create(org, name, auth) do
      {:ok, %{"data" => %{} = _product}} ->
        Shell.info("Product '#{name}' created.")

      error ->
        Shell.render_error(error)
    end
  end

  def delete(org, product_name) do
    if Shell.yes?("Delete product '#{product_name}'?") do
      auth = Shell.request_auth()

      case NervesHubUserAPI.Product.delete(org, product_name, auth) do
        {:ok, ""} ->
          Shell.info("Product deleted successfully.")

        error ->
          Shell.render_error(error)
      end
    end
  end

  def update(org, product, key, value) do
    auth = Shell.request_auth()

    case NervesHubUserAPI.Product.update(org, product, Map.put(%{}, key, value), auth) do
      {:ok, %{"data" => product}} ->
        Shell.info("")
        Shell.info("Product updated:")

        render_product(product)
        |> String.trim_trailing()
        |> Shell.info()

        Shell.info("")

      error ->
        Shell.render_error(error)
    end
  end

  defp render_product(params) do
    """
      name: #{params["name"]}
    """
  end
end

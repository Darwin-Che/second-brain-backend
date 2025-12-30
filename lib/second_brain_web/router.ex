defmodule SecondBrainWeb.Router do
  use SecondBrainWeb, :router

  require Logger

  pipeline :api do
    plug :accepts, ["json"]

    plug :fetch_session
  end

  pipeline :auth do
    plug Ueberauth
  end

  pipeline :guardian_maybe_auth do
    plug Guardian.Plug.Pipeline,
      module: SecondBrain.Auth.Guardian,
      error_handler: SecondBrain.Auth.AuthErrorHandler

    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.VerifyHeader
    plug Guardian.Plug.LoadResource, allow_blank: true
  end

  pipeline :guardian_ensure_auth do
    plug Guardian.Plug.EnsureAuthenticated
  end

  scope "/auth", SecondBrainWeb do
    pipe_through :auth

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  scope "/api/v1", SecondBrainWeb.Api.V1 do
    pipe_through [
      :api,
      :guardian_maybe_auth,
      :guardian_ensure_auth
    ]

    get "/brain/state", BrainController, :state

    get "/session_history", HistoryController, :index

    get "/tasks", TaskController, :index
    post "/tasks/add", TaskController, :add_task
    post "/tasks/edit", TaskController, :edit_task
    get "/tasks/recommend", TaskController, :recommend

    post "/start_session", BrainController, :start_session
    post "/end_session", BrainController, :end_session
    post "/update_notes", BrainController, :update_notes

    get "/account", AccountController, :show
    post "/account/logout", AccountController, :logout
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:second_brain, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: SecondBrainWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

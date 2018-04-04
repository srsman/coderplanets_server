defmodule MastaniServer.Test.AccountsTest do
  use MastaniServerWeb.ConnCase, async: true

  # TODO import Service.Utils move both helper and github
  import Helper.Utils
  import MastaniServer.Factory

  alias MastaniServer.{Repo, Accounts}
  alias Helper.MastaniServer.Guardian
  alias Helper.ORM

  # @valid_user mock_attrs(:user)
  @valid_github_profile mock_attrs(:github_profile) |> map_key_stringify

  describe "[github login]" do
    test "register a valid github user with non-exist in db" do
      g_user = Repo.get_by(Accounts.GithubUser, github_id: to_string(@valid_github_profile["id"]))
      assert nil == g_user
      user = Repo.get_by(Accounts.User, nickname: @valid_github_profile["login"])
      assert nil == user

      # IO.inspect @valid_github_profile, label: "@valid_github_profile"
      {:ok, %{token: token, user: user}} = Accounts.github_signin(@valid_github_profile)
      {:ok, claims, _info} = Guardian.jwt_decode(token)

      created_user = Repo.get(Accounts.User, claims.id)

      assert user.id == created_user.id
      assert created_user.nickname == @valid_github_profile["login"]
      assert created_user.avatar == @valid_github_profile["avatar_url"]
      assert created_user.bio == @valid_github_profile["bio"]
      assert created_user.from_github == true

      g_user = Repo.get_by(Accounts.GithubUser, github_id: to_string(@valid_github_profile["id"]))
      assert g_user.login == @valid_github_profile["login"]
      assert g_user.avatar_url == @valid_github_profile["avatar_url"]
      assert g_user.access_token == @valid_github_profile["access_token"]
      assert g_user.node_id == @valid_github_profile["node_id"]
    end

    test "exsit github user should not be created twice" do
      assert ORM.count(Accounts.GithubUser) == 0
      {:ok, _} = Accounts.github_signin(@valid_github_profile)
      assert ORM.count(Accounts.GithubUser) == 1
      {:ok, _} = Accounts.github_signin(@valid_github_profile)
      assert ORM.count(Accounts.GithubUser) == 1
    end
  end
end

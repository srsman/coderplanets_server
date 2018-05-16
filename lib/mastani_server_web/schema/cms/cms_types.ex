defmodule MastaniServerWeb.Schema.CMS.Types do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  import Ecto.Query, warn: false
  import Absinthe.Resolution.Helpers, only: [dataloader: 2, on_load: 2]

  alias MastaniServer.{CMS}
  alias MastaniServerWeb.{Resolvers, Schema}
  alias MastaniServerWeb.Middleware, as: M

  import_types(Schema.CMS.Misc)

  object :idlike do
    field(:id, :id)
  end

  object :comment do
    field(:id, :id)
    field(:body, :string)
    field(:floor, :integer)
    field(:author, :user, resolve: dataloader(CMS, :author))
    # field(:reply_to, :comment)

    field :reply_to, :comment do
      resolve(dataloader(CMS, :reply_to))
    end

    field :likes, list_of(:user) do
      arg(:filter, :members_filter)

      middleware(M.PageSizeProof)
      resolve(dataloader(CMS, :likes))
    end

    field :likes_count, :integer do
      arg(:count, :count_type, default_value: :count)

      resolve(dataloader(CMS, :likes))
      middleware(M.ConvertToInt)
    end

    field :viewer_has_liked, :boolean do
      arg(:viewer_did, :viewer_did_type, default_value: :viewer_did)

      middleware(M.Authorize, :login)
      # put current user into dataloader's args
      middleware(M.PutCurrentUser)
      resolve(dataloader(CMS, :likes))
      middleware(M.ViewerDidConvert)
    end

    field :dislikes, list_of(:user) do
      arg(:filter, :members_filter)

      middleware(M.PageSizeProof)
      resolve(dataloader(CMS, :dislikes))
    end

    field :viewer_has_disliked, :boolean do
      arg(:viewer_did, :viewer_did_type, default_value: :viewer_did)

      middleware(M.Authorize, :login)
      # put current user into dataloader's args
      middleware(M.PutCurrentUser)
      resolve(dataloader(CMS, :dislikes))
      middleware(M.ViewerDidConvert)
    end

    field :dislikes_count, :integer do
      arg(:count, :count_type, default_value: :count)

      resolve(dataloader(CMS, :dislikes))
      middleware(M.ConvertToInt)
    end

    field :replies, list_of(:comment) do
      arg(:filter, :members_filter)

      middleware(M.ForceLoader)
      middleware(M.PageSizeProof)
      resolve(dataloader(CMS, :replies))
    end

    field :replies_count, :integer do
      arg(:count, :count_type, default_value: :count)

      resolve(dataloader(CMS, :replies))
      middleware(M.ConvertToInt)
    end

    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
  end

  object :post do
    interface(:article)
    field(:id, :id)
    field(:title, :string)
    field(:digest, :string)
    field(:length, :integer)
    field(:link_addr, :string)
    field(:body, :string)
    field(:views, :integer)
    field(:tags, list_of(:tag), resolve: dataloader(CMS, :tags))
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)

    field(:author, :user, resolve: dataloader(CMS, :author))
    field(:communities, list_of(:community), resolve: dataloader(CMS, :communities))

    field :comments, list_of(:comment) do
      arg(:filter, :members_filter)

      # middleware(M.ForceLoader)
      middleware(M.PageSizeProof)
      resolve(dataloader(CMS, :comments))
    end

    field :comments_count, :integer do
      arg(:count, :count_type, default_value: :count)

      resolve(dataloader(CMS, :comments))
      middleware(M.ConvertToInt)
    end

    field :comments_participators, list_of(:user) do
      arg(:filter, :members_filter)
      arg(:unique, :unique_type, default_value: true)

      middleware(M.ForceLoader)
      middleware(M.PageSizeProof)
      resolve(dataloader(CMS, :comments))
    end

    field :comments_participators2, list_of(:user) do
      arg(:filter, :members_filter)
      arg(:unique, :unique_type, default_value: true)

      middleware(M.PageSizeProof)

      resolve(fn post, _args, %{context: %{loader: loader}} ->
        # IO.inspect args, label: "the args"
        loader
        |> Dataloader.load(CMS, {:many, CMS.PostComment}, cp_users: post.id)
        |> on_load(fn loader ->
          {:ok, Dataloader.get(loader, CMS, {:many, CMS.PostComment}, cp_users: post.id)}
        end)
      end)
    end

    field :comments_participators_count, :integer do
      resolve(fn post, _args, %{context: %{loader: loader}} ->
        loader
        |> Dataloader.load(CMS, {:one, CMS.PostComment}, cp_count: post.id)
        |> on_load(fn loader ->
          {:ok, Dataloader.get(loader, CMS, {:one, CMS.PostComment}, cp_count: post.id)}
        end)
      end)
    end

    field :comments_participators_count_wired, :integer do
      arg(:unique, :unique_type, default_value: true)
      arg(:count, :count_type, default_value: :count)

      # middleware(M.ForceLoader)
      resolve(dataloader(CMS, :comments))
      # middleware(M.CountLength)
    end

    field :viewer_has_favorited, :boolean do
      arg(:viewer_did, :viewer_did_type, default_value: :viewer_did)

      middleware(M.Authorize, :login)
      # put current user into dataloader's args
      middleware(M.PutCurrentUser)
      resolve(dataloader(CMS, :favorites))
      middleware(M.ViewerDidConvert)
      # TODO: Middleware.Logger
    end

    field :viewer_has_starred, :boolean do
      arg(:viewer_did, :viewer_did_type, default_value: :viewer_did)

      middleware(M.Authorize, :login)
      middleware(M.PutCurrentUser)
      resolve(dataloader(CMS, :stars))
      middleware(M.ViewerDidConvert)
    end

    field :favorited_users, list_of(:user) do
      arg(:filter, :members_filter)

      middleware(M.PageSizeProof)
      resolve(dataloader(CMS, :favorites))
    end

    field :favorited_count, :integer do
      arg(:count, :count_type, default_value: :count)
      arg(:type, :post_type, default_value: :post)
      # middleware(M.SeeMe)
      resolve(dataloader(CMS, :favorites))
      middleware(M.ConvertToInt)
    end

    field :starred_count, :integer do
      arg(:count, :count_type, default_value: :count)
      arg(:type, :post_type, default_value: :post)

      resolve(dataloader(CMS, :stars))
      middleware(M.ConvertToInt)
    end

    field :starred_users, list_of(:user) do
      arg(:filter, :members_filter)

      middleware(M.PageSizeProof)
      resolve(dataloader(CMS, :stars))
    end
  end

  object :thread do
    field(:id, :id)
    field(:title, :string)
    field(:raw, :string)
  end

  object :contribute do
    field(:date, :date)
    field(:count, :integer)
  end

  object :contribute_map do
    field(:start_date, :date)
    field(:end_date, :date)
    field(:total_count, :integer)
    field(:records, list_of(:contribute))
  end

  object :community do
    # meta(:cache, max_age: 30)

    field(:id, :id)
    field(:title, :string)
    field(:desc, :string)
    field(:raw, :string)
    field(:logo, :string)
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
    field(:author, :user, resolve: dataloader(CMS, :author))
    field(:threads, list_of(:thread), resolve: dataloader(CMS, :threads))

    # Big thanks: https://elixirforum.com/t/grouping-error-in-absinthe-dadaloader/13671/2
    # see also: https://github.com/absinthe-graphql/dataloader/issues/25
    field :posts_count, :integer do
      resolve(fn community, _args, %{context: %{loader: loader}} ->
        IO.inspect(community.id, label: "luck")

        loader
        |> Dataloader.load(CMS, {:one, CMS.Post}, posts_count: community.id)
        |> on_load(fn loader ->
          {:ok, Dataloader.get(loader, CMS, {:one, CMS.Post}, posts_count: community.id)}
        end)
      end)
    end

    field :subscribers, list_of(:user) do
      arg(:filter, :members_filter)
      middleware(M.PageSizeProof)
      resolve(dataloader(CMS, :subscribers))
    end

    field :subscribers_count, :integer do
      arg(:count, :count_type, default_value: :count)
      arg(:type, :community_type, default_value: :community)
      resolve(dataloader(CMS, :subscribers))
      middleware(M.ConvertToInt)
    end

    field :viewer_has_subscribed, :boolean do
      arg(:viewer_did, :viewer_did_type, default_value: :viewer_did)

      middleware(M.Authorize, :login)
      middleware(M.PutCurrentUser)
      resolve(dataloader(CMS, :subscribers))
      middleware(M.ViewerDidConvert)
    end

    field :editors, list_of(:user) do
      arg(:filter, :members_filter)
      middleware(M.PageSizeProof)
      resolve(dataloader(CMS, :editors))
    end

    field :editors_count, :integer do
      arg(:count, :count_type, default_value: :count)
      arg(:type, :community_type, default_value: :community)
      resolve(dataloader(CMS, :editors))
      middleware(M.ConvertToInt)
    end

    field :contributes, list_of(:contribute) do
      # TODO add complex here to warning N+1 problem
      resolve(&Resolvers.Statistics.list_contributes/3)
    end

    field :contributes_digest, list_of(:integer) do
      # TODO add complex here to warning N+1 problem
      resolve(&Resolvers.Statistics.list_contributes_digest/3)
    end
  end

  object :tag do
    field(:id, :id)
    field(:title, :string)
    field(:color, :string)
    field(:part, :string)
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
  end

  object :paged_posts do
    field(:entries, list_of(:post))
    field(:total_count, :integer)
    field(:page_size, :integer)
    field(:total_pages, :integer)
    field(:page_number, :integer)
  end

  object :paged_comments do
    field(:entries, list_of(:comment))
    field(:total_count, :integer)
    field(:page_size, :integer)
    field(:total_pages, :integer)
    field(:page_number, :integer)
  end

  object :paged_communities do
    field(:entries, list_of(:community))
    field(:total_count, :integer)
    field(:page_size, :integer)
    field(:total_pages, :integer)
    field(:page_number, :integer)
  end

  object :paged_tags do
    field(:entries, list_of(:tag))
    field(:total_count, :integer)
    field(:page_size, :integer)
    field(:total_pages, :integer)
    field(:page_number, :integer)
  end
end

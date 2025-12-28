defmodule SecondBrain.Db.EctoHelper do
  @moduledoc false

  import Ecto.Changeset

  @doc false
  @spec validate_not_nil(Ecto.Changeset.t(), [atom()]) :: Ecto.Changeset.t()
  def validate_not_nil(changeset, fields) do
    Enum.reduce(fields, changeset, fn field, changeset ->
      if get_field(changeset, field) == nil do
        add_error(changeset, field, "nil")
      else
        changeset
      end
    end)
  end

  def cast_with_empty(object, attrs, fields) do
    cast(object, attrs, fields, empty_values: [nil])
  end
end

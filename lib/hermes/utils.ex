defmodule Hermes.Utils do
  import Bitwise

  def run_cmd(cmd, args) do
    {res, _} = System.cmd(cmd, args)
    IO.binwrite(res)
  end

  def build_inner(inner) do
    case is_map(inner) do
        false -> inner
        true -> apply(inner.__struct__, :build, [inner])
      end
  end

  def calc_checksum(data) do
    data
    |> :binary.bin_to_list()
    |> Enum.chunk_every(2)
    |> Enum.reduce(0, fn
      [high], acc -> acc + (high <<< 8)
      [low, high], acc -> acc + (low <<< 8) + high
    end)
    |> fold_sum()
    |> bxor(0xFFFF)
  end

  defp fold_sum(sum) when (sum >>> 16) > 0, do: fold_sum((sum &&& 0xFFFF) + (sum >>> 16))
  defp fold_sum(sum), do: sum
end

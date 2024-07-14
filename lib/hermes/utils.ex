defmodule Hermes.Utils do
  def run_cmd(cmd, args) do
    {res, _} = System.cmd(cmd, args)
    IO.binwrite(res)
  end
end

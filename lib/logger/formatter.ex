import Kernel, except: [inspect: 2]

defmodule Logger.Formatter do
  @moduledoc false

  @doc """
  Receives a format string and arguments and replace `~p`,
  `~P`, `~w` and `~W` by its inspected variants.
  """
  def inspect(format, args, opts \\ %Inspect.Opts{})

  def inspect(format, args, opts) when is_atom(format) do
    inspect(Atom.to_char_list(format), args, opts)
  end

  def inspect(format, args, opts) when is_binary(format) do
    inspect(:binary.bin_to_list(format), args, opts)
  end

  def inspect(format, args, opts) when is_list(format) do
    do_inspect(format, args, opts)
  end

  defp do_inspect(format, [], _opts),  do: {format, []}
  defp do_inspect(format, args, opts), do: do_inspect(format, args, [], [], opts)

  defp do_inspect([?~|t], args, used_format, used_args, opts) do
    {t, args, cc_format, cc_args} = collect_cc(:width, t, args, [?~], [], opts)
    do_inspect(t, args, cc_format ++ used_format, cc_args ++ used_args, opts)
  end

  defp do_inspect([h|t], args, used_format, used_args, opts),
    do: do_inspect(t, args, [h|used_format], used_args, opts)

  defp do_inspect([], [], used_format, used_args, _opts),
    do: {:lists.reverse(used_format), :lists.reverse(used_args)}

  ## width

  defp collect_cc(:width, [?-|t], args, used_format, used_args, opts),
    do: collect_value(:width, t, args, [?-|used_format], used_args, opts, :precision)

  defp collect_cc(:width, t, args, used_format, used_args, opts),
    do: collect_value(:width, t, args, used_format, used_args, opts, :precision)

  ## precision

  defp collect_cc(:precision, [?.|t], args, used_format, used_args, opts),
    do: collect_value(:precision, t, args, [?.|used_format], used_args, opts, :pad_char)

  defp collect_cc(:precision, t, args, used_format, used_args, opts),
    do: collect_cc(:pad_char, t, args, used_format, used_args, opts)

  ## pad char

  defp collect_cc(:pad_char, [?.,?*|t], [arg|args], used_format, used_args, opts),
    do: collect_cc(:encoding, t, args, [?*,?.|used_format], [arg|used_args], opts)

  defp collect_cc(:pad_char, [?.,p|t], args, used_format, used_args, opts),
    do: collect_cc(:encoding, t, args, [p,?.|used_format], used_args, opts)

  defp collect_cc(:pad_char, t, args, used_format, used_args, opts),
    do: collect_cc(:encoding, t, args, used_format, used_args, opts)

  ## encoding

  defp collect_cc(:encoding, [?l|t], args, used_format, used_args, opts),
    do: collect_cc(:done, t, args, [?l|used_format], used_args, %{opts | char_lists: false})

  defp collect_cc(:encoding, [?t|t], args, used_format, used_args, opts),
    do: collect_cc(:done, t, args, [?t|used_format], used_args, opts)

  defp collect_cc(:encoding, t, args, used_format, used_args, opts),
    do: collect_cc(:done, t, args, used_format, used_args, opts)

  ## done

  defp collect_cc(:done, [?W|t], [data, limit|args], _used_format, _used_args, opts),
    do: collect_inspect(t, args, data, %{opts | limit: limit, width: :infinity})

  defp collect_cc(:done, [?w|t], [data|args], _used_format, _used_args, opts),
    do: collect_inspect(t, args, data, %{opts | width: :infinity})

  defp collect_cc(:done, [?P|t], [data, limit|args], _used_format, _used_args, opts),
    do: collect_inspect(t, args, data, %{opts | limit: limit})

  defp collect_cc(:done, [?p|t], [data|args], _used_format, _used_args, opts),
    do: collect_inspect(t, args, data, opts)

  defp collect_cc(:done, [h|t], args, used_format, used_args, _opts) do
    {args, used_args} = collect_cc(h, args, used_args)
    {t, args, [h|used_format], used_args}
  end

  defp collect_cc(?x, [a,prefix|args], used), do: {args, [prefix, a|used]}
  defp collect_cc(?X, [a,prefix|args], used), do: {args, [prefix, a|used]}
  defp collect_cc(?s, [a|args], used), do: {args, [a|used]}
  defp collect_cc(?e, [a|args], used), do: {args, [a|used]}
  defp collect_cc(?f, [a|args], used), do: {args, [a|used]}
  defp collect_cc(?g, [a|args], used), do: {args, [a|used]}
  defp collect_cc(?b, [a|args], used), do: {args, [a|used]}
  defp collect_cc(?B, [a|args], used), do: {args, [a|used]}
  defp collect_cc(?+, [a|args], used), do: {args, [a|used]}
  defp collect_cc(?#, [a|args], used), do: {args, [a|used]}
  defp collect_cc(?c, [a|args], used), do: {args, [a|used]}
  defp collect_cc(?i, [a|args], used), do: {args, [a|used]}
  defp collect_cc(?~, args, used), do: {args, used}
  defp collect_cc(?n, args, used), do: {args, used}

  defp collect_inspect(t, args, data, opts) do
    data =
      data
      |> Inspect.Algebra.to_doc(opts)
      |> Inspect.Algebra.pretty(opts.width)
    {t, args, 'st~', [data]}
  end

  defp collect_value(current, [?*|t], [arg|args], used_format, used_args, opts, next)
      when is_integer(arg) do
    collect_cc(next, t, args, [?*|used_format], [arg|used_args],
               put_value(opts, current, arg))
  end

  defp collect_value(current, [c|t], args, used_format, used_args, opts, next)
      when is_integer(c) and c >= ?0 and c <= ?9 do
    {t, c} = collect_value([c|t], [])
    collect_cc(next, t, args, c ++ used_format, used_args,
               put_value(opts, current, c |> :lists.reverse |> List.to_integer))
  end

  defp collect_value(_current, t, args, used_format, used_args, opts, next),
    do: collect_cc(next, t, args, used_format, used_args, opts)

  defp collect_value([c|t], buffer)
    when is_integer(c) and c >= ?0 and c <= ?9,
    do: collect_value(t, [c|buffer])

  defp collect_value(other, buffer),
    do: {other, buffer}

  defp put_value(opts, key, value) do
    if Map.has_key?(opts, key) do
      Map.put(opts, key, value)
    else
      opts
    end
  end
end

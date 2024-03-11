defmodule Duration do
  @moduledoc """
  Struct and functions for handling durations.

  A `Duration` struct represents a collection of time scale units,
  allowing for manipulation and calculation of durations.

  Date and time scale units are represented as integers, allowing for both positive and negative values.

  Microseconds are represented using a tuple `{microsecond, precision}`.
  This ensures compatibility with other calendar types implementing time, such as `Time`, `DateTime`, and `NaiveDateTime`.
  """

  defstruct year: 0,
            month: 0,
            week: 0,
            day: 0,
            hour: 0,
            minute: 0,
            second: 0,
            microsecond: {0, 0}

  @type t :: %Duration{
          year: integer,
          month: integer,
          week: integer,
          day: integer,
          hour: integer,
          minute: integer,
          second: integer,
          microsecond: {integer, integer}
        }

  @type unit ::
          {:year, integer}
          | {:month, integer}
          | {:week, integer}
          | {:day, integer}
          | {:hour, integer}
          | {:minute, integer}
          | {:second, integer}
          | {:microsecond, {integer, integer}}

  @doc """
  Creates a new `Duration` struct from given `units`.

  Raises a KeyError when called with invalid units.

  ## Examples

      iex> Duration.new(month: 2)
      %Duration{month: 2}

  """
  @spec new([unit]) :: t
  def new(units) do
    case Keyword.get(units, :microsecond) do
      nil ->
        :noop

      ms when is_tuple(ms) ->
        :noop

      _ ->
        raise "microseconds must be a tuple {ms, precision}"
    end

    struct!(Duration, units)
  end

  @doc """
  Adds units of given durations `d1` and `d2`.

  Respects the the highest microsecond precision of the two.

  ## Examples

      iex> Duration.add(%Duration{week: 2, day: 1}, %Duration{day: 2})
      %Duration{week: 2, day: 3}

  """
  @spec add(t, t) :: t
  def add(%Duration{} = d1, %Duration{} = d2) do
    {m1, p1} = d1.microsecond
    {m2, p2} = d2.microsecond

    %Duration{
      year: d1.year + d2.year,
      month: d1.month + d2.month,
      week: d1.week + d2.week,
      day: d1.day + d2.day,
      hour: d1.hour + d2.hour,
      minute: d1.minute + d2.minute,
      second: d1.second + d2.second,
      microsecond: {m1 + m2, max(p1, p2)}
    }
  end

  @doc """
  Subtracts units of given durations `d1` and `d2`.

  Respects the the highest microsecond precision of the two.

  ## Examples

      iex> Duration.subtract(%Duration{week: 2, day: 1}, %Duration{day: 2})
      %Duration{week: 2, day: -1}

  """
  @spec subtract(t, t) :: t
  def subtract(%Duration{} = d1, %Duration{} = d2) do
    {m1, p1} = d1.microsecond
    {m2, p2} = d2.microsecond

    %Duration{
      year: d1.year - d2.year,
      month: d1.month - d2.month,
      week: d1.week - d2.week,
      day: d1.day - d2.day,
      hour: d1.hour - d2.hour,
      minute: d1.minute - d2.minute,
      second: d1.second - d2.second,
      microsecond: {m1 - m2, max(p1, p2)}
    }
  end

  @doc """
  Multiplies `duration` units by given `integer`.

  ## Examples

      iex> Duration.multiply(%Duration{day: 1, minute: 15, second: -10}, 3)
      %Duration{day: 3, minute: 45, second: -30}

  """
  @spec multiply(t, integer) :: t
  def multiply(%Duration{microsecond: {ms, p}} = duration, integer) when is_integer(integer) do
    %Duration{
      year: duration.year * integer,
      month: duration.month * integer,
      week: duration.week * integer,
      day: duration.day * integer,
      hour: duration.hour * integer,
      minute: duration.minute * integer,
      second: duration.second * integer,
      microsecond: {ms * integer, p}
    }
  end

  @doc """
  Negates `duration` units.


  ## Examples

      iex> Duration.negate(%Duration{day: 1, minute: 15, second: -10})
      %Duration{day: -1, minute: -15, second: 10}

  """
  @spec negate(t) :: t
  def negate(%Duration{microsecond: {ms, p}} = duration) do
    %Duration{
      year: -duration.year,
      month: -duration.month,
      week: -duration.week,
      day: -duration.day,
      hour: -duration.hour,
      minute: -duration.minute,
      second: -duration.second,
      microsecond: {-ms, p}
    }
  end

  @doc """
  Parses an ISO8601 formatted duration string to a `Duration` struct.

  ## Examples

      iex> Duration.parse("P1Y2M3DT4H5M6S")
      {:ok, %Duration{year: 1, month: 2, day: 3, hour: 4, minute: 5, second: 6}}

      iex> Duration.parse("PT10H30M")
      {:ok, %Duration{hour: 10, minute: 30, second: 0}}

  """
  @spec parse(String.t()) :: {:ok, t} | {:error, String.t()}
  def parse("P" <> duration_string) do
    parse(duration_string, %{}, "", false)
  end

  def parse(_) do
    {:error, "invalid duration string"}
  end

  @doc """
  Same as parse/1 but raises an ArgumentError.

  ## Examples

      iex> Duration.parse!("P1Y2M3DT4H5M6S")
      %Duration{year: 1, month: 2, day: 3, hour: 4, minute: 5, second: 6}

      iex> Duration.parse!("PT10H30M")
      %Duration{hour: 10, minute: 30, second: 0}

  """
  @spec parse!(String.t()) :: t
  def parse!(duration_string) do
    case parse(duration_string) do
      {:ok, duration} ->
        duration

      {:error, reason} ->
        raise ArgumentError, "failed to parse duration. reason: #{inspect(reason)}"
    end
  end

  defp parse(<<>>, duration, "", _), do: {:ok, new(Enum.into(duration, []))}

  defp parse(<<c::utf8, rest::binary>>, duration, buffer, is_time) when c in ?0..?9 do
    parse(rest, duration, <<buffer::binary, c::utf8>>, is_time)
  end

  defp parse(<<"Y", rest::binary>>, duration, buffer, false) do
    parse(:year, rest, duration, buffer, false)
  end

  defp parse(<<"M", rest::binary>>, duration, buffer, false) do
    parse(:month, rest, duration, buffer, false)
  end

  defp parse(<<"W", rest::binary>>, duration, buffer, false) do
    parse(:week, rest, duration, buffer, false)
  end

  defp parse(<<"D", rest::binary>>, duration, buffer, false) do
    parse(:day, rest, duration, buffer, false)
  end

  defp parse(<<"T", _::binary>>, _duration, _, true) do
    {:error, "time delimiter was already provided"}
  end

  defp parse(<<"T", rest::binary>>, duration, _buffer, false) do
    parse(rest, duration, "", true)
  end

  defp parse(<<"H", rest::binary>>, duration, buffer, true) do
    parse(:hour, rest, duration, buffer, true)
  end

  defp parse(<<"M", rest::binary>>, duration, buffer, true) do
    parse(:minute, rest, duration, buffer, true)
  end

  defp parse(<<"S", rest::binary>>, duration, buffer, true) do
    parse(:second, rest, duration, buffer, true)
  end

  defp parse(<<c::utf8, _::binary>>, _, _, _) do
    {:error, "Unexpected character: #{<<c>>}"}
  end

  defp parse(unit, string, duration, buffer, is_time) do
    case Map.get(duration, unit) do
      nil -> parse(string, Map.put(duration, unit, String.to_integer(buffer)), "", is_time)
      _ -> {:error, "#{unit} was already provided"}
    end
  end

  @doc """
  Formats a `Duration` struct to an ISO8601 formatted duration string.

  ## Examples

      iex> Duration.format(%Duration{year: 1, month: 2, day: 3, hour: 4, minute: 5, second: 6})
      "P1Y2M3DT4H5M6S"

      iex> Duration.format(%Duration{hour: 10, minute: 30})
      "PT10H30M"

      iex> Duration.format(%Duration{year: 1, month: 2, day: 3})
      "P1Y2M3D"
  """
  @spec format(t) :: String.t()
  def format(duration) do
    [
      year: duration.year,
      month: duration.month,
      week: duration.week,
      day: duration.day,
      hour: duration.hour,
      minute: duration.minute,
      second: duration.second
    ]
    |> Enum.reject(&(elem(&1, 1) == 0))
    |> format_components()
    |> Enum.join()
  end

  defp format_components(duration) do
    date_components = format_date_components(duration)
    time_components = format_time_components(duration)

    case time_components do
      [] -> ["P"] ++ date_components
      time_components -> ["P"] ++ date_components ++ ["T"] ++ time_components
    end
  end

  defp format_date_components(duration) do
    for {key, value} <- duration, key in [:year, :month, :week, :day] do
      "#{value}#{format_unit(key)}"
    end
  end

  defp format_time_components(duration) do
    for {key, value} <- duration, key in [:hour, :minute, :second] do
      "#{value}#{format_unit(key)}"
    end
  end

  defp format_unit(:year), do: "Y"
  defp format_unit(:month), do: "M"
  defp format_unit(:week), do: "W"
  defp format_unit(:day), do: "D"
  defp format_unit(:hour), do: "H"
  defp format_unit(:minute), do: "M"
  defp format_unit(:second), do: "S"
end

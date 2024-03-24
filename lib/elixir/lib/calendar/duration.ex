defmodule Duration do
  @moduledoc """
  Struct and functions for handling durations.

  A `Duration` struct represents a collection of time scale units,
  allowing for manipulation and calculation of durations.

  Date and time scale units are represented as integers, allowing for both positive and negative values.

  Microseconds are represented using a tuple `{microsecond, precision}`. This ensures compatibility with
  other calendar types implementing time, such as `Time`, `DateTime`, and `NaiveDateTime`.
  """

  @moduledoc since: "1.17.0"

  @derive {Inspect, optional: [:year, :month, :week, :day, :hour, :minute, :second, :microsecond]}
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
          microsecond: {integer, 0..6}
        }

  @type unit_pair ::
          {:year, integer}
          | {:month, integer}
          | {:week, integer}
          | {:day, integer}
          | {:hour, integer}
          | {:minute, integer}
          | {:second, integer}
          | {:microsecond, {integer, 0..6}}

  @doc """
  Creates a new `Duration` struct from given `unit_pairs`.

  Raises an `ArgumentError` when called with invalid unit pairs.

  ## Examples

      iex> Duration.new!(year: 1, week: 3, hour: 4, second: 1)
      %Duration{year: 1, week: 3, hour: 4, second: 1}
      iex> Duration.new!(second: 1, microsecond: {1000, 6})
      %Duration{second: 1, microsecond: {1000, 6}}
      iex> Duration.new!(month: 2)
      %Duration{month: 2}

  """
  @spec new!([unit_pair]) :: t
  def new!(unit_pairs) do
    Enum.each(unit_pairs, &validate_duration_unit!/1)
    struct!(Duration, unit_pairs)
  end

  defp validate_duration_unit!({:microsecond, {ms, precision}})
       when is_integer(ms) and precision in 0..6 do
    :ok
  end

  defp validate_duration_unit!({:microsecond, microsecond}) do
    raise ArgumentError,
          "expected a tuple {ms, precision} for microsecond where precision is an integer from 0 to 6, got #{inspect(microsecond)}"
  end

  defp validate_duration_unit!({unit, _value})
       when unit not in [:year, :month, :week, :day, :hour, :minute, :second] do
    raise ArgumentError, "unexpected unit #{inspect(unit)}"
  end

  defp validate_duration_unit!({_unit, value}) when is_integer(value) do
    :ok
  end

  defp validate_duration_unit!({unit, value}) do
    raise ArgumentError, "expected an integer for #{inspect(unit)}, got #{inspect(value)}"
  end

  @doc """
  Adds units of given durations `d1` and `d2`.

  Respects the the highest microsecond precision of the two.

  ## Examples

      iex> Duration.add(%Duration{week: 2, day: 1}, %Duration{day: 2})
      %Duration{week: 2, day: 3}
      iex> Duration.add(%Duration{microsecond: {400, 3}}, %Duration{microsecond: {600, 6}})
      %Duration{microsecond: {1000, 6}}

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
      iex> Duration.subtract(%Duration{microsecond: {400, 6}}, %Duration{microsecond: {600, 3}})
      %Duration{microsecond: {-200, 6}}

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
      iex> Duration.multiply(%Duration{microsecond: {200, 4}}, 3)
      %Duration{microsecond: {600, 4}}

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
      iex> Duration.negate(%Duration{microsecond: {500000, 4}})
      %Duration{microsecond: {-500000, 4}}

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
  Parses an ISO 8601-2 formatted duration string to a `Duration` struct.

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

  defp parse(<<c::utf8, rest::binary>>, duration, buffer, is_time) when c in ?0..?9 or c == ?. do
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
    {:error, "unexpected character: #{<<c>>}"}
  end

  defp parse(unit, _string, duration, _buffer, _is_time) when is_map_key(duration, unit) do
    {:error, "#{unit} was already provided"}
  end

  defp parse(:second, string, duration, buffer, is_time) do
    case Float.parse(buffer) do
      {float_second, ""} ->
        second = trunc(float_second)

        {microsecond, precision} =
          case trunc((float_second - second) * 1_000_000) do
            0 -> {0, 0}
            microsecond -> {microsecond, 6}
          end

        duration =
          duration
          |> Map.put(:second, second)
          |> Map.put(:microsecond, {microsecond, precision})

        parse(string, duration, "", is_time)

      _ ->
        {:error, "invalid value for second: #{buffer}"}
    end
  end

  defp parse(unit, string, duration, buffer, is_time) do
    case Integer.parse(buffer) do
      {duration_value, ""} ->
        parse(string, Map.put(duration, unit, duration_value), "", is_time)

      _ ->
        {:error, "invalid value for #{unit}: #{buffer}"}
    end
  end
end

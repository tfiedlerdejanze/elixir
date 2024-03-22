Code.require_file("../test_helper.exs", __DIR__)

defmodule DurationTest do
  use ExUnit.Case, async: true
  doctest Duration

  test "new/1" do
    assert Duration.new(year: 2, month: 1, week: 3) == %Duration{year: 2, month: 1, week: 3}

    assert_raise KeyError, ~s/key :months not found/, fn ->
      Duration.new(months: 1)
    end
  end

  test "add/2" do
    d1 = %Duration{
      year: 1,
      month: 2,
      week: 3,
      day: 4,
      hour: 5,
      minute: 6,
      second: 7,
      microsecond: {8, 6}
    }

    d2 = %Duration{
      year: 8,
      month: 7,
      week: 6,
      day: 5,
      hour: 4,
      minute: 3,
      second: 2,
      microsecond: {1, 6}
    }

    assert Duration.add(d1, d2) == %Duration{
             year: 9,
             month: 9,
             week: 9,
             day: 9,
             hour: 9,
             minute: 9,
             second: 9,
             microsecond: {9, 6}
           }

    assert Duration.add(d1, d2) == Duration.add(d2, d1)

    d1 = %Duration{month: 2, week: 3, day: 4}
    d2 = %Duration{year: 8, day: 2, second: 2}

    assert Duration.add(d1, d2) == %Duration{
             year: 8,
             month: 2,
             week: 3,
             day: 6,
             hour: 0,
             minute: 0,
             second: 2,
             microsecond: {0, 0}
           }

    d1 = %Duration{microsecond: {1000, 4}}
    d2 = %Duration{microsecond: {5, 6}}
    assert Duration.add(d1, d2) == %Duration{microsecond: {1005, 6}}
  end

  test "subtract/2" do
    d1 = %Duration{
      year: 1,
      month: 2,
      week: 3,
      day: 4,
      hour: 5,
      minute: 6,
      second: 7,
      microsecond: {8, 6}
    }

    d2 = %Duration{
      year: 8,
      month: 7,
      week: 6,
      day: 5,
      hour: 4,
      minute: 3,
      second: 2,
      microsecond: {1, 6}
    }

    assert Duration.subtract(d1, d2) == %Duration{
             year: -7,
             month: -5,
             week: -3,
             day: -1,
             hour: 1,
             minute: 3,
             second: 5,
             microsecond: {7, 6}
           }

    assert Duration.subtract(d2, d1) == %Duration{
             year: 7,
             month: 5,
             week: 3,
             day: 1,
             hour: -1,
             minute: -3,
             second: -5,
             microsecond: {-7, 6}
           }

    assert Duration.subtract(d1, d2) != Duration.subtract(d2, d1)

    d1 = %Duration{year: 10, month: 2, week: 3, day: 4}
    d2 = %Duration{year: 8, day: 2, second: 2}

    assert Duration.subtract(d1, d2) == %Duration{
             year: 2,
             month: 2,
             week: 3,
             day: 2,
             hour: 0,
             minute: 0,
             second: -2,
             microsecond: {0, 0}
           }

    d1 = %Duration{microsecond: {1000, 4}}
    d2 = %Duration{microsecond: {5, 6}}
    assert Duration.subtract(d1, d2) == %Duration{microsecond: {995, 6}}
  end

  test "multiply/2" do
    duration = %Duration{
      year: 1,
      month: 2,
      week: 3,
      day: 4,
      hour: 5,
      minute: 6,
      second: 7,
      microsecond: {8, 6}
    }

    assert Duration.multiply(duration, 3) == %Duration{
             year: 3,
             month: 6,
             week: 9,
             day: 12,
             hour: 15,
             minute: 18,
             second: 21,
             microsecond: {24, 6}
           }

    assert Duration.multiply(%Duration{year: 2, day: 4, minute: 5}, 4) ==
             %Duration{
               year: 8,
               month: 0,
               week: 0,
               day: 16,
               hour: 0,
               minute: 20,
               second: 0,
               microsecond: {0, 0}
             }
  end

  test "negate/1" do
    duration = %Duration{
      year: 1,
      month: 2,
      week: 3,
      day: 4,
      hour: 5,
      minute: 6,
      second: 7,
      microsecond: {8, 6}
    }

    assert Duration.negate(duration) == %Duration{
             year: -1,
             month: -2,
             week: -3,
             day: -4,
             hour: -5,
             minute: -6,
             second: -7,
             microsecond: {-8, 6}
           }

    assert Duration.negate(%Duration{year: 2, day: 4, minute: 5}) ==
             %Duration{
               year: -2,
               month: 0,
               week: 0,
               day: -4,
               hour: 0,
               minute: -5,
               second: 0,
               microsecond: {0, 0}
             }
  end

  test "parse/1" do
    assert Duration.parse("P1Y2M3DT4H5M6S") ==
             {:ok, %Duration{year: 1, month: 2, day: 3, hour: 4, minute: 5, second: 6}}

    assert Duration.parse("P3WT5H3M") == {:ok, %Duration{week: 3, hour: 5, minute: 3}}
    assert Duration.parse("PT5H3M") == {:ok, %Duration{hour: 5, minute: 3}}
    assert Duration.parse("P1Y2M3D") == {:ok, %Duration{year: 1, month: 2, day: 3}}
    assert Duration.parse("PT4H5M6S") == {:ok, %Duration{hour: 4, minute: 5, second: 6}}
    assert Duration.parse("P1Y2M") == {:ok, %Duration{year: 1, month: 2}}
    assert Duration.parse("P3D") == {:ok, %Duration{day: 3}}
    assert Duration.parse("PT4H5M") == {:ok, %Duration{hour: 4, minute: 5}}
    assert Duration.parse("PT6S") == {:ok, %Duration{second: 6}}
    assert Duration.parse("P5H3HT4M") == {:error, "unexpected character: H"}
    assert Duration.parse("P4Y2W3Y") == {:error, "year was already provided"}
    assert Duration.parse("invalid") == {:error, "invalid duration string"}
  end

  test "parse!/1" do
    assert Duration.parse!("P1Y2M3DT4H5M6S") == %Duration{
             year: 1,
             month: 2,
             day: 3,
             hour: 4,
             minute: 5,
             second: 6
           }

    assert Duration.parse!("P3WT5H3M") == %Duration{week: 3, hour: 5, minute: 3}
    assert Duration.parse!("PT5H3M") == %Duration{hour: 5, minute: 3}
    assert Duration.parse!("P1Y2M3D") == %Duration{year: 1, month: 2, day: 3}
    assert Duration.parse!("PT4H5M6S") == %Duration{hour: 4, minute: 5, second: 6}
    assert Duration.parse!("P1Y2M") == %Duration{year: 1, month: 2}
    assert Duration.parse!("P3D") == %Duration{day: 3}
    assert Duration.parse!("PT4H5M") == %Duration{hour: 4, minute: 5}
    assert Duration.parse!("PT6S") == %Duration{second: 6}

    assert_raise ArgumentError,
                 ~s/failed to parse duration. reason: "unexpected character: H"/,
                 fn ->
                   Duration.parse!("P5H3HT4M")
                 end

    assert_raise ArgumentError,
                 ~s/failed to parse duration. reason: "year was already provided"/,
                 fn ->
                   Duration.parse!("P4Y2W3Y")
                 end

    assert_raise ArgumentError,
                 ~s/failed to parse duration. reason: "invalid duration string"/,
                 fn ->
                   Duration.parse!("invalid")
                 end
  end

  test "sigil_P" do
    assert ~P[P1Y2M3DT4H5M6S] == %Duration{
             year: 1,
             month: 2,
             day: 3,
             hour: 4,
             minute: 5,
             second: 6
           }

    assert ~P[PT5H3M] == %Duration{hour: 5, minute: 3}
    assert ~P[P1Y2M3D] == %Duration{year: 1, month: 2, day: 3}
    assert ~P[PT4H5M6S] == %Duration{hour: 4, minute: 5, second: 6}
    assert ~P[P1Y2M] == %Duration{year: 1, month: 2}
    assert ~P[P3D] == %Duration{day: 3}
    assert ~P[PT4H5M] == %Duration{hour: 4, minute: 5}
    assert ~P[PT6S] == %Duration{second: 6}

    assert_raise ArgumentError,
                 ~s/failed to parse duration. reason: "unexpected character: H"/,
                 fn ->
                   Code.eval_string("~P[P5H3HT4M]")
                 end

    assert_raise ArgumentError,
                 ~s/failed to parse duration. reason: "invalid duration string"/,
                 fn ->
                   Code.eval_string("~P[invalid]")
                 end
  end
end

module GradeHelper
  # Maps a 0-10 numeric proprietary grade to a letter:
  #   10-8 = A, 7-5 = B, 4-2 = C, 1-0 = D, nil = "—"
  def letter_grade(numeric)
    return "—" if numeric.nil?
    case numeric
    when 8..10 then "A"
    when 5..7  then "B"
    when 2..4  then "C"
    else            "D"
    end
  end

  # Tailwind class for letter-grade badge background.
  def letter_grade_class(letter)
    case letter
    when "A" then "bg-green-600 text-white"
    when "B" then "bg-lime-500 text-white"
    when "C" then "bg-amber-500 text-white"
    when "D" then "bg-red-500 text-white"
    else          "bg-surface-alt text-muted"
    end
  end

  # Hex color for a 0-100 PFF grade badge. Nil-safe.
  PFF_GRADE_COLORS = [
    [90, "#16a34a"],  # green-600
    [80, "#22c55e"],  # green-500
    [70, "#84cc16"],  # lime-500
    [60, "#eab308"]   # yellow-500
  ].freeze
  PFF_GRADE_FALLBACK = "#ef4444".freeze # red-500
  PFF_GRADE_NIL      = "#6b7280".freeze # gray-500

  def pff_grade_color(value)
    return PFF_GRADE_NIL if value.nil?
    PFF_GRADE_COLORS.each { |threshold, color| return color if value >= threshold }
    PFF_GRADE_FALLBACK
  end
end

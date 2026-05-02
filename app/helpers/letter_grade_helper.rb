module LetterGradeHelper
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
end
